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
    /// UI files the lexer could not finish. Such a file is excluded from scoring and
    /// reported rather than scored clean, so the count must be visible in the result.
    ///
    /// `var`, not `let`: a stored `let` with a default is omitted from the synthesised
    /// memberwise initialiser, which would leave `AuditEngine` no way to set the count.
    var failedFiles: Int = 0
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
    /// Duo surfaces the source suggests. Advisory: they never enter the score, any check
    /// score, or the gate verdict.
    let advisory: [AdvisoryFinding]
    /// Toolchain generations read from the scanned project files, reported as read.
    let build: BuildSignal

    init(
        root: String,
        appName: String,
        generatedAt: Date,
        totalScore: Double,
        outcomes: [CheckOutcome],
        findings: [Finding],
        blockers: [Blocker],
        stats: AuditStats,
        hoursEstimate: Double,
        advisory: [AdvisoryFinding] = [],
        build: BuildSignal = .empty
    ) {
        self.root = root
        self.appName = appName
        self.generatedAt = generatedAt
        self.totalScore = totalScore
        self.outcomes = outcomes
        self.findings = findings
        self.blockers = blockers
        self.stats = stats
        self.hoursEstimate = hoursEstimate
        self.advisory = advisory
        self.build = build
    }

    /// Runtime checks that would settle the advisory surface signals, once each.
    var advisoryRuntimeChecks: [String] {
        DuoSurfaces.runtimeChecks(for: advisory)
    }

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
        let projectFiles = walk(extension: "pbxproj", at: root)
        let build = BuildFloor.read(projectFiles: projectFiles)

        // Everything scored is measured over shipping UI files. Tests, snapshots,
        // generated code and vendored dependencies are counted and reported, not scored.
        let uiFiles = allSwift.filter { Exclusions.isUIFile($0) }
        // Lex each UI file once and hand the checks that view, so a comment or the literal
        // text of a string can never be scored. A file the lexer cannot finish is reported
        // through `stats.failedFiles` and excluded, never silently scored clean.
        let lexed = uiFiles.map { SwiftLexer.lex($0) }
        let scorable = lexed.filter { !$0.failed }
        let stats = makeStats(root: root, allSwift: allSwift, uiFiles: uiFiles, plists: plists,
                              failedFiles: lexed.count - scorable.count)

        let blockers = [
            Blockers.sceneLifecycle(swiftFiles: allSwift),
            Blockers.fullScreen(plists: plists)
        ].compactMap { $0 }

        var results = [
            navigation(lexed: scorable),
            adaptiveLayout(lexed: scorable),
            adaptiveGeometry(lexed: scorable),
            statePreservation(lexed: scorable),
            idiom(lexed: scorable),
            orientation(lexed: scorable, plists: plists),
            buildToolchain(build: build)
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
            hoursEstimate: estimateHours(stats: stats, outcomes: outcomes, blockers: blockers),
            advisory: DuoSurfaces.analyze(lexed: scorable),
            build: build
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
                                  uiFiles: [FileContent], plists: [FileContent],
                                  failedFiles: Int) -> AuditStats {
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
            infoPlists: plists.count,
            failedFiles: failedFiles)
    }

    // MARK: - Checks

    /// Whole-file token presence over shipping lines only. The navigation and state checks
    /// ask whether a file holds a container of a kind, not where; a `NavigationView` or a
    /// `List` that exists only inside a preview block must not answer yes.
    private static func containsOutsidePreview(_ token: String, in file: LexedFile) -> Bool {
        file.lines.contains { !file.isPreview(line: $0.number) && $0.code.contains(token) }
    }

    /// Standard navigation adapts without a sidebar opt-in. This is a source signal,
    /// not proof that a particular screen or transition renders correctly.
    private static func navigation(lexed: [LexedFile]) -> CheckResult {
        var adopted = 0
        var legacy: [String] = []
        let standardContainers = ["NavigationStack", "NavigationSplitView", "TabView",
                                  "UINavigationController", "UISplitViewController",
                                  "UITabBarController"]
        for file in lexed {
            let standard = standardContainers.contains { containsOutsidePreview($0, in: file) }
            if standard { adopted += 1 }
            else if containsOutsidePreview("NavigationView", in: file) { legacy.append(file.path) }
        }
        let total = adopted + legacy.count
        let findings = legacy.sorted().map { path in
            Finding(check: "navigation", severity: .minor,
                message: "Legacy NavigationView found. Review migration to standard navigation; a sidebar is optional and no rendering failure has been observed.",
                file: path, line: nil)
        }
        return CheckResult(key: "navigation", title: "Standard adaptive navigation",
            score: total == 0 ? nil : Double(adopted) / Double(total),
            detail: "\(adopted) standard navigation site(s), \(legacy.count) legacy site(s). Sidebar placement is optional.",
            reference: Reference.prepareDuo, findings: findings, baseWeight: 0.20,
            signals: ["adopted": Double(adopted), "containers": Double(total)])
    }

    /// Share of UI files free of fixed-geometry layout.
    ///
    /// Counting occurrences over every Swift file let a large codebase dilute real
    /// problems to nothing: Signal scored 100 with 22 offending files, WordPress 98 with
    /// 119. Offending files over UI files is a density, bounded in [0, 1], that two apps
    /// of very different sizes share when their code is equally affected.
    private static func adaptiveLayout(lexed: [LexedFile]) -> CheckResult {
        var findings: [Finding] = []
        var offending = Set<String>()
        var iconFrames = 0

        for file in lexed {
            for line in file.lines {
                guard !file.isPreview(line: line.number) else { continue }
                let code = line.code

                if Exclusions.matches(Exclusions.screenMainBounds, code) {
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .major,
                        message: "UIScreen.main.bounds is a fixed geometry read; use the view's own bounds or the window scene.",
                        file: file.path, line: line.number))
                } else if Exclusions.matches(Exclusions.screenMain, code) {
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "UIScreen.main is deprecated in iOS 27; derive scale and geometry from the window scene and trait collection.",
                        file: file.path, line: line.number))
                }

                switch Exclusions.isScorableFrame(line: code) {
                case .some(true):
                    offending.insert(file.path)
                    findings.append(Finding(check: "adaptive-layout", severity: .minor,
                        message: "Hardcoded frame larger than a control: it will not reflow when the scene changes width.",
                        file: file.path, line: line.number))
                case .some(false):
                    // Icon-sized: reported as information, never scored. 92% of the frame
                    // findings on the corpus were this.
                    iconFrames += 1
                case .none:
                    break
                }
            }
        }

        guard !lexed.isEmpty else {
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
        let density = Double(offending.count) / Double(lexed.count)
        let score = 1.0 / (1.0 + density / Exclusions.layoutDensityHalfPoint)
        return CheckResult(
            key: "adaptive-layout", title: "Adaptive layout",
            score: score,
            detail: "\(offending.count) of \(lexed.count) UI file(s) use fixed geometry"
                + (iconFrames > 0 ? " · \(iconFrames) icon-sized frame(s) not scored" : ""),
            reference: Reference.modernizeUIKit, findings: findings, baseWeight: 0.35,
            signals: ["offending": Double(offending.count), "ui_files": Double(lexed.count),
                      "icon_frames": Double(iconFrames)])
    }

    /// Share of UI files that read size classes or effective geometry.
    ///
    /// The device-branching half moved to the `idiom` and `orientation` checks; what is left
    /// is coverage of the trait environment. An app that reads no geometry has a missing
    /// signal rather than a defect, so absence is not scored zero.
    private static func adaptiveGeometry(lexed: [LexedFile]) -> CheckResult {
        var findings: [Finding] = []
        var aware = 0
        var internalStrings = 0

        for file in lexed {
            var fileIsAware = false
            for line in file.lines {
                guard !file.isPreview(line: line.number) else { continue }
                let code = line.code
                if code.contains("horizontalSizeClass") || code.contains("verticalSizeClass")
                    || code.contains("didUpdateEffectiveGeometry") {
                    fileIsAware = true
                }
                if code.contains("foldState") || code.contains("angleDegrees")
                    || code.contains("mechanicalAngleDegrees") {
                    internalStrings += 1
                    findings.append(Finding(check: "adaptive-geometry", severity: .info,
                        message: "foldState/angleDegrees are internal framework strings, not public API. Rely on size classes and effective geometry.",
                        file: file.path, line: line.number))
                }
            }
            if fileIsAware { aware += 1 }
        }

        guard !lexed.isEmpty else {
            return CheckResult(key: "adaptive-geometry", title: "Adaptive geometry",
                score: nil, detail: "no UI files found", reference: Reference.sizeClasses,
                findings: [], baseWeight: 0.15, signals: ["aware": 0, "ui_files": 0])
        }

        // Coverage anchor, calibrated on the twenty-app corpus (2026-09-06): an app is
        // credited with full coverage once one UI file in fifty reads the scene geometry.
        // Recorded in docs/result-contract.md with its corpus and date, not hidden here.
        let target = max(1.0, Double(lexed.count) * Exclusions.geometryCoverageAnchor)
        let coverage = min(1.0, Double(aware) / target)
        // An app that reads no geometry has a missing signal to report, not a mistake: three
        // corpus apps were punished for the absence before this guard.
        let score = aware == 0 ? 1.0 : coverage

        return CheckResult(
            key: "adaptive-geometry", title: "Adaptive geometry",
            score: score,
            detail: "\(aware) of \(lexed.count) UI file(s) read size classes or effective geometry"
                + (internalStrings > 0 ? " · \(internalStrings) internal fold string(s)" : ""),
            reference: Reference.sizeClasses, findings: findings, baseWeight: 0.15,
            signals: ["aware": Double(aware), "ui_files": Double(lexed.count)])
    }

    /// Share of stateful views that preserve their state.
    ///
    /// The laddered version returned 70 whenever the app had view models, which was
    /// seventeen of the twenty corpus apps.
    private static func statePreservation(lexed: [LexedFile]) -> CheckResult {
        var findings: [Finding] = []
        var stateful = 0
        var preserved = 0

        for file in lexed {
            let holdsState = ["List(", "List {", "ScrollView", "UITableView",
                              "UICollectionView", "Table("]
                .contains { containsOutsidePreview($0, in: file) }
            guard holdsState else { continue }
            stateful += 1

            let preserves = ["@SceneStorage", "restorationIdentifier",
                             "preservesSelectionInNavigationStack", "scrollPosition(",
                             "NSUserActivity"]
                .contains { containsOutsidePreview($0, in: file) }
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

    /// Share of UI files that do not branch on the device idiom.
    ///
    /// Apple directs layout decisions at the size class and the scene's effective geometry. A
    /// `UIDevice.current.userInterfaceIdiom` branch describes a device, not a canvas, and a
    /// resizable one can change shape under it. The finding is `medium` confidence because a
    /// deliberate phone-only screen is invisible to a source scan.
    private static func idiom(lexed: [LexedFile]) -> CheckResult {
        var findings: [Finding] = []
        var clean = 0

        for file in lexed {
            var branches = false
            for line in file.lines {
                guard !file.isPreview(line: line.number) else { continue }
                guard line.code.contains("userInterfaceIdiom") else { continue }
                branches = true
                findings.append(Finding(check: "idiom", severity: .minor,
                    message: "Layout branching on the device idiom; a resizable scene is described by its size class, not by whether it is a phone or a tablet.",
                    file: file.path, line: line.number, confidence: .medium))
            }
            if !branches { clean += 1 }
        }

        guard !lexed.isEmpty else {
            return CheckResult(key: "idiom", title: "Interface idiom",
                score: nil, detail: "no UI files found", reference: Reference.interfaceIdiom,
                findings: [], baseWeight: 0.10, signals: ["clean": 0, "ui_files": 0])
        }

        return CheckResult(
            key: "idiom", title: "Interface idiom",
            score: Double(clean) / Double(lexed.count),
            detail: "\(clean) of \(lexed.count) UI file(s) free of device-idiom branching",
            reference: Reference.interfaceIdiom, findings: findings, baseWeight: 0.10,
            signals: ["clean": Double(clean), "ui_files": Double(lexed.count)])
    }

    /// Interface orientation, read from the Info.plist declaration and from source branches.
    ///
    /// A plist that lists only portrait orientations locks the app to a shape, so it cannot
    /// use the full canvas when the scene is wider. A source branch on `interfaceOrientation`
    /// makes the same device-level decision the size class would settle. The check does not
    /// apply when no plist declares orientations and no source file branches on one, so its
    /// weight is spread over the checks that do.
    private static func orientation(lexed: [LexedFile], plists: [FileContent]) -> CheckResult {
        var findings: [Finding] = []
        var sites = 0
        var clean = 0
        var lockedPlists = 0

        for plist in plists {
            let declared = Exclusions.declaredOrientations(in: plist.content)
            guard !declared.isEmpty else { continue }
            sites += 1
            if Exclusions.orientationLock(in: plist.content) {
                lockedPlists += 1
                findings.append(Finding(check: "orientation", severity: .major,
                    message: "Info.plist declares only portrait orientations, locking the app to one shape so it cannot use the full canvas when the scene is wider.",
                    file: plist.path, line: nil, confidence: .high))
            } else {
                clean += 1
            }
        }

        for file in lexed {
            var branches = false
            for line in file.lines {
                guard !file.isPreview(line: line.number) else { continue }
                guard line.code.contains("interfaceOrientation") else { continue }
                branches = true
                findings.append(Finding(check: "orientation", severity: .minor,
                    message: "Layout branching on interface orientation; a resizable scene is described by its size class, not by the device's current rotation.",
                    file: file.path, line: line.number, confidence: .high))
            }
            if branches { sites += 1 }
        }

        guard sites > 0 else {
            return CheckResult(key: "orientation", title: "Interface orientation",
                score: nil,
                detail: "no supported orientations declared in Info.plist and no orientation branch in source",
                reference: Reference.interfaceOrientations, findings: [], baseWeight: 0.10,
                signals: ["sites": 0, "clean": 0, "locked_plists": 0])
        }

        return CheckResult(
            key: "orientation", title: "Interface orientation",
            score: Double(clean) / Double(sites),
            detail: "\(clean) of \(sites) orientation site(s) adapt to the scene",
            reference: Reference.interfaceOrientations, findings: findings, baseWeight: 0.10,
            signals: ["sites": Double(sites), "clean": Double(clean),
                      "locked_plists": Double(lockedPlists)])
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
                        message: String(format: "Uniform margins detected (%.0f%% of the frame). Inspect the image and linked SDK: this may be intentional spacing or system compatibility presentation, not a layout defect.",
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

    // MARK: - Build floor

    /// Apple requires Xcode 27.1 or later to use all of the available screen space on
    /// iPhone Duo. The source signal is `LastUpgradeCheck` in the project file, which
    /// records the last Xcode upgrade and can be stale: a gap is a prompt to confirm the
    /// toolchain that actually builds the app, not proof that a shipped binary fails.
    private static func buildToolchain(build: BuildSignal) -> CheckResult {
        guard let highest = build.highestUpgradeCheck else {
            return CheckResult(key: "build-toolchain", title: "Xcode 27.1 build floor",
                score: nil,
                detail: build.isEmpty ? "no Xcode project file found" : "project file records no LastUpgradeCheck value",
                reference: Reference.duoPreparation, findings: [], baseWeight: 0.10,
                signals: ["last_upgrade_check": 0, "projects": Double(build.upgradeChecks.count)])
        }

        let file = build.upgradeChecks.first { $0.value == highest }?.file
        let floor = BuildFloor.xcode27_1Generation
        var signals: [String: Double] = [
            "last_upgrade_check": Double(highest),
            "xcode_27_1_generation": Double(floor)
        ]
        if let objectVersion = build.objectVersions.max() {
            signals["object_version"] = Double(objectVersion)
        }

        if highest >= floor {
            return CheckResult(key: "build-toolchain", title: "Xcode 27.1 build floor",
                score: 1,
                detail: "LastUpgradeCheck \(highest) in \(file ?? "the project file") is at or above the Xcode 27.1 generation (\(floor)).",
                reference: Reference.duoPreparation, findings: [], baseWeight: 0.10, signals: signals)
        }

        let finding = Finding(check: "build-toolchain", severity: .minor,
            message: "Xcode 27.1 or later is required to use all of the available screen space on iPhone Duo; below it the app does not extend under the status bar and camera. LastUpgradeCheck reads \(highest), which records the last Xcode upgrade and can be stale: confirm the toolchain that actually builds the app.",
            file: file, line: nil)
        return CheckResult(key: "build-toolchain", title: "Xcode 27.1 build floor",
            score: 0,
            detail: "LastUpgradeCheck \(highest) in \(file ?? "the project file") is below the Xcode 27.1 generation (\(floor)).",
            reference: Reference.duoPreparation, findings: [finding], baseWeight: 0.10, signals: signals)
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
            case "build-toolchain": hours += gap * 2
            default: break
            }
        }
        return (hours * 2).rounded() / 2
    }
}
