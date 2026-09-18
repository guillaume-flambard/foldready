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
/// through, and a string literal nested inside an interpolation is itself consumed whole, so
/// its text is blanked rather than leaking into the surrounding code. Swift block comments
/// nest. A file that ends inside a block comment or string is reported as `failed` rather than
/// silently scored.
enum SwiftLexer {

    static func lex(_ file: FileContent) -> LexedFile {
        let lexer = SourceLexer(file.content)
        lexer.run()

        // Split the blanked code back into lines, keeping 1-based numbers and start depth.
        let rawLines = lexer.outputLines
        var lines: [LexedLine] = []
        lines.reserveCapacity(rawLines.count)
        let fallbackDepth = lexer.lineStartDepths.last ?? 0
        for (index, lineText) in rawLines.enumerated() {
            let lineDepth = index < lexer.lineStartDepths.count
                ? lexer.lineStartDepths[index] : fallbackDepth
            lines.append(LexedLine(number: index + 1, code: lineText, depth: lineDepth))
        }

        let previews = previewRanges(in: lines)
        return LexedFile(path: file.path, lines: lines, previewRanges: previews,
                         failed: lexer.failed)
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

/// The mutable state of one lexing pass. A reference type keeps the scan helpers and their
/// shared cursor, depth and output in one place instead of threading them through `inout`
/// parameters.
private final class SourceLexer {
    private let scalars: [Character]
    private let count: Int
    private var output: [Character]
    private var i = 0
    private var depth = 0
    /// Brace depth at the start of each 0-based line. Line 1 always starts at zero.
    private(set) var lineStartDepths: [Int] = [0]
    private(set) var failed = false

    init(_ content: String) {
        scalars = Array(content)
        count = scalars.count
        output = Array(repeating: " ", count: scalars.count)
    }

    var outputLines: [String] {
        String(output).components(separatedBy: "\n")
    }

    func run() {
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
                skipBlockComment()
                continue
            }

            // String literal: `"..."` or raw `#*"..."#*`, single-line or multiline.
            if c == "\"" || isRawStringStart(at: i) {
                if !copyStringLiteral() { failed = true }
                continue
            }

            if c == "{" { depth += 1 }
            if c == "}" { depth -= 1 }
            output[i] = c
            i += 1
        }
    }

    /// Preserve the newline at `index` and record the depth that the next line starts at.
    private func recordNewline(at index: Int) {
        lineStartDepths.append(depth)
        output[index] = "\n"
    }

    private func skipBlockComment() {
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
    }

    /// Consume one string literal starting at the current position, which must be a `"` or the
    /// first `#` of a raw `#*"` opener. The literal's text is blanked and its interpolation
    /// bodies are copied through as code. Returns true when a closing delimiter was found,
    /// leaving the cursor past it; false means EOF was reached first.
    private func copyStringLiteral() -> Bool {
        var hashes = 0
        while i + hashes < count, scalars[i + hashes] == "#" { hashes += 1 }
        var cursor = i + hashes + 1
        guard cursor < count else { return false }
        let multiline = cursor + 1 < count
            && scalars[cursor] == "\"" && scalars[cursor + 1] == "\""
        if multiline { cursor += 2 }
        i = cursor
        while i < count {
            // Interpolation is real code: `\(` normally, `\#*(` inside a raw string.
            if scalars[i] == "\\" {
                var k = i + 1
                var h = 0
                while k < count, h < hashes, scalars[k] == "#" { h += 1; k += 1 }
                if h == hashes, k < count, scalars[k] == "(" {
                    var p = i
                    while p <= k { output[p] = scalars[p]; p += 1 }
                    i = k + 1
                    copyInterpolationBody()
                    continue
                }
            }
            if hashes > 0 {
                // Raw close: the quote run plus exactly `hashes` hashes.
                let quoteCount = multiline ? 3 : 1
                if scalars[i] == "\"" {
                    var q = 0
                    while q < quoteCount, i + q < count, scalars[i + q] == "\"" { q += 1 }
                    var h = 0
                    while h < hashes, i + q + h < count, scalars[i + q + h] == "#" { h += 1 }
                    if q == quoteCount, h == hashes {
                        i += q + hashes
                        return true
                    }
                }
            } else if multiline {
                if scalars[i] == "\\", i + 1 < count, scalars[i + 1] != "\n" {
                    i += 2
                    continue
                }
                if scalars[i] == "\"", i + 2 < count,
                   scalars[i + 1] == "\"", scalars[i + 2] == "\"" {
                    i += 3
                    return true
                }
            } else {
                if scalars[i] == "\\" {
                    i += (i + 1 < count && scalars[i + 1] != "\n") ? 2 : 1
                    continue
                }
                if scalars[i] == "\"" {
                    i += 1
                    return true
                }
            }
            if scalars[i] == "\n" { recordNewline(at: i) }
            i += 1
        }
        return false
    }

    /// Copy the body of a `\( ... )` interpolation as real code. Parentheses are balanced so a
    /// nested call is kept whole, and a string literal nested in the interpolation is consumed
    /// whole by `copyStringLiteral`, so a `)` inside that literal cannot end the body early.
    /// The caller has already consumed the backslash and the opening parenthesis.
    private func copyInterpolationBody() {
        var nest = 1
        while i < count, nest > 0 {
            let c = scalars[i]
            if c == "\"" || isRawStringStart(at: i) {
                _ = copyStringLiteral()
                continue
            }
            if c == "(" {
                nest += 1
            } else if c == ")" {
                nest -= 1
            } else if c == "{" {
                depth += 1
            } else if c == "}" {
                depth -= 1
            }
            if c == "\n" {
                recordNewline(at: i)
            } else {
                output[i] = c
            }
            i += 1
        }
    }

    /// True when `index` starts the raw-string opener `#*"`.
    private func isRawStringStart(at index: Int) -> Bool {
        guard index < count, scalars[index] == "#" else { return false }
        var hashes = 0
        while index + hashes < count, scalars[index + hashes] == "#" { hashes += 1 }
        return index + hashes < count && scalars[index + hashes] == "\""
    }
}
