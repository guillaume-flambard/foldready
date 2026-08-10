import Foundation

struct CheckOutcome: Sendable {
    let key: String
    let title: String
    let weight: Double
    let score: Double
    let detail: String
    let findings: [Finding]
}

struct AuditStats: Sendable {
    let swiftFiles: Int
    let swiftuiFiles: Int
    let uikitFiles: Int
    let xibOrStoryboard: Int
    let infoPlists: Int
}

struct AuditResult: Sendable {
    let root: String
    let appName: String
    let generatedAt: Date
    let totalScore: Double
    let outcomes: [CheckOutcome]
    let findings: [Finding]
    let stats: AuditStats
    let hoursEstimate: Double
    var risk: String {
        switch totalScore {
        case ..<30: return "high"
        case 30..<61: return "medium"
        default: return "low"
        }
    }
    var grade: String {
        switch totalScore {
        case ..<30: return "F"
        case 30..<45: return "D"
        case 45..<60: return "C"
        case 60..<75: return "B"
        default: return "A"
        }
    }
}

enum AuditEngine {

    static func run(root: String, appName: String, screenshots: [String] = []) -> AuditResult {
        let swift = walk(extension: "swift", at: root)
        let plists = walk(extension: "plist", at: root)

        let stats = makeStats(root: root, swift: swift, plists: plists)

        var outcomes: [CheckOutcome] = []
        var findings: [Finding] = []

        func add(_ pair: (outcome: CheckOutcome, findings: [Finding])) {
            outcomes.append(pair.outcome)
            findings.append(contentsOf: pair.outcome.findings)
        }

        add(adaptiveLayout(swiftFiles: swift))
        add(requiresFullScreen(plists: plists))
        add(navigation(swiftFiles: swift))
        add(sceneLifecycle(swiftFiles: swift))
        add(foldState(swiftFiles: swift))
        add(statePreservation(swiftFiles: swift))
        add(frameworkRatio(stats: stats))

        // Optional visual check: screenshots captured on the widest simulator.
        if !screenshots.isEmpty {
            let captured = capturedLayout(screenshots: screenshots)
            add(captured)
            let scale = 1.0 - captured.outcome.weight
            outcomes = outcomes.map { o in
                CheckOutcome(key: o.key, title: o.title, weight: o.weight * scale,
                    score: o.score, detail: o.detail, findings: o.findings)
            }
        }

        let weighted = outcomes.reduce(0.0) { $0 + $1.score * $1.weight }
        let total = weighted * 100.0
        let hours = estimateHours(stats: stats, outcomes: outcomes)

        return AuditResult(
            root: root,
            appName: appName,
            generatedAt: Date(),
            totalScore: total.rounded(),
            outcomes: outcomes,
            findings: findings.sorted { $0.severity < $1.severity },
            stats: stats,
            hoursEstimate: hours
        )
    }

    // MARK: - Walking

