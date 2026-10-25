import XCTest

/// Hand-written reference. No decoding of journeys.json and no generated checkpoints/expectations.
@MainActor
final class ExplicitTests: CaseRecorder {
    /// Real foreground validation on the selected simulator. No fold gesture is simulated.
    /// A successful simctl launch alone is insufficient: a home screen screenshot
    /// can still be produced after the app has disappeared.
    func testDuoForegroundJourney() {
        let app = XCUIApplication()
        app.launchEnvironment = ["FR_JOURNEY": "form", "FR_VARIANT": "fixed"]
        app.launch()
        defer { app.terminate() }

        let title = app.staticTexts["Continuity demo: form / fixed"]
        XCTAssertTrue(title.waitForExistence(timeout: 25), "Synthetic fixture heading must exist")
        XCTAssertTrue(title.isHittable, "Synthetic fixture must be visible, not only installed")

        let firstStep = app.buttons["step1"]
        XCTAssertTrue(firstStep.waitForExistence(timeout: 10), "First journey action must exist")
        XCTAssertTrue(firstStep.isHittable, "First journey action must be tappable")
        firstStep.tap()
        let nameValue = app.staticTexts["name"]
        XCTAssertTrue(nameValue.waitForExistence(timeout: 10), "Fixture state must be exposed")
        XCTAssertEqual(nameValue.value as? String, "Ada", "One critical fixture state must update")

        let geometry = app.staticTexts["geometry"]
        XCTAssertTrue(geometry.exists, "Window geometry must be reported")
        XCTContext.runActivity(named: "Synthetic form journey - visible UI evidence") { activity in
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "duo-foreground-form-step1"
            screenshot.lifetime = .keepAlways
            activity.add(screenshot)
        }
    }

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
