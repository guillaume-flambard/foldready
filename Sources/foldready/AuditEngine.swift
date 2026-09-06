import Foundation

struct CheckOutcome: Sendable {
    let key: String
    let title: String
    let weight: Double
    let score: Double
    let detail: String
    /// Raw counts behind the score: numerator, denominator, and whatever else the check
    /// weighed. Emitted in the JSON so a rebalance can be calibrated from stored results
    /// rather than by re-auditing a corpus from scratch.
    let signals: [String: Double]
    /// Apple-authoritative source the requirement is derived from. Every scored check
    /// must have one; `Scripts/check.sh` fails the build when it is empty.
    let reference: String
    let findings: [Finding]
}

/// A check before its weight is known. A check that does not apply to an app (no lists to
/// preserve state in, no root navigation to adapt) drops out and its weight is spread over
/// the others, rather than being scored as a failure — that fallback scoring is what made
/// `state` return 70 for seventeen of the twenty corpus apps.
private struct CheckResult {
    let key: String
    let title: String
    /// Nil when the check does not apply to this app.
    let score: Double?
    let detail: String
    let reference: String
    let findings: [Finding]
    let baseWeight: Double
    let signals: [String: Double]

    init(key: String, title: String, score: Double?, detail: String, reference: String,
         findings: [Finding], baseWeight: Double, signals: [String: Double] = [:]) {
        self.key = key
        self.title = title
        self.score = score
        self.detail = detail
        self.reference = reference
        self.findings = findings
        self.baseWeight = baseWeight
        self.signals = signals
    }
}

struct AuditStats: Sendable {
    let swiftFiles: Int
    let uiFiles: Int
    let excludedFiles: Int
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
    let blockers: [Blocker]
    let stats: AuditStats
    let hoursEstimate: Double

    /// True when the app has declined the resizable canvas, which makes the quality score
    /// a statement about code that never gets the room it is measured against.
    var scoreIsProvisional: Bool {
        blockers.contains { $0.id == Blockers.fullScreenOptOut }
    }

    var risk: String {
        if blockers.contains(where: \.stopsLaunch) { return "high" }
        switch totalScore {
        case ..<45: return "high"
        case 45..<70: return "medium"
        default: return "low"
        }
    }

    /// Bands calibrated on the twenty-app corpus (see docs/result-contract.md). Each band
    /// states a behaviour, not a rank.
    var grade: String {
        switch totalScore {
        case ..<25: return "F"
        case 25..<45: return "D"
        case 45..<65: return "C"
        case 65..<85: return "B"
        default: return "A"
        }
    }
}

enum AuditEngine {

    static func run(root: String, appName: String, screenshots: [String] = []) -> AuditResult {
        let allSwift = walk(extension: "swift", at: root)
        let plists = walk(extension: "plist", at: root)

        // Everything scored is measured over shipping UI files. Tests, snapshots,
        // generated code and vendored dependencies are counted and reported, not scored.
        let uiFiles = allSwift.filter { Exclusions.isUIFile($0) }
        let stats = makeStats(root: root, allSwift: allSwift, uiFiles: uiFiles, plists: plists)

        let blockers = [
            Blockers.sceneLifecycle(swiftFiles: allSwift),
            Blockers.fullScreen(plists: plists)
        ].compactMap { $0 }

        var results = [
            navigation(uiFiles: uiFiles),
            adaptiveLayout(uiFiles: uiFiles),
            adaptiveGeometry(uiFiles: uiFiles),
            statePreservation(uiFiles: uiFiles)
        ]
        if !screenshots.isEmpty {
            results.append(capturedLayout(screenshots: screenshots))
        }

        let outcomes = weighted(results)
        let findings = outcomes.flatMap(\.findings)
        let total = (outcomes.reduce(0.0) { $0 + $1.score * $1.weight } * 100).rounded()

        return AuditResult(
            root: root,
            appName: appName,
            generatedAt: Date(),
            totalScore: total,
            outcomes: outcomes,
            findings: Finding.deterministicOrder(findings),
            blockers: blockers,
            stats: stats,
            hoursEstimate: estimateHours(stats: stats, outcomes: outcomes, blockers: blockers)
        )
    }