    private static func walk(extension ext: String, at root: String) -> [FileContent] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: root) else { return [] }
        var result: [FileContent] = []
        while let rel = enumerator.nextObject() as? String {
            let url = URL(fileURLWithPath: rel)
            guard url.pathExtension == ext else { continue }
            let components = url.pathComponents
            if components.contains(".build") || components.contains("DerivedData")
                || components.contains(".git") || components.contains("node_modules")
                || components.contains("Pods") { continue }
            let full = (root as NSString).appendingPathComponent(rel)
            guard let data = fm.contents(atPath: full),
                  let text = String(data: data, encoding: .utf8) else { continue }
            result.append(FileContent(path: rel, content: text))
        }
        return result
    }

    private static func makeStats(root: String, swift: [FileContent], plists: [FileContent]) -> AuditStats {
        var swiftui = 0, uikit = 0
        for file in swift {
            if file.content.contains("import SwiftUI") { swiftui += 1 }
            if file.content.contains("import UIKit") { uikit += 1 }
        }
        let xibs = walk(extension: "xib", at: root).count
        let storyboards = walk(extension: "storyboard", at: root).count
        return AuditStats(
            swiftFiles: swift.count,
            swiftuiFiles: swiftui,
            uikitFiles: uikit,
            xibOrStoryboard: xibs + storyboards,
            infoPlists: plists.count
        )
    }

    // MARK: - Checks

    private static func adaptiveLayout(swiftFiles: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var fixedFrames = 0
        var screenMain = 0
        var screenMainOther = 0

        for file in swiftFiles {
            let lines = file.content.components(separatedBy: .newlines)
            for (idx, line) in lines.enumerated() {
                if line.contains("UIScreen.main.bounds") {
                    screenMain += 1
                    findings.append(Finding(check: "adaptive-layout", severity: .major,
                        message: "UIScreen.main.bounds is a fixed geometry read; use the scene coordinate space.",
                        file: file.path, line: idx + 1))
                } else if line.range(of: #"UIScreen\.main\b"#, options: .regularExpression) != nil {
                    screenMainOther += 1
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "UIScreen.main is deprecated in iOS 27; derive scale and geometry from the window scene and trait collection.",
                        file: file.path, line: idx + 1))
                }
                if line.range(of: #"\.frame\(width:\s*\d+\.?\d*[a-zA-Z]*\s*,\s*height:\s*\d+\.?\d*[a-zA-Z]*"#, options: .regularExpression) != nil {
                    fixedFrames += 1
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "Hardcoded frame (width and height literals) will not reflow on the 7.8 inch inner display.",
                        file: file.path, line: idx + 1))
                }
            }
        }

        let total = max(1, swiftFiles.count)
        let load = Double(fixedFrames) * 0.5 + Double(screenMain) * 2.0 + Double(screenMainOther) * 0.6
        let score = max(0.0, 1.0 - min(1.0, load / Double(total)))
        let detail = "\(fixedFrames) hardcoded frames, \(screenMain) UIScreen.main.bounds, \(screenMainOther) other UIScreen.main reads across \(swiftFiles.count) files"
        let outcome = CheckOutcome(key: "adaptive-layout", title: "Adaptive layout",
            weight: 0.22, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func requiresFullScreen(plists: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var blocked = false
        var scanned = 0
        for plist in plists {
            scanned += 1
            let s = plist.content
            if s.range(of: #"UIRequiresFullScreen"#, options: .regularExpression) != nil,
               s.range(of: #"<true/>"#, options: .regularExpression) != nil {
                blocked = true
                findings.append(Finding(check: "full-screen", severity: .critical,
                    message: "UIRequiresFullScreen=true skips Parallel View on the iPhone Fold. Remove it to opt in.",
                    file: plist.path, line: nil))
            }
        }
        let score: Double
        if blocked { score = 0 }
        else if scanned == 0 { score = 0.5 }
        else { score = 1 }
        let detail = blocked ? "UIRequiresFullScreen=true found" : (scanned == 0 ? "no Info.plist scanned, verify build settings" : "Parallel View not blocked")
        let outcome = CheckOutcome(key: "full-screen", title: "Parallel View opt-in",
            weight: 0.08, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func navigation(swiftFiles: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var split = 0, sidebar = 0, stack = 0, stacksWithoutSplit: [String] = []

        for file in swiftFiles {
            if file.content.contains("NavigationSplitView") { split += 1 }
            if file.content.contains(".adaptiveSidebar()") || file.content.contains("tabBarController.sidebar")
                || file.content.contains("preferredPlacement = .sidebar") { sidebar += 1 }
            if file.content.contains("NavigationStack") || file.content.contains("NavigationView") {
                stack += 1
                if !file.content.contains("NavigationSplitView") && !file.content.contains(".adaptiveSidebar()") {
                    stacksWithoutSplit.append(file.path)
                }
            }
        }

        for path in stacksWithoutSplit {
            findings.append(Finding(check: "navigation", severity: .major,
                message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.",
                file: path, line: nil))
        }

        let score: Double
        if split > 0 || sidebar > 0 { score = 1.0 }
        else if stacksWithoutSplit.isEmpty && stack > 0 { score = 0.7 }
        else if stack > 0 { score = 0.4 }
        else { score = 0.5 }

        let detail = "\(split) NavigationSplitView, \(sidebar) sidebar opt-ins, \(stack) stacks"
        let outcome = CheckOutcome(key: "navigation", title: "Adaptive navigation / sidebar",
            weight: 0.25, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func sceneLifecycle(swiftFiles: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var swiftuiApp = false
        var sceneDelegate = false
        var sceneManifest = false

        for file in swiftFiles {
            if file.content.contains("@main") && file.content.contains("App:") { swiftuiApp = true }
            if file.content.contains("UIWindowSceneDelegate") || file.content.contains("UISceneDelegate") { sceneDelegate = true }
            if file.content.contains("UIApplicationSceneManifest") || file.content.contains("UISceneConfiguration") { sceneManifest = true }
        }

        if !swiftuiApp && !sceneDelegate && !sceneManifest {
            findings.append(Finding(check: "scene", severity: .major,
                message: "No UIScene lifecycle detected. The scene lifecycle is mandatory on iOS 27; apps without it fail to adapt to fold transitions.",
                file: nil, line: nil))
        }

        let score: Double
        if swiftuiApp { score = 1.0 }
        else if sceneDelegate || sceneManifest { score = 0.8 }
        else { score = 0.2 }

        let detail = swiftuiApp ? "SwiftUI @main App scene" : (sceneDelegate ? "UIKit scene delegate" : "scene lifecycle missing")
        let outcome = CheckOutcome(key: "scene", title: "UIScene lifecycle",
            weight: 0.15, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func foldState(swiftFiles: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var effectiveGeometry = 0
        var sizeClasses = 0
        var geometryReader = 0
        var internalStrings = 0
        var idiomOrientation = 0

        for file in swiftFiles {
            let lines = file.content.components(separatedBy: .newlines)
            if file.content.contains("didUpdateEffectiveGeometry") { effectiveGeometry += 1 }
            if file.content.contains("horizontalSizeClass") || file.content.contains("verticalSizeClass") { sizeClasses += 1 }
            if file.content.contains("GeometryReader") { geometryReader += 1 }
            for (idx, line) in lines.enumerated() {
                if line.contains("foldState") || line.contains("angleDegrees") || line.contains("mechanicalAngleDegrees") {
                    internalStrings += 1
                    findings.append(Finding(check: "fold-state", severity: .info,
                        message: "foldState/angleDegrees are internal framework strings, not public API. Rely on size classes and effective geometry instead.",
                        file: file.path, line: idx + 1))
                }
                if line.contains("userInterfaceIdiom") || line.contains("interfaceOrientation") {
                    idiomOrientation += 1
                    findings.append(Finding(check: "fold-state", severity: .minor,
                        message: "userInterfaceIdiom/interfaceOrientation are not meaningful for layout in resizable environments; use size classes.",
                        file: file.path, line: idx + 1))
                }
            }
        }

        if effectiveGeometry == 0 && sizeClasses == 0 && geometryReader == 0 {
            findings.append(Finding(check: "fold-state", severity: .minor,
                message: "No adaptive geometry handling (didUpdateEffectiveGeometry, size classes, GeometryReader). The app runs via Parallel View, but has no opinion about wider canvases.",
                file: nil, line: nil))
        }

        let score: Double
        if effectiveGeometry > 0 || sizeClasses > 0 { score = 1.0 }
        else if geometryReader > 0 { score = 0.7 }
        else { score = 0.2 }
        // small penalty for layout decided by idiom/orientation
        let penalized = max(0.0, score - Double(idiomOrientation) * 0.05)

        let detail = "\(effectiveGeometry) effectiveGeometry, \(sizeClasses) size classes, \(geometryReader) GeometryReader, \(internalStrings) internal strings"
        let outcome = CheckOutcome(key: "fold-state", title: "Adaptive geometry (fold-aware)",
            weight: 0.12, score: penalized, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func statePreservation(swiftFiles: [FileContent]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var sceneStorage = 0, restoration = 0, viewModels = 0
        var any = false

        for file in swiftFiles {
            if file.content.contains("@SceneStorage") { sceneStorage += 1; any = true }
            if file.content.contains("restorationIdentifier") || file.content.contains("preservesSelectionInNavigationStack")
                || file.content.contains("PreservedState") { restoration += 1; any = true }
            if file.content.contains("@Observable") || file.content.contains("@StateObject") || file.content.contains("@ObservableObject") {
                viewModels += 1
            }
        }

        if !any {
            findings.append(Finding(check: "state", severity: .minor,
                message: "No explicit scroll/selection state preservation. A fold transition can rebuild the view hierarchy; state held only in views is lost.",
                file: nil, line: nil))
        }

        let score: Double
        if sceneStorage > 0 || restoration > 0 { score = 1.0 }
        else if viewModels > 0 { score = 0.7 }
        else { score = 0.3 }

        let detail = "\(sceneStorage) @SceneStorage, \(restoration) restoration, \(viewModels) view models"
        let outcome = CheckOutcome(key: "state", title: "State preservation",
            weight: 0.08, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    private static func frameworkRatio(stats: AuditStats) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        let total = stats.swiftuiFiles + stats.uikitFiles
        let score: Double
        if total == 0 {
            score = 0.5
            findings.append(Finding(check: "framework", severity: .info,
                message: "No SwiftUI or UIKit imports detected; framework ratio unknown.",
                file: nil, line: nil))
        } else {
            score = Double(stats.swiftuiFiles) / Double(total)
        }
        let detail = "\(stats.swiftuiFiles) SwiftUI files, \(stats.uikitFiles) UIKit files"
        let outcome = CheckOutcome(key: "framework", title: "SwiftUI vs UIKit",
            weight: 0.10, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    // MARK: - Visual check

    private static func capturedLayout(screenshots: [String]) -> (outcome: CheckOutcome, findings: [Finding]) {
        var findings: [Finding] = []
        var scores: [Double] = []
        var analyzed = 0

        for path in screenshots {
            if let result = try? VisualAnalysis.analyze(png: path) {
                analyzed += 1
                scores.append(result.layoutScore)
                if result.letterbox > 0.08 {
                    findings.append(Finding(check: "captured-layout", severity: .major,
                        message: String(format: "Letterboxing detected (%.0f%% of the frame is uniform margin). The layout hardcodes a portrait fit and will show bands when it gets horizontal room.",
                            result.letterbox * 100),
                        file: result.file, line: nil))
                }
            }
        }

        let score = analyzed == 0 ? 0.5 : scores.reduce(0, +) / Double(analyzed)

        let detail = analyzed == 0
            ? "no screenshot could be decoded"
            : "\(analyzed) screenshot(s) analyzed, avg layout score \(Int((score * 100).rounded()))%"
        let outcome = CheckOutcome(key: "captured-layout", title: "Captured layout (simulator)",
            weight: 0.10, score: score, detail: detail, findings: findings)
        return (outcome, findings)
    }

    // MARK: - Effort estimate

    private static func estimateHours(stats: AuditStats, outcomes: [CheckOutcome]) -> Double {
        var hours = Double(stats.swiftFiles) * 0.35

        for outcome in outcomes {
            switch outcome.key {
            case "adaptive-layout":
                hours += Double(outcome.findings.count) * 0.3
            case "full-screen":
                if outcome.score == 0 { hours += 0.5 }
            case "navigation":
                if outcome.score < 1 { hours += Double(outcome.findings.count) * 1.5 + 2 }
            case "fold-state":
                if outcome.score < 1 { hours += 3 }
            case "state":
                if outcome.score < 1 { hours += 2 }
            case "scene":
                if outcome.score < 0.8 { hours += 2 }
            default:
                break
            }
        }
        return (hours * 2).rounded() / 2
    }
}
