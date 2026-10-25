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

    /// A real simulator rotation with observable state, NOT a hinge/fold transition.
    /// The fixed fixture must retain entered form values after a size change.
    func testDuoRotationPreservesFormState() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launchEnvironment = ["FR_JOURNEY": "form", "FR_VARIANT": "fixed"]
        app.launch()
        defer {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
        }

        let firstStep = app.buttons["step1"]
        guard firstStep.waitForExistence(timeout: 25), firstStep.isHittable else {
            XCTFail("The fixture must be actionable before rotation")
            return
        }
        firstStep.tap()
        let nameValue = app.staticTexts["name"]
        let geometry = app.staticTexts["geometry"]
        guard nameValue.waitForExistence(timeout: 10), geometry.exists else {
            XCTFail("Fixture values and window geometry must be accessible")
            return
        }
        XCTAssertEqual(nameValue.value as? String, "Ada", "Pre-rotation form state")
        let originalGeometry = geometry.label

        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "landscape"),
            object: geometry
        )
        guard XCTWaiter.wait(for: [landscape], timeout: 20) == .completed else {
            XCTFail("Requested rotation did not produce a landscape window")
            return
        }
        XCTAssertNotEqual(geometry.label, originalGeometry, "Window must actually resize")
        XCTAssertEqual(nameValue.value as? String, "Ada", "Form state must survive rotation")
        XCTAssertTrue(firstStep.isHittable, "Primary form action must remain available")

        XCTContext.runActivity(named: "iPhone Duo synthetic rotation - form state preserved") { activity in
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "duo-landscape-form-with-preserved-state"
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
