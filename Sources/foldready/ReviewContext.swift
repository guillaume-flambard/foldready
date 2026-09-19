import Foundation

/// Review guidance only. Never participates in scoring or gate evaluation.
enum ReviewContext {
    static let scoreNote = "Versioned heuristic summary, not a readiness threshold. Compare only the same contract, engine and coverage."
    static let effortNote = "Unvalidated heuristic hours; not measured delivery time, a quote or a commitment."
    static let orderNote = "Tool-proposed review order follows severity, then check and location. Human priority is not assessed; confirm relevance and journey impact first."
    static let coverageNote = "Swift UI source, plist declarations and project metadata only; no target membership, declaration scope, generated build settings, Objective-C implementation or linked SDK resolution. Exclusions and unreadable files limit coverage. Screenshots cannot establish behavior or cause."

    static func nextStep(for check: String) -> String {
        switch check {
        case "adaptive-layout", "adaptive-geometry":
            return "Inspect the located layout in its target and resize the affected journey. Record clipping, intentional fixed sizes and expected behavior before proposing a change."
        case "navigation":
            return "Exercise navigation in narrow and wide scenes. Confirm whether migration is needed; a sidebar is optional."
        case "state":
            return "Set selection, scroll and input state, then resize and revisit the journey. Record any loss before proposing restoration changes."
        case "idiom", "orientation":
            return "Confirm the declaration belongs to the reviewed target and inspect branch intent. Test the affected journey across scene sizes and rotation."
        case "build-toolchain":
            return "Record the actual build toolchain and linked SDK. Project upgrade metadata alone does not identify the shipped build."
        case "captured-layout":
            return "Record image provenance and reproduce the visible margins on a named build. Check intentional spacing and system presentation before attributing a cause."
        default:
            return "Inspect source and target configuration, then reproduce the suspected consequence on a named build and agreed journey."
        }
    }

    static func finding(_ finding: Finding, in result: AuditResult) -> [String: Any] {
        let outcome = result.outcomes.first { $0.key == finding.check }
        var context: [String: Any] = [
            "status": "hypothesis_to_review",
            "human_priority": NSNull(),
            "runtime_status": "not_tested",
            "rationale": "The detector reported this signal; confidence describes the match, not a reproduced defect. Confirm target membership and context.",
            "next_step": nextStep(for: finding.check)
        ]
        if let outcome {
            // Reuse evidence already collected by the check; do not invent source excerpts.
            context["check_evidence"] = outcome.detail
            context["reference"] = outcome.reference
        }
        return context
    }

    static func payload(_ result: AuditResult) -> [String: Any] {
        [
            "status": "awaiting_human_review",
            "score_note": scoreNote,
            "effort_status": "unvalidated_estimate",
            "effort_note": effortNote,
            "order_note": orderNote,
            "coverage_note": coverageNote,
            "runtime_checks": Evidence.runtimeChecksRequired(surfaceChecks: result.advisoryRuntimeChecks).map {
                ["check": $0, "status": "not_tested"]
            }
        ]
    }
}
