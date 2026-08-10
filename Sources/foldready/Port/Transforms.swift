import Foundation

enum Transforms {

    // MARK: - Safe tier

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
            notes.append("Removed UIRequiresFullScreen from \(plist.path) — opts the app into Parallel View / resizability.")
        }
        return Patch(transformId: "remove-fullscreen", title: "Remove UIRequiresFullScreen opt-out",
            tier: .safe, edits: edits, newFiles: [:], notes: notes)
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
            tier: .safe, edits: edits, newFiles: [:], notes: notes)
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

    // MARK: - Review tier

    static func sceneLifecycle(_ input: TransformInput) -> Patch {
        let swiftuiApp = input.swiftFiles.contains { $0.content.contains(": App") && $0.content.contains("import SwiftUI") }
        let uikitApp = input.swiftFiles.contains { $0.content.contains("@UIApplicationMain") || ($0.content.contains("@main") && $0.content.contains("UIApplicationDelegate")) }
        let hasScene = input.swiftFiles.contains {
            $0.content.contains("UIWindowSceneDelegate") || $0.content.contains("UISceneDelegate") || $0.content.contains("UISceneConfiguration")
        }
        guard uikitApp && !hasScene && !swiftuiApp else {
            return Patch(transformId: "scene-lifecycle", title: "UIScene lifecycle",
                tier: .review, edits: [], newFiles: [:],
                notes: hasScene || swiftuiApp ? ["Scene lifecycle already present."] : ["Not a UIKit app-delegate app; nothing to do."])
        }

        let sceneDelegate = """
        import UIKit

        // Generated by FoldReady — migrate your AppDelegate's window setup here.
        // See Apple Technote TN3187 for the full UIScene migration.
        class SceneDelegate: UIResponder, UIWindowSceneDelegate {

            var window: UIWindow?

            func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                       options connectionOptions: UIScene.ConnectionOptions) {
                guard let windowScene = scene as? UIWindowScene else { return }
                let window = UIWindow(windowScene: windowScene)
                // TODO: set the app's real root view controller here (previously built in AppDelegate).
                window.rootViewController = UIViewController()
                window.makeKeyAndVisible()
                self.window = window
            }
        }
        """
        let manifest = """
        \t<key>UIApplicationSceneManifest</key>
        \t<dict>
        \t\t<key>UIApplicationSupportsMultipleScenes</key>
        \t\t<false/>
        \t\t<key>UISceneConfigurations</key>
        \t\t<dict>
        \t\t\t<key>UIWindowSceneSessionRoleApplication</key>
        \t\t\t<array>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>UISceneConfigurationName</key>
        \t\t\t\t\t<string>Default Configuration</string>
        \t\t\t\t\t<key>UISceneDelegateClassName</key>
        \t\t\t\t\t<string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
        \t\t\t\t</dict>
        \t\t\t</array>
        \t\t</dict>
        \t</dict>
        """

        var edits: [FileEdit] = []
        var notes: [String] = []
        if let plist = bestPlist(input.plists) {
            if !plist.content.contains("UIApplicationSceneManifest") {
                let after = plist.content.replacingOccurrences(
                    of: #"</dict>\s*</plist>"#,
                    with: "\(manifest)\n</dict>\n</plist>",
                    options: .regularExpression)
                edits.append(FileEdit(path: plist.path, before: plist.content, after: after))
                notes.append("Added UIApplicationSceneManifest to \(plist.path).")
            }
        } else {
            notes.append("No Info.plist found — add the UIApplicationSceneManifest manually (see TN3187).")
        }
        notes.append("UIScene lifecycle is REQUIRED from the iOS 27 SDK — apps without it fail to launch (TN3187).")
        notes.append("Set the real rootViewController in SceneDelegate (currently a placeholder).")
        return Patch(transformId: "scene-lifecycle", title: "Migrate to UIScene lifecycle",
            tier: .review, edits: edits, newFiles: ["SceneDelegate.swift": sceneDelegate], notes: notes)
    }

    static func screenBounds(_ input: TransformInput) -> Patch {
        var edits: [FileEdit] = []
        var notes: [String] = []
        // Exact full-bleed patterns that are safe to replace (incl. .size variants).
        let fullBoth = try? NSRegularExpression(pattern: #"\.frame\(width:\s*UIScreen\.main\.bounds(?:\.size)?\.width\s*,\s*height:\s*UIScreen\.main\.bounds(?:\.size)?\.height\s*\)"#, options: [])
        let fullWidth = try? NSRegularExpression(pattern: #"\.frame\(width:\s*UIScreen\.main\.bounds(?:\.size)?\.width\s*\)"#, options: [])
        let boundsRead = try? NSRegularExpression(pattern: #"UIScreen\.main\.bounds"#, options: [])

        for file in input.swiftFiles {
            guard file.content.contains("UIScreen.main.bounds") else { continue }
            var after = file.content
            if let fullBoth {
                after = fullBoth.stringByReplacingMatches(in: after, options: [], range: NSRange(after.startIndex..., in: after), withTemplate: ".frame(maxWidth: .infinity, maxHeight: .infinity)")
            }
            if let fullWidth {
                after = fullWidth.stringByReplacingMatches(in: after, options: [], range: NSRange(after.startIndex..., in: after), withTemplate: ".frame(maxWidth: .infinity)")
            }
            let remaining = boundsRead?.numberOfMatches(in: after, range: NSRange(after.startIndex..., in: after)) ?? 0
            if remaining > 0 {
                notes.append("\(file.path): \(remaining) UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.")
            }
            if after != file.content {
                edits.append(FileEdit(path: file.path, before: file.content, after: after))
            }
        }
        notes.append("UIScreen.main is deprecated in iOS 27; reads must come from the window scene / effective geometry.")
        return Patch(transformId: "screen-bounds", title: "Replace UIScreen.main.bounds",
            tier: .review, edits: edits, newFiles: [:], notes: notes)
    }

    static func adaptiveNavigation(_ input: TransformInput) -> Patch {
        var edits: [FileEdit] = []
        var notes: [String] = []
        let bodyView = "var body: some View {"
        let bodyScene = "var body: some Scene {"

        for file in input.swiftFiles {
            let whole = file.content
            guard whole.contains("NavigationStack"), !whole.contains("NavigationSplitView") else { continue }
            var searchStart = whole.startIndex
            var wrappedOne = false

            while true {
                let viewRange = whole.range(of: bodyView, options: [.literal], range: searchStart..<whole.endIndex)
                let sceneRange = whole.range(of: bodyScene, options: [.literal], range: searchStart..<whole.endIndex)
                guard let bodyRange = viewRange ?? sceneRange else { break }
                let openBrace = whole.index(bodyRange.upperBound, offsetBy: -1)
                guard whole[openBrace] == "{" else { break }
                guard let bodyClose = Lex.matchingCloseBrace(whole, openBrace: openBrace) else { break }

                let triviaEnd = Lex.skipTrivia(from: whole.index(after: openBrace), in: whole)
                let bodyInnerEnd = bodyClose
                guard triviaEnd < bodyInnerEnd, Lex.word("NavigationStack", at: triviaEnd, in: whole) else {
                    notes.append("\(file.path): body root is not a bare NavigationStack (TabView/ZStack/Group/sheet) — left as-is.")
                    searchStart = bodyClose
                    continue
                }
                guard let stackOpen = whole[triviaEnd..<bodyInnerEnd].firstIndex(of: "{"),
                      let stackClose = Lex.matchingCloseBrace(whole, openBrace: stackOpen) else { break }

                if !wrappedOne {
                    let prefix = String(whole[..<triviaEnd])
                    let block = String(whole[triviaEnd...stackClose])
                    let suffix = String(whole[whole.index(after: stackClose)...])
                    let after = prefix + "NavigationSplitView { " + block + " } detail: { Color.clear }" + suffix
                    edits.append(FileEdit(path: file.path, before: whole, after: after))
                    wrappedOne = true
                    notes.append("\(file.path): wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.")
                    notes.append("\(file.path): move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.")
                } else {
                    notes.append("\(file.path): additional root NavigationStack in another body — one wrap per file, left as-is.")
                }
                searchStart = bodyClose
            }
        }
        if edits.isEmpty && notes.isEmpty {
            notes.append("No root NavigationStack without an existing NavigationSplitView found.")
        }
        return Patch(transformId: "adaptive-navigation", title: "Root NavigationStack → NavigationSplitView",
            tier: .review, edits: edits, newFiles: [:], notes: notes)
    }

    // MARK: - Manual tier

    static func statePreservation(_ input: TransformInput) -> Patch {
        var notes: [String] = []
        let sceneStorage = try? NSRegularExpression(pattern: #"@SceneStorage|restorationIdentifier|preservesSelectionInNavigationStack"#, options: [])
        for file in input.swiftFiles {
            if file.content.contains("List") || file.content.contains("ScrollView") {
                let has = sceneStorage?.firstMatch(in: file.content, range: NSRange(file.content.startIndex..., in: file.content)) != nil
                if !has {
                    notes.append("\(file.path): add @SceneStorage for selection/scroll so the fold transition keeps user state.")
                }
            }
        }
        return Patch(transformId: "state-preservation", title: "State preservation across fold transitions",
            tier: .manual, edits: [], newFiles: [:],
            notes: notes.isEmpty ? ["No list/scroll views detected — nothing to do."] : notes + [
                "Pattern: @SceneStorage(\"selection\") var selection: String? — survives the scene geometry change.",
            ])
    }

    static func dehardcodeFrames(_ input: TransformInput) -> Patch {
        var notes: [String] = []
        let frameRe = try? NSRegularExpression(pattern: #"\.frame\(width:\s*\d+\.?\d*[a-zA-Z]*\s*,\s*height:\s*\d+\.?\d*[a-zA-Z]*"#, options: [])
        for file in input.swiftFiles {
            if let frameRe {
                let count = frameRe.numberOfMatches(in: file.content, range: NSRange(file.content.startIndex..., in: file.content))
                if count > 0 { notes.append("\(file.path): \(count) hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.") }
            }
        }
        return Patch(transformId: "dehardcode-frames", title: "De-hardcode fixed frames",
            tier: .manual, edits: [], newFiles: [:],
            notes: notes.isEmpty ? ["No hardcoded frames detected."] : notes)
    }

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
