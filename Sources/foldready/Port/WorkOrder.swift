import Foundation

/// How FoldReady re-checks a work-order entry after someone (or an agent) has executed it.
///
/// Acceptance is expressed against the audit, never against a FoldReady transform, so an
/// entry stays meaningful whatever tool did the work.
enum Acceptance: Sendable, Equatable {
    /// No finding of `check` remains in `file` (or anywhere, when `file` is nil).
    case findingResolved(check: String, file: String?)
    /// The check scores at least `score` out of 100.
    case checkAtLeast(key: String, score: Double)

    var described: String {
        switch self {
        case .findingResolved(let check, let file):
            return "no '\(check)' finding remains in \(file ?? "the project")"
        case .checkAtLeast(let key, let score):
            return "check '\(key)' scores at least \(Int(score))/100"
        }
    }

    func isMet(by result: AuditResult) -> Bool {
        switch self {
        case .findingResolved(let check, let file):
            return !result.findings.contains { $0.check == check && (file == nil || $0.file == file) }
        case .checkAtLeast(let key, let score):
            guard let outcome = result.outcomes.first(where: { $0.key == key }) else { return false }
            return (outcome.score * 100).rounded() >= score
        }
    }

    var encoded: [String: Any] {
        switch self {
        case .findingResolved(let check, let file):
            var d: [String: Any] = ["type": "finding_resolved", "check": check]
            if let file { d["file"] = file }
            return d
        case .checkAtLeast(let key, let score):
            return ["type": "check_at_least", "check": key, "score": score]
        }
    }

    static func decode(_ d: [String: Any]) -> Acceptance? {
        switch d["type"] as? String {
        case "finding_resolved":
            guard let check = d["check"] as? String else { return nil }
            return .findingResolved(check: check, file: d["file"] as? String)
        case "check_at_least":
            guard let key = d["check"] as? String else { return nil }
            let score = (d["score"] as? Double) ?? (d["score"] as? Int).map(Double.init) ?? 100
            return .checkAtLeast(key: key, score: score)
        default:
            return nil
        }
    }
}

/// One unit of non-mechanical work: what must be true when it is done, where, why (the
/// Apple requirement), and how FoldReady will verify it.
struct WorkOrderEntry: Sendable {
    let id: String
    let title: String
    /// Key of the audit check this entry belongs to.
    let checkKey: String
    let file: String?
    let line: Int?
    let requiredEndState: String
    let reference: String
    let acceptance: Acceptance
    /// Whether the acceptance condition already held when the work order was written.
    let metWhenWritten: Bool

    var location: String {
        guard let file else { return "project-wide" }
        return line.map { "\(file):\($0)" } ?? file
    }
}

/// The handoff artefact: everything an agent needs to do the work, and everything
/// `verify` needs to say afterwards whether it was done.
struct WorkOrder: Sendable {
    let app: String
    let generatedAt: Date
    let score: Double
    let entries: [WorkOrderEntry]

    /// Per-entry outcome of a re-audit.
    enum Status: String, Sendable {
        case fixed
        case unchanged
        case regressed
    }

    func status(of entry: WorkOrderEntry, after result: AuditResult) -> Status {
        let met = entry.acceptance.isMet(by: result)
        if met && !entry.metWhenWritten { return .fixed }
        if !met && entry.metWhenWritten { return .regressed }
        return met ? .fixed : .unchanged
    }
}

enum WorkOrderBuilder {