    /// Applicable checks keep their share; the weight of the rest is spread proportionally,
    /// so the weights always sum to 1.
    private static func weighted(_ results: [CheckResult]) -> [CheckOutcome] {
        let applicable = results.filter { $0.score != nil }
        let base = applicable.reduce(0.0) { $0 + $1.baseWeight }
        guard base > 0 else { return [] }
        return applicable.map { r in
            CheckOutcome(key: r.key, title: r.title, weight: r.baseWeight / base,
                score: r.score ?? 0, detail: r.detail, signals: r.signals,
                reference: r.reference, findings: r.findings)
        }
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

    private static func makeStats(root: String, allSwift: [FileContent],
                                  uiFiles: [FileContent], plists: [FileContent]) -> AuditStats {
        var swiftui = 0, uikit = 0
        for file in uiFiles {
            if file.content.contains("import SwiftUI") { swiftui += 1 }
            if file.content.contains("import UIKit") { uikit += 1 }
        }
        let xibs = walk(extension: "xib", at: root).count
        let storyboards = walk(extension: "storyboard", at: root).count
        return AuditStats(
            swiftFiles: allSwift.count,
            uiFiles: uiFiles.count,
            excludedFiles: allSwift.count - uiFiles.count,
            swiftuiFiles: swiftui,
            uikitFiles: uikit,
            xibOrStoryboard: xibs + storyboards,
            infoPlists: plists.count)
    }

    // MARK: - Checks

    /// Whether the app has adopted a navigation container that can become a sidebar.
    ///
    /// Measured, not assumed: across the corpus, `adopted` is 0 for eighteen apps and 1
    /// for two. No formula can grade a signal that reality has not yet spread out, and
    /// the file-level denominator counted every file mentioning a stack, not the roots.
    /// So this is reported as the binary capability it is, at a weight that says it
    /// matters: it is the adaptation a wide canvas is for.
    private static func navigation(uiFiles: [FileContent]) -> CheckResult {
        var findings: [Finding] = []
        var adopted = 0
        var notAdopted: [String] = []

        for file in uiFiles {
            let sidebarCapable = file.content.contains("NavigationSplitView")
                || file.content.contains(".adaptiveSidebar()")
                || file.content.contains("tabBarController.sidebar")
                || file.content.contains("sidebar.preferredPlacement")
                || file.content.contains("preferredPlacement = .sidebar")
                || file.content.contains(".tabViewStyle(.sidebarAdaptable)")
            let hasRoot = file.content.contains("NavigationStack")
                || file.content.contains("NavigationView")
                || file.content.contains(": UITabBarController")
                || file.content.contains("UITabBarController {")

            if sidebarCapable {
                adopted += 1
            } else if hasRoot {
                notAdopted.append(file.path)
            }
        }

        let total = adopted + notAdopted.count
        guard total > 0 else {
            return CheckResult(key: "navigation", title: "Adaptive navigation / sidebar",
                score: nil, detail: "no root navigation container found",
                reference: Reference.tabBarSidebar, findings: [], baseWeight: 0.20,
                signals: ["adopted": 0, "containers": 0])
        }

        for path in notAdopted.sorted() {
            findings.append(Finding(check: "navigation", severity: .major,
                message: "Root navigation that cannot become a sidebar: the panes will not split when the scene is wide.",
                file: path, line: nil))
        }

        return CheckResult(
            key: "navigation", title: "Adaptive navigation / sidebar",
            score: adopted > 0 ? 1.0 : 0.0,
            detail: adopted > 0
                ? "\(adopted) sidebar-capable container(s) across \(total) navigation site(s)"
                : "no sidebar-capable container across \(total) navigation site(s)",
            reference: Reference.tabBarSidebar, findings: findings, baseWeight: 0.20,
            signals: ["adopted": Double(adopted), "containers": Double(total)])
    }

    /// Share of UI files free of fixed-geometry layout.
    ///
    /// Counting occurrences over every Swift file let a large codebase dilute real
    /// problems to nothing: Signal scored 100 with 22 offending files, WordPress 98 with
    /// 119. Offending files over UI files is a density, bounded in [0, 1], that two apps
    /// of very different sizes share when their code is equally affected.
    private static func adaptiveLayout(uiFiles: [FileContent]) -> CheckResult {
        var findings: [Finding] = []
        var offending = Set<String>()
        var iconFrames = 0

        for file in uiFiles {
            let previews = Exclusions.previewLines(in: file.content)
            let lines = file.content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                guard !previews.contains(index) else { continue }

                if Exclusions.matches(Exclusions.screenMainBounds, line) {
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .major,
                        message: "UIScreen.main.bounds is a fixed geometry read; use the view's own bounds or the window scene.",
                        file: file.path, line: index + 1))
                } else if Exclusions.matches(Exclusions.screenMain, line) {
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "UIScreen.main is deprecated in iOS 27; derive scale and geometry from the window scene and trait collection.",
                        file: file.path, line: index + 1))
                }

                switch Exclusions.isScorableFrame(line: line) {
                case .some(true):
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "Hardcoded frame larger than a control: it will not reflow when the scene changes width.",
                        file: file.path, line: index + 1))
                case .some(false):
                    // Icon-sized: reported as information, never scored. 92% of the frame
                    // findings on the corpus were this.
                    iconFrames += 1
                case .none:
                    break
                }
            }
        }

        guard !uiFiles.isEmpty else {
            return CheckResult(key: "adaptive-layout", title: "Adaptive layout",
                score: nil, detail: "no UI files found", reference: Reference.modernizeUIKit,
                findings: [], baseWeight: 0.35, signals: ["offending": 0, "ui_files": 0])
        }

        // Density with a soft decay rather than a linear share. A plain share made the
        // check near-constant on the corpus (stdev 3.2 across twenty apps), because a
        // large codebase dilutes a real problem; a hard threshold instead produced a
        // cliff, where 5.05% scored zero and 4.9% scored two. `1 / (1 + density/k)` falls
        // steeply where it matters and never reaches an implausible zero.
        // k = 0.03: 3% of UI files reading fixed geometry halves the check.
        let density = Double(offending.count) / Double(uiFiles.count)
        let score = 1.0 / (1.0 + density / Exclusions.layoutDensityHalfPoint)
        return CheckResult(
            key: "adaptive-layout", title: "Adaptive layout",
            score: score,
            detail: "\(offending.count) of \(uiFiles.count) UI file(s) use fixed geometry"
                + (iconFrames > 0 ? " · \(iconFrames) icon-sized frame(s) not scored" : ""),
            reference: Reference.modernizeUIKit, findings: findings, baseWeight: 0.35,
            signals: ["offending": Double(offending.count), "ui_files": Double(uiFiles.count),
                      "icon_frames": Double(iconFrames)])
    }

    /// Two halves: how widely the app reads size classes or effective geometry, and how
    /// much of its branching is on device idiom or interface orientation instead.
    private static func adaptiveGeometry(uiFiles: [FileContent]) -> CheckResult {
        var findings: [Finding] = []
        var aware = 0
        var deviceBranching = 0
        var internalStrings = 0

        for file in uiFiles {
            let previews = Exclusions.previewLines(in: file.content)
            var fileIsAware = false
            var fileBranchesOnDevice = false

            let lines = file.content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                guard !previews.contains(index) else { continue }
                if line.contains("horizontalSizeClass") || line.contains("verticalSizeClass")
                    || line.contains("didUpdateEffectiveGeometry") {
                    fileIsAware = true
                }
                if line.contains("userInterfaceIdiom") || line.contains("interfaceOrientation") {
                    fileBranchesOnDevice = true
                    findings.append(Finding(check: "adaptive-geometry", severity: .minor,
                        message: "Layout branching on device idiom or interface orientation; a resizable scene is described by its size class.",
                        file: file.path, line: index + 1))
                }
                if line.contains("foldState") || line.contains("angleDegrees")
                    || line.contains("mechanicalAngleDegrees") {
                    internalStrings += 1
                    findings.append(Finding(check: "adaptive-geometry", severity: .info,
                        message: "foldState/angleDegrees are internal framework strings, not public API. Rely on size classes and effective geometry.",
                        file: file.path, line: index + 1))
                }
            }
            if fileIsAware { aware += 1 }
            if fileBranchesOnDevice { deviceBranching += 1 }
        }

        guard !uiFiles.isEmpty else {
            return CheckResult(key: "adaptive-geometry", title: "Adaptive geometry",
                score: nil, detail: "no UI files found", reference: Reference.sizeClasses,
                findings: [], baseWeight: 0.35, signals: ["aware": 0, "device_branching": 0, "ui_files": 0])
        }

        // Coverage anchor, calibrated on the twenty-app corpus (2026-09-06): an app is
        // credited with full coverage once one UI file in fifty reads the scene geometry.
        // Recorded in docs/result-contract.md with its corpus and date, not hidden here.
        let target = max(1.0, Double(uiFiles.count) * Exclusions.geometryCoverageAnchor)
        let coverage = min(1.0, Double(aware) / target)
        // An app that branches on nothing has no purity problem. Scoring it zero punished
        // three corpus apps for an absence rather than for a mistake.
        let score: Double
        if aware + deviceBranching == 0 {
            score = coverage
        } else {
            let purity = Double(aware) / Double(aware + deviceBranching)
            score = 0.5 * coverage + 0.5 * purity
        }

        return CheckResult(
            key: "adaptive-geometry", title: "Adaptive geometry",
            score: score,
            detail: "\(aware) of \(uiFiles.count) UI file(s) read size classes or effective geometry, "
                + "\(deviceBranching) branch on device or orientation"
                + (internalStrings > 0 ? " · \(internalStrings) internal fold string(s)" : ""),
            reference: Reference.sizeClasses, findings: findings, baseWeight: 0.35,
            signals: ["aware": Double(aware), "device_branching": Double(deviceBranching),
                      "ui_files": Double(uiFiles.count)])
    }

    /// Share of stateful views that preserve their state.
    ///
    /// The laddered version returned 70 whenever the app had view models, which was
    /// seventeen of the twenty corpus apps.
    private static func statePreservation(uiFiles: [FileContent]) -> CheckResult {
        var findings: [Finding] = []
        var stateful = 0
        var preserved = 0

        for file in uiFiles {
            let holdsState = file.content.contains("List(")
                || file.content.contains("List {")
                || file.content.contains("ScrollView")
                || file.content.contains("UITableView")
                || file.content.contains("UICollectionView")
                || file.content.contains("Table(")
            guard holdsState else { continue }
            stateful += 1

            let preserves = file.content.contains("@SceneStorage")
                || file.content.contains("restorationIdentifier")
                || file.content.contains("preservesSelectionInNavigationStack")
                || file.content.contains("scrollPosition(")
                || file.content.contains("NSUserActivity")
            if preserves {
                preserved += 1
            } else {
                findings.append(Finding(check: "state", severity: .minor,
                    message: "Scroll or selection state is not preserved; a scene resize can rebuild the hierarchy and lose it.",
                    file: file.path, line: nil))
            }
        }

        guard stateful > 0 else {
            return CheckResult(key: "state", title: "State preservation",
                score: nil, detail: "no list or scroll views to preserve state in",
                reference: Reference.sceneStorage, findings: [], baseWeight: 0.10,
                signals: ["preserved": 0, "stateful": 0])
        }

        return CheckResult(
            key: "state", title: "State preservation",
            score: Double(preserved) / Double(stateful),
            detail: "\(preserved) of \(stateful) stateful view file(s) preserve state",
            reference: Reference.sceneStorage, findings: findings, baseWeight: 0.10,
            signals: ["preserved": Double(preserved), "stateful": Double(stateful)])
    }

    // MARK: - Visual check

    private static func capturedLayout(screenshots: [String]) -> CheckResult {
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

        guard analyzed > 0 else {
            return CheckResult(key: "captured-layout", title: "Captured layout (simulator)",
                score: nil, detail: "no screenshot could be decoded",
                reference: Reference.modernizeUIKit, findings: [], baseWeight: 0.20,
                signals: ["analyzed": 0])
        }

        let score = scores.reduce(0, +) / Double(analyzed)
        return CheckResult(
            key: "captured-layout", title: "Captured layout (simulator)",
            score: score,
            detail: "\(analyzed) screenshot(s) analyzed, avg layout score \(Int((score * 100).rounded()))%",
            reference: Reference.modernizeUIKit, findings: findings, baseWeight: 0.20,
            signals: ["analyzed": Double(analyzed)])
    }

    // MARK: - Effort estimate

    private static func estimateHours(stats: AuditStats, outcomes: [CheckOutcome],
                                      blockers: [Blocker]) -> Double {
        var hours = Double(stats.uiFiles) * 0.2

        for blocker in blockers {
            hours += blocker.stopsLaunch ? 8 : 0.5
        }
        for outcome in outcomes where outcome.score < 1 {
            let gap = 1 - outcome.score
            switch outcome.key {
            case "adaptive-layout": hours += Double(outcome.findings.count) * 0.3
            case "navigation": hours += gap * 24
            case "adaptive-geometry": hours += gap * 12
            case "state": hours += gap * 8
            default: break
            }
        }
        return (hours * 2).rounded() / 2
    }
}
