import Foundation

enum Transforms {

    // MARK: - Provably safe transforms

    static func removeFullScreen(_ input: TransformInput) -> Patch {
        var edits: [FileEdit] = []
        var notes: [String] = []
        let pattern = #"\s*<key>UIRequiresFullScreen</key>\s*(?:<(?:true|false)/>|<string>[^<]*</string>)?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        for plist in input.plists {
            guard plist.content.contains("UIRequiresFullScreen") else { continue }
            guard let regex else { continue }
            let ns = plist.content as NSString
            let range = NSRange(location: 0, length: ns.length)
            let cleaned = regex.stringByReplacingMatches(in: plist.content, options: [], range: range, withTemplate: "")
            let collapsed = cleaned.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            guard collapsed != plist.content else { continue }
            edits.append(FileEdit(path: plist.path, before: plist.content, after: collapsed))
            notes.append("Removed UIRequiresFullScreen from \(plist.path) — opts the app into resizable presentation.")
        }
        return Patch(transformId: "remove-fullscreen", title: "Remove UIRequiresFullScreen opt-out",
            edits: edits, newFiles: [:], notes: notes)
    }

    static func sidebarOptIn(_ input: TransformInput) -> Patch {
        var edits: [FileEdit] = []
        var notes: [String] = []
        let subclass = try? NSRegularExpression(pattern: #"class\s+\w+\s*:\s*[^\{]*UITabBarController"#, options: [])
        let deploy = deploymentTarget(input.root)

        for file in input.swiftFiles {
            guard let subclass,
                  subclass.firstMatch(in: file.content, range: NSRange(file.content.startIndex..., in: file.content)) != nil else { continue }
            if file.content.contains("tabSidebar") || file.content.contains("preferredPlacement") {
                notes.append("\(file.path): sidebar already opted in.")
                continue
            }
            let lines = file.content.components(separatedBy: .newlines)
            let classIndices = lines.enumerated().compactMap { idx, line in
                subclass.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil ? idx : nil
            }
            var inserts: [(at: Int, content: [String])] = []
            for (ci, clsIdx) in classIndices.enumerated() {
                let regionEnd = (ci + 1 < classIndices.count) ? classIndices[ci + 1] : lines.count
                var at: Int?
                for j in clsIdx..<regionEnd {
                    if lines[j].contains("override func viewDidLoad()") || lines[j].contains("super.viewDidLoad()") {
                        at = j + 1
                        break
                    }
                }
                if let at {
                    let indent = lines[at - 1].prefix(while: { $0 == " " || $0 == "\t" })
                    let content: [String]
                    if needsAvailability(deploy) {
                        content = [
                            "\(indent)if #available(iOS 26.0, *) {",
                            "\(indent)\tmode = .tabSidebar",
                            "\(indent)\tsidebar.preferredPlacement = .sidebar",
                            "\(indent)}",
                        ]
                    } else {
                        content = [
                            "\(indent)mode = .tabSidebar",
                            "\(indent)sidebar.preferredPlacement = .sidebar",
                        ]
                    }
                    inserts.append((at, content))
                } else {
                    notes.append("\(file.path): UITabBarController subclass without a viewDidLoad — add one to set mode = .tabSidebar.")
                }
            }
            if inserts.isEmpty { continue }
            var out = lines
            for ins in inserts.sorted(by: { $0.at > $1.at }) {
                out.insert(contentsOf: ins.content, at: ins.at)
            }
            edits.append(FileEdit(path: file.path, before: file.content, after: out.joined(separator: "\n")))
            notes.append("\(file.path): tab bar becomes a sidebar on wide canvases (mode = .tabSidebar).\(needsAvailability(deploy) ? " Guarded with #available(iOS 26.0, *)." : "")")
        }
        return Patch(transformId: "sidebar-optin", title: "UIKit tab bar → sidebar opt-in",
            edits: edits, newFiles: [:], notes: notes)
    }

    private static func deploymentTarget(_ root: String) -> Double? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: root) else { return nil }
        for f in files where f.hasSuffix(".pbxproj") {
            let full = (root as NSString).appendingPathComponent(f)
            guard let data = fm.contents(atPath: full), let s = String(data: data, encoding: .utf8) else { continue }
            guard let re = try? NSRegularExpression(pattern: #"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([\d.]+);"#, options: []),
                  let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
                  let r = Range(m.range(at: 1), in: s) else { continue }
            return Double(s[r])
        }
        return nil
    }

    private static func needsAvailability(_ target: Double?) -> Bool {
        guard let target else { return true } // unknown target → safe default
        return target < 26.0
    }

    /// Pick the main app Info.plist: prefer a root-level "Info.plist", else one
    /// carrying CFBundleExecutable, else the first non-Tests plist.
    private static func bestPlist(_ plists: [FileContent]) -> FileContent? {
        let candidates = plists.filter { !$0.path.contains("Tests") }
        if let rootInfo = candidates.first(where: { ($0.path as NSString).lastPathComponent == "Info.plist"
            && ($0.path as NSString).pathComponents.count <= 2 }) { return rootInfo }
        if let executable = candidates.first(where: { $0.content.contains("CFBundleExecutable") }) { return executable }
        return candidates.first
    }

    // The transforms that used to live here (scene lifecycle, UIScreen.main.bounds,
    // root NavigationSplitView wrapping, state preservation, de-hardcoding frames) are
    // gone by design. None of them was provably safe from a pattern matcher, and Xcode 27
    // ships an app modernization agent skill that does the same edits with the build
    // graph and the type checker. FoldReady now emits a work order for that work instead
    // (Port/WorkOrder.swift) and verifies the result.

    // MARK: - Swift lexer helpers (comment- and string-aware)

    enum Lex {
        private enum State { case code, lineComment, blockComment, string, multiline, char }

        /// Skip whitespace and comments (// and /* */) from `i`.
        static func skipTrivia(from i: String.Index, in s: String) -> String.Index {
            var i = i
            let end = s.endIndex
            while i < end {
                let c = s[i]
                if c == " " || c == "\t" || c == "\n" || c == "\r" { i = s.index(after: i); continue }
                if c == "/", s.index(after: i) < end {
                    let j = s.index(after: i)
                    let c2 = s[j]
                    if c2 == "/" {
                        while i < end, s[i] != "\n" { i = s.index(after: i) }
                        continue
                    }
                    if c2 == "*" {
                        i = s.index(after: j)
                        while i < end {
                            if s[i] == "*", s.index(after: i) < end, s[s.index(after: i)] == "/" {
                                i = s.index(after: s.index(after: i))
                                break
                            }
                            i = s.index(after: i)
                        }
                        continue
                    }
                }
                break
            }
            return i
        }

        /// True if the identifier starting exactly at `i` equals `word` (word boundaries).
        static func word(_ word: String, at i: String.Index, in s: String) -> Bool {
            guard let r = s.range(of: word, options: [.literal], range: i..<s.endIndex), r.lowerBound == i else { return false }
            let after = r.upperBound
            if after < s.endIndex {
                let c = s[after]
                if c.isLetter || c.isNumber || c == "_" { return false }
            }
            return true
        }

        /// Match the `}` that closes the `{` at `openBrace`, ignoring braces inside
        /// strings, character literals, multi-line strings and comments.
        static func matchingCloseBrace(_ s: String, openBrace: String.Index) -> String.Index? {
            var depth = 0
            var i = s.index(after: openBrace)
            let end = s.endIndex
            var st: State = .code

            while i < end {
                let c = s[i]
                switch st {
                case .lineComment:
                    if c == "\n" { st = .code }
                case .blockComment:
                    if c == "*", s.index(after: i) < end, s[s.index(after: i)] == "/" {
                        st = .code
                        i = s.index(after: i)
                    }
                case .string:
                    if c == "\\" { i = s.index(after: i) }
                    else if c == "\"" { st = .code }
                case .char:
                    if c == "\\" { i = s.index(after: i) }
                    else if c == "'" { st = .code }
                case .multiline:
                    if c == "\"", s.index(after: i) < end, s[s.index(after: i)] == "\"" {
                        let k = s.index(after: s.index(after: i))
                        if k < end, s[k] == "\"" { st = .code; i = k }
                    }
                case .code:
                    if c == "\"" {
                        if s.index(after: i) < end, s[s.index(after: i)] == "\"" {
                            let k = s.index(after: s.index(after: i))
                            if k < end, s[k] == "\"" { st = .multiline; i = k }
                            else { st = .string }
                        } else { st = .string }
                    } else if c == "'" {
                        st = .char
                    } else if c == "/", s.index(after: i) < end {
                        let j = s.index(after: i)
                        if s[j] == "/" { st = .lineComment; i = j }
                        else if s[j] == "*" { st = .blockComment; i = j }
                    } else if c == "{" {
                        depth += 1
                    } else if c == "}" {
                        if depth == 0 { return i }
                        depth -= 1
                    }
                }
                i = s.index(after: i)
            }
            return nil
        }
    }

    static func matches(_ regex: NSRegularExpression?, _ s: String) -> Bool {
        guard let regex else { return false }
        return regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
}