    /// Builds the work order from an audit result.
    ///
    /// Entries come from the audit, not from FoldReady's transforms: an entry cites the
    /// platform requirement, so it remains executable by Apple's app modernization skill
    /// or any other coding agent that has never seen this tool.
    static func build(from result: AuditResult) -> WorkOrder {
        var entries: [WorkOrderEntry] = []

        func reference(_ key: String) -> String {
            result.outcomes.first { $0.key == key }?.reference ?? Reference.modernizeUIKit
        }
        func score(_ key: String) -> Double {
            guard let o = result.outcomes.first(where: { $0.key == key }) else { return 0 }
            return (o.score * 100).rounded()
        }

        // Scene lifecycle: the one that stops the app launching at all.
        if score("scene") < 80 {
            let acceptance = Acceptance.checkAtLeast(key: "scene", score: 80)
            entries.append(WorkOrderEntry(
                id: "scene-lifecycle",
                title: "Adopt the UIScene lifecycle",
                checkKey: "scene",
                file: nil, line: nil,
                requiredEndState: """
                    The app declares a scene manifest and a scene delegate (or a SwiftUI \
                    App scene), and creates its window from the window scene rather than \
                    in the application delegate. An app built against the iOS 27 SDK \
                    without the scene lifecycle does not launch.
                    """,
                reference: reference("scene"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        // Fixed geometry reads, one entry per file.
        for file in files(in: result, check: "adaptive-layout", matching: "UIScreen.main") {
            let acceptance = Acceptance.findingResolved(check: "adaptive-layout", file: file.path)
            entries.append(WorkOrderEntry(
                id: "screen-geometry",
                title: "Replace fixed screen geometry reads",
                checkKey: "adaptive-layout",
                file: file.path, line: file.line,
                requiredEndState: """
                    Geometry comes from the view's own bounds, the window scene, or the \
                    trait collection, not from the main screen. The value must follow the \
                    scene as it is resized, not the device.
                    """,
                reference: reference("adaptive-layout"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        // Hardcoded frames, one entry per file.
        for file in files(in: result, check: "adaptive-layout", matching: "Hardcoded frame") {
            let acceptance = Acceptance.findingResolved(check: "adaptive-layout", file: file.path)
            entries.append(WorkOrderEntry(
                id: "dehardcode-frames",
                title: "Remove hardcoded frame sizes",
                checkKey: "adaptive-layout",
                file: file.path, line: file.line,
                requiredEndState: """
                    Layout is expressed in constraints, stacks or relative sizes, so the \
                    view reflows when the scene changes width. Fixed width and height \
                    literals only remain where the content genuinely has a fixed size.
                    """,
                reference: reference("adaptive-layout"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        // Navigation that will not gain a sidebar.
        for file in files(in: result, check: "navigation", matching: "") {
            let acceptance = Acceptance.findingResolved(check: "navigation", file: file.path)
            entries.append(WorkOrderEntry(
                id: "adaptive-navigation",
                title: "Adopt a navigation container that can become a sidebar",
                checkKey: "navigation",
                file: file.path, line: file.line,
                requiredEndState: """
                    The root navigation is a NavigationSplitView (SwiftUI) or opts into \
                    the tab bar sidebar placement (UIKit), so the system can show a \
                    sidebar when the scene is wide enough. Only the root container \
                    changes; nested navigation stays as it is.
                    """,
                reference: reference("navigation"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        if score("fold-state") < 70 {
            let acceptance = Acceptance.checkAtLeast(key: "fold-state", score: 70)
            entries.append(WorkOrderEntry(
                id: "adaptive-geometry",
                title: "Branch layout on size classes, not on device or orientation",
                checkKey: "fold-state",
                file: nil, line: nil,
                requiredEndState: """
                    Layout decisions read the horizontal size class or the scene's \
                    effective geometry. Device idiom and interface orientation do not \
                    describe a resizable scene and must not drive layout.
                    """,
                reference: reference("fold-state"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        if score("state") < 70 {
            let acceptance = Acceptance.checkAtLeast(key: "state", score: 70)
            entries.append(WorkOrderEntry(
                id: "state-preservation",
                title: "Preserve selection and scroll state across a scene resize",
                checkKey: "state",
                file: nil, line: nil,
                requiredEndState: """
                    Selection, scroll position and in-progress input survive the view \
                    hierarchy being rebuilt, via @SceneStorage, state restoration, or a \
                    model that outlives the view.
                    """,
                reference: reference("state"),
                acceptance: acceptance,
                metWhenWritten: acceptance.isMet(by: result)))
        }

        return WorkOrder(app: result.appName, generatedAt: result.generatedAt,
            score: result.totalScore, entries: entries)
    }

    private struct Site { let path: String; let line: Int? }

    /// One site per file, the first occurrence, so a work order stays readable on a large
    /// app instead of listing the same task hundreds of times.
    private static func files(in result: AuditResult, check: String, matching fragment: String) -> [Site] {
        var seen = Set<String>()
        var sites: [Site] = []
        for finding in result.findings
        where finding.check == check && (fragment.isEmpty || finding.message.contains(fragment)) {
            guard let path = finding.file, !seen.contains(path) else { continue }
            seen.insert(path)
            sites.append(Site(path: path, line: finding.line))
        }
        return sites
    }
}

extension WorkOrder {

    /// The agent-facing document. One file, handed to a coding agent as its task input.
    func markdown() -> String {
        var out = """
        # FoldReady work order — \(app)

        Score at the time of writing: \(Int(score))/100.

        These are the changes FoldReady will not make for you: each one needs judgement \
        about the app's structure, which the tool that has the build graph and the type \
        checker should exercise, not a pattern matcher. Apple ships one such tool with \
        Xcode 27 — the app modernization agent skill, exportable with \
        `xcrun agent skills export` — and this document is written so that skill, or any \
        other coding agent, can execute it.

        FoldReady measures and verifies. After the work, re-run:

        ```sh
        foldready verify <path> --work-order <this file's directory>/work-order.json
        ```

        Each entry states the required end state, the Apple source the requirement comes \
        from, and the condition FoldReady re-evaluates.

        """

        if entries.isEmpty {
            out += "\nNothing to hand over: no judgement-level work outstanding.\n"
            return out
        }

        for (index, entry) in entries.enumerated() {
            out += """

            ## \(index + 1). \(entry.title)

            - **Where**: `\(entry.location)`
            - **Audit check**: `\(entry.checkKey)`
            - **Apple source**: \(entry.reference)
            - **Required end state**: \(entry.requiredEndState)
            - **Done when**: \(entry.acceptance.described)

            """
        }
        return out
    }

    /// Machine form, so `verify` can report per-entry status rather than only a new total.
    func json() -> String {
        let payload: [String: Any] = [
            "schema_version": resultSchemaVersion,
            "foldready_version": foldreadyVersion,
            "app": app,
            "generated_at": ISO8601DateFormatter().string(from: generatedAt),
            "score": score,
            "entries": entries.map { entry -> [String: Any] in
                var d: [String: Any] = [
                    "id": entry.id,
                    "title": entry.title,
                    "check": entry.checkKey,
                    "required_end_state": entry.requiredEndState,
                    "reference": entry.reference,
                    "acceptance": entry.acceptance.encoded,
                    "met_when_written": entry.metWhenWritten
                ]
                if let file = entry.file { d["file"] = file }
                if let line = entry.line { d["line"] = line }
                return d
            }
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    static func load(path: String) -> WorkOrder? {
        guard let data = FileManager.default.contents(atPath: path),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let rawEntries = obj["entries"] as? [[String: Any]] else { return nil }
        let entries: [WorkOrderEntry] = rawEntries.compactMap { d in
            guard let id = d["id"] as? String,
                  let title = d["title"] as? String,
                  let check = d["check"] as? String,
                  let acceptanceDict = d["acceptance"] as? [String: Any],
                  let acceptance = Acceptance.decode(acceptanceDict) else { return nil }
            return WorkOrderEntry(
                id: id, title: title, checkKey: check,
                file: d["file"] as? String, line: d["line"] as? Int,
                requiredEndState: (d["required_end_state"] as? String) ?? "",
                reference: (d["reference"] as? String) ?? Reference.modernizeUIKit,
                acceptance: acceptance,
                metWhenWritten: (d["met_when_written"] as? Bool) ?? false)
        }
        let score = (obj["score"] as? Double) ?? (obj["score"] as? Int).map(Double.init) ?? 0
        return WorkOrder(app: (obj["app"] as? String) ?? "app", generatedAt: Date(),
            score: score, entries: entries)
    }
}
