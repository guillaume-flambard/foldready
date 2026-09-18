import Foundation

/// One source line after lexing: comments gone, string literals blanked to spaces, and the
/// brace depth at the start of the line.
struct LexedLine: Sendable {
    /// 1-based line number in the original file.
    let number: Int
    /// The code on this line, with comment and string-literal contents replaced by spaces so
    /// column offsets and token boundaries survive.
    let code: String
    /// Brace nesting depth at the start of this line.
    let depth: Int
}

/// A Swift file viewed through the lexer rather than as raw text.
///
/// This is a lexer, not a syntax tree. It cannot tell that a match sits in a test helper
/// nested in a shipping file; declaration-scope attribution is a recorded follow-up. What it
/// does guarantee is that a match inside a comment or inside the literal text of a string is
/// never seen by a check, which is where the demonstrated false positives came from.
struct LexedFile: Sendable {
    let path: String
    let lines: [LexedLine]
    /// 0-based line ranges inside a `#Preview { ... }` or `PreviewProvider` body.
    let previewRanges: [ClosedRange<Int>]
    /// True when the lexer reached EOF inside an unterminated block comment or string. Such a
    /// file is excluded from scoring rather than scored clean.
    let failed: Bool

    func contains(_ token: String) -> Bool {
        lines.contains { $0.code.contains(token) }
    }

    func matches(_ regex: NSRegularExpression?) -> Bool {
        Exclusions.matches(regex, lines.map(\.code).joined(separator: "\n"))
    }

    func isPreview(line number: Int) -> Bool {
        previewRanges.contains { $0.contains(number - 1) }
    }
}

/// A character-scalar state machine that blanks every comment and string-literal body while
/// copying real code through verbatim.
///
/// Blanked characters become spaces, so columns and line lengths survive; newlines are kept so
/// line numbers stay stable. String interpolation `\( ... )` is real code and is copied
/// through. Swift block comments nest. A file that ends inside a block comment or string is
/// reported as `failed` rather than silently scored.
enum SwiftLexer {

