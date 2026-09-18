import XCTest

/// Hand-written reference. No decoding of journeys.json and no generated checkpoints/expectations.
@MainActor
final class ExplicitTests: CaseRecorder {
    func testMatrix() {
        for variant in variants {
            for repetition in 1...repetitions {
                if selected.contains("form") {
                    form(variant, repetition, "control", false, true)
                    form(variant, repetition, "name-entered", true, false)
                    form(variant, repetition, "details-entered", true, true)
                }
                if selected.contains("cart") {
                    cart(variant, repetition, "control", false, true)
                    cart(variant, repetition, "item-added", true, false)
                    cart(variant, repetition, "order-placed", true, true)
                }
                if selected.contains("draft") {
                    draft(variant, repetition, "control", false, true)
                    draft(variant, repetition, "body-entered", true, false)
                    draft(variant, repetition, "draft-saved", true, true)
                }
            }
        }
    }

    private func form(_ variant: String, _ repetition: Int, _ checkpoint: String, _ rotate: Bool, _ complete: Bool) {
        record(approach: "explicit", journey: "form", variant: variant, checkpoint: checkpoint,
               steps: complete ? ["step1", "step2"] : ["step1"],
               expected: ["name": "Ada", "details": complete ? "12 Test Street" : ""],
               repetition: repetition, rotate: rotate, remainingSteps: complete ? [] : ["step2"],
               finalExpected: ["name": "Ada", "details": "12 Test Street"])
    }
    private func cart(_ variant: String, _ repetition: Int, _ checkpoint: String, _ rotate: Bool, _ complete: Bool) {
        record(approach: "explicit", journey: "cart", variant: variant, checkpoint: checkpoint,
               steps: complete ? ["step1", "step2"] : ["step1"],
               expected: ["quantity": "1", "orders": complete ? "1" : "0"],
               repetition: repetition, rotate: rotate, remainingSteps: complete ? [] : ["step2"],
               finalExpected: ["quantity": "1", "orders": "1"])
    }
    private func draft(_ variant: String, _ repetition: Int, _ checkpoint: String, _ rotate: Bool, _ complete: Bool) {
        record(approach: "explicit", journey: "draft", variant: variant, checkpoint: checkpoint,
               steps: complete ? ["step1", "step2"] : ["step1"],
               expected: ["body": "Delivery notes", "saves": complete ? "1" : "0"],
               repetition: repetition, rotate: rotate, remainingSteps: complete ? [] : ["step2"],
               finalExpected: ["body": "Delivery notes", "saves": "1"])
    }
}
