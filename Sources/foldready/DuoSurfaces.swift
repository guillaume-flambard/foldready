import Foundation

/// A Duo surface the source appears to build by hand, reported as a question rather than a
/// defect.
///
/// Advisory findings never enter the readiness score, any check score, or the gate verdict.
/// A `GeometryReader` that never asks for reserved regions may be entirely correct, and a
/// zero-weight entry inside `checks` would make the score arithmetic read as if these
/// surfaces mattered to it.
struct AdvisoryFinding: Sendable {
    let surface: String
    let message: String
    let file: String
    let line: Int
    let reference: String
    let runtimeCheck: String
    /// How many matching occurrences the file held; only the first line is reported.
    let collapsed: Int
}

/// The four surfaces Apple names for custom layouts on iPhone Duo.
///
/// Apple: custom views "don't automatically adjust to reserved regions", bars are stacked
/// vertically on the side in some poses, an arrangement view follows the fold, and the
/// active display and camera direction can change when the phone is opened, closed or
/// rotated. Each detector is deliberately conservative: it fires on a structural token and
/// states the runtime check that would settle it.
enum DuoSurfaces {
    static let reservedRegions = "Reserved regions"
    static let arrangementViews = "Arrangement views"
    static let verticalBars = "Vertical bars"
    static let cameraDirection = "Camera direction"

    /// Report order, so the payload and the checklist read the same way on every run.
    static let order = [reservedRegions, arrangementViews, verticalBars, cameraDirection]

    static func reference(for surface: String) -> String {
        switch surface {
        case reservedRegions: return Reference.reservedRegions
        case arrangementViews: return Reference.arrangementViews
        case verticalBars: return Reference.verticalBars
        default: return Reference.cameraDirection
        }
    }

    /// The runtime check that would confirm or dismiss a source signal for a surface. The
    /// same wording is used in the report checklist and in `docs/readiness-review.md`.
    static func runtimeCheck(for surface: String) -> String {
        switch surface {
        case reservedRegions:
            return "On inner and outer displays, confirm the fold and camera reserved regions do not cover custom content."
        case arrangementViews:
            return "Confirm the panes arrange as intended when partially folded and when the container changes width."
        case verticalBars:
            return "Confirm every bar action is present vertically; an item drawn from a title with no icon is not shown there."
        default:
            return "Confirm which camera is active and which display the app is on after opening, closing and rotating."
        }
    }

    static func analyze(uiFiles: [FileContent]) -> [AdvisoryFinding] {
        var findings: [AdvisoryFinding] = []
        for file in uiFiles {
            if !uses(file, ["reservedRegions", "ReservedRegion"]),
               let hits = hits(in: file, matching: isReservedRegionSignal) {
                findings.append(make(
                    surface: reservedRegions,
                    message: "Custom geometry without a reserved-region query. The fold divides a large view and the cameras can occlude it; Apple's reserved-region APIs report both.",
                    file: file, hits: hits))
            }
            if !uses(file, ["ArrangementView", "UIArrangementViewController", "arrangementViewStyle", "updateArrangement"]),
               uses(file, ["HStack", ".overlay("]),
               uses(file, ["GeometryReader", "containerRelativeFrame"]),
               let hits = hits(in: file, matching: isArrangementSignal) {
                findings.append(make(
                    surface: arrangementViews,
                    message: "Several panes are placed against measured geometry. An arrangement view splits side by side or overlays, and follows the fold by itself.",
                    file: file, hits: hits))
            }
            if let hits = hits(in: file, matching: isBarSignal) {
                findings.append(make(
                    surface: verticalBars,
                    message: "A bar is built directly, or a bar item is declared with a title and no icon. Duo stacks bars vertically on the side, where a title-only or custom-view item is not presented.",
                    file: file, hits: hits))
            }
            if !uses(file, ["cameraPosition", "systemPreferredCamera", "builtInWideAngleCamera", "AVCaptureDevice.Position", "default(for:"]),
               let hits = hits(in: file, matching: isCameraSignal) {
                findings.append(make(
                    surface: cameraDirection,
                    message: "Camera capture without a facing or display decision. Opening, closing or rotating can change which display the app is on, and the camera can point the opposite way.",
                    file: file, hits: hits))
            }
        }
        return findings.sorted {
            let left = order.firstIndex(of: $0.surface) ?? order.count
            let right = order.firstIndex(of: $1.surface) ?? order.count
            if left != right { return left < right }
            if $0.file != $1.file { return $0.file < $1.file }
            return $0.line < $1.line
        }
    }

    /// Surfaces that produced a finding, once each, in report order.
    static func surfaces(in findings: [AdvisoryFinding]) -> [String] {
        order.filter { surface in findings.contains { $0.surface == surface } }
    }

    /// The runtime checks for the surfaces that produced a finding, once each.
    static func runtimeChecks(for findings: [AdvisoryFinding]) -> [String] {
        surfaces(in: findings).map(runtimeCheck(for:))
    }

    // MARK: - Signals

    /// A bound container read without ever asking which region is reserved by the fold or
    /// the cameras.
    private static func isReservedRegionSignal(_ line: String) -> Bool {
        line.contains("GeometryReader")
            || line.contains("containerRelativeFrame")
            || line.contains(".frame(in:")
            || line.contains("safeAreaInset")
    }

    private static func isArrangementSignal(_ line: String) -> Bool {
        line.contains("HStack") || line.contains(".overlay(")
    }

    /// A bar built directly instead of through the system, or an item that cannot be
    /// presented vertically because it carries a title with no icon or a custom view.
    private static func isBarSignal(_ line: String) -> Bool {
        if line.contains("UIToolbar(") || line.contains("UINavigationBar(") || line.contains("UITabBar(") {
            return true
        }
        if line.contains("UIBarButtonItem(title:") && !line.contains("image:") {
            return true
        }
        if line.contains("ToolbarItem") && line.contains("Text(")
            && !line.contains("Image(") && !line.contains("Label(") {
            return true
        }
        return false
    }

    private static func isCameraSignal(_ line: String) -> Bool {
        line.contains("AVCaptureDevice") || line.contains("AVCaptureSession")
    }

    // MARK: - Helpers

    private static func uses(_ file: FileContent, _ tokens: [String]) -> Bool {
        tokens.contains { file.content.contains($0) }
    }

    /// The 1-based line of the first matching non-preview line and the number of matches
    /// in the file. Preview code is skipped for the same reason the scored checks skip it.
    private static func hits(in file: FileContent, matching predicate: (String) -> Bool) -> (line: Int, count: Int)? {
        let skipped = Exclusions.previewLines(in: file.content)
        var first = 0
        var count = 0
        for (index, raw) in file.content.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            if skipped.contains(index) { continue }
            if predicate(String(raw)) {
                count += 1
                if first == 0 { first = index + 1 }
            }
        }
        guard count > 0 else { return nil }
        return (first, count)
    }

    private static func make(surface: String, message: String, file: FileContent, hits: (line: Int, count: Int)) -> AdvisoryFinding {
        AdvisoryFinding(
            surface: surface,
            message: message,
            file: file.path,
            line: hits.line,
            reference: reference(for: surface),
            runtimeCheck: runtimeCheck(for: surface),
            collapsed: hits.count)
    }
}