    static func lex(_ file: FileContent) -> LexedFile {
        let scalars = Array(file.content)
        let count = scalars.count
        var output: [Character] = Array(repeating: " ", count: count)
        var failed = false

        // Brace depth at the start of each 0-based line. Line 1 always starts at zero.
        var lineStartDepths: [Int] = [0]
        var depth = 0
        var i = 0

        /// Preserve the newline at `index` and record the depth that the next line starts at.
        func recordNewline(at index: Int) {
            lineStartDepths.append(depth)
            output[index] = "\n"
        }

        while i < count {
            let c = scalars[i]

            if c == "\n" {
                recordNewline(at: i)
                i += 1
                continue
            }

            // Line comment: everything to the end of the line is not code.
            if c == "/", i + 1 < count, scalars[i + 1] == "/" {
                while i < count, scalars[i] != "\n" { i += 1 }
                continue
            }

            // Block comment, which nests in Swift.
            if c == "/", i + 1 < count, scalars[i + 1] == "*" {
                var nest = 1
                i += 2
                while i < count, nest > 0 {
                    if scalars[i] == "/", i + 1 < count, scalars[i + 1] == "*" {
                        nest += 1
                        i += 2
                    } else if scalars[i] == "*", i + 1 < count, scalars[i + 1] == "/" {
                        nest -= 1
                        i += 2
                    } else {
                        if scalars[i] == "\n" { recordNewline(at: i) }
                        i += 1
                    }
                }
                if nest > 0 { failed = true }
                continue
            }

            // Raw string: one or more `#` followed by `"` or `"""`, closed by the mirrored
            // delimiter with the same number of `#`. Raw interpolation is `\#*(`.
            if c == "#" {
                var hashes = 0
                while i + hashes < count, scalars[i + hashes] == "#" { hashes += 1 }
                if i + hashes < count, scalars[i + hashes] == "\"" {
                    var cursor = i + hashes + 1
                    let multiline = cursor + 1 < count
                        && scalars[cursor] == "\"" && scalars[cursor + 1] == "\""
                    if multiline { cursor += 2 }
                    i = cursor
                    var terminated = false
                    while i < count {
                        // Raw interpolation: backslash, exactly `hashes` hashes, then `(`.
                        if scalars[i] == "\\" {
                            var k = i + 1
                            var h = 0
                            while k < count, h < hashes, scalars[k] == "#" { h += 1; k += 1 }
                            if h == hashes, k < count, scalars[k] == "(" {
                                var p = i
                                while p <= k { output[p] = scalars[p]; p += 1 }
                                i = k + 1
                                copyInterpolationBody(&i, scalars, count,
                                                      output: &output, depth: &depth,
                                                      recordNewline: recordNewline)
                                continue
                            }
                        }
                        let quoteCount = multiline ? 3 : 1
                        if scalars[i] == "\"" {
                            var q = 0
                            while q < quoteCount, i + q < count, scalars[i + q] == "\"" { q += 1 }
                            var h = 0
                            while h < hashes, i + q + h < count, scalars[i + q + h] == "#" {
                                h += 1
                            }
                            if q == quoteCount, h == hashes {
                                i += q + hashes
                                terminated = true
                                break
                            }
                        }
                        if scalars[i] == "\n" { recordNewline(at: i) }
                        i += 1
                    }
                    if !terminated { failed = true }
                    continue
                }
            }

            // String literal, single-line or multiline.
            if c == "\"" {
                let multiline = i + 2 < count
                    && scalars[i + 1] == "\"" && scalars[i + 2] == "\""
                i += multiline ? 3 : 1
                var terminated = false
                while i < count {
                    // Interpolation is real code and must be copied through.
                    if scalars[i] == "\\", i + 1 < count, scalars[i + 1] == "(" {
                        output[i] = "\\"
                        output[i + 1] = "("
                        i += 2
                        copyInterpolationBody(&i, scalars, count,
                                              output: &output, depth: &depth,
                                              recordNewline: recordNewline)
                        continue
                    }
                    if multiline {
                        if scalars[i] == "\\", i + 1 < count, scalars[i + 1] != "\n" {
                            i += 2
                            continue
                        }
                        if scalars[i] == "\"", i + 2 < count,
                           scalars[i + 1] == "\"", scalars[i + 2] == "\"" {
                            i += 3
                            terminated = true
                            break
                        }
                    } else {
                        if scalars[i] == "\\" {
                            i += (i + 1 < count && scalars[i + 1] != "\n") ? 2 : 1
                            continue
                        }
                        if scalars[i] == "\"" {
                            i += 1
                            terminated = true
                            break
                        }
                    }
                    if scalars[i] == "\n" { recordNewline(at: i) }
                    i += 1
                }
                if !terminated { failed = true }
                continue
            }

            if c == "{" { depth += 1 }
            if c == "}" { depth -= 1 }
            output[i] = c
            i += 1
        }

        // Split the blanked code back into lines, keeping 1-based numbers and start depth.
        let rawLines = String(output).components(separatedBy: "\n")
        var lines: [LexedLine] = []
        lines.reserveCapacity(rawLines.count)
        let fallbackDepth = lineStartDepths.last ?? 0
        for (index, lineText) in rawLines.enumerated() {
            let lineDepth = index < lineStartDepths.count ? lineStartDepths[index] : fallbackDepth
            lines.append(LexedLine(number: index + 1, code: lineText, depth: lineDepth))
        }

        let previews = previewRanges(in: lines)
        return LexedFile(path: file.path, lines: lines, previewRanges: previews, failed: failed)
    }

    /// Copy the body of a `\( ... )` interpolation as real code, balancing parentheses so a
    /// nested call is kept whole. The caller has already consumed the backslash and the
    /// opening parenthesis.
    private static func copyInterpolationBody(
        _ i: inout Int,
        _ scalars: [Character],
        _ count: Int,
        output: inout [Character],
        depth: inout Int,
        recordNewline: (Int) -> Void
    ) {
        var nest = 1
        while i < count, nest > 0 {
            if scalars[i] == "(" {
                nest += 1
            } else if scalars[i] == ")" {
                nest -= 1
            } else if scalars[i] == "{" {
                depth += 1
            } else if scalars[i] == "}" {
                depth -= 1
            }
            if scalars[i] == "\n" {
                recordNewline(i)
            } else {
                output[i] = scalars[i]
            }
            i += 1
        }
    }

    /// Line ranges (0-based, inclusive) inside a `#Preview` macro body or a
    /// `PreviewProvider` conformance body. Brace counting runs on lexed lines, so a brace
    /// inside a string or comment can no longer break it.
    private static func previewRanges(in lines: [LexedLine]) -> [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []
        var index = 0
        while index < lines.count {
            let code = lines[index].code
            let starts = code.contains("#Preview")
                || code.contains(": PreviewProvider")
                || code.range(of: #"static var previews\s*:"#, options: .regularExpression) != nil
            guard starts else { index += 1; continue }
            let start = index
            var depth = 0
            var opened = false
            while index < lines.count {
                for character in lines[index].code {
                    if character == "{" { depth += 1; opened = true }
                    if character == "}" { depth -= 1 }
                }
                if opened && depth <= 0 { break }
                index += 1
            }
            ranges.append(start...min(index, lines.count - 1))
            index += 1
        }
        return ranges
    }
}
