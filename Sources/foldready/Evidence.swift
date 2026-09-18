import Foundation

/// Honest boundaries shared by machine and human reports. No static run certifies Duo.
enum Evidence {
    static let summary = "Source signals and optional screenshot heuristics only. iPhone Duo runtime compatibility is unverified; SDK and build configuration are not resolved. Existing apps can run without recompilation."
    static let runtimeChecks = [
        "Record Xcode, linked SDK, simulator or device, build and tested app version.",
        "Test agreed critical journeys on outer and inner displays, including open/close transitions.",
        "Test partial folding, rotation and Split View; check asymmetric safe areas and controls near cameras and hinge.",
        "Verify selection, scroll position, input and navigation state survive resizing.",
        "Separate reproduced defects from optional sidebar or arrangement improvements."
    ]
    /// The standing checks plus the ones the advisory Duo surface signals add. The surface
    /// checks use the same wording as `docs/readiness-review.md`.
    static func runtimeChecksRequired(surfaceChecks: [String]) -> [String] {
        runtimeChecks + surfaceChecks
    }

    static func payload(surfaceChecks: [String] = []) -> [String: Any] {
        ["summary": summary, "duo_runtime_verified": false,
         "sdk_status": "unresolved",
         "runtime_checks_required": runtimeChecksRequired(surfaceChecks: surfaceChecks),
         "references": [Reference.prepareDuo, Reference.adaptiveDuo]]
    }
}
