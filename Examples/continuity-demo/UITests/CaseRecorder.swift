import XCTest

struct Checkpoint: Decodable {
    let id: String
    let steps: [String]
    let expected: [String: String]
}
struct Journey: Decodable { let id: String; let checkpoints: [Checkpoint] }
struct JourneyFile: Decodable { let journeys: [Journey] }

@MainActor
class CaseRecorder: XCTestCase {
    let settings = ProcessInfo.processInfo.environment
    private var activeApp: XCUIApplication?
    private var activeFixture = ""

    override func tearDown() {
        activeApp?.terminate()
        activeApp = nil
        super.tearDown()
    }

    var variants: [String] { settings["FR_VARIANTS"]!.components(separatedBy: ",") }
    var repetitions: Int { Int(settings["FR_REPETITIONS"]!)! }
    var selected: [String] { settings["FR_JOURNEYS"]!.components(separatedBy: ",") }

    /// Shared only for device interaction/evidence; explicit suite does not read generated expectations.
    func record(approach: String, journey: String, variant: String, checkpoint: String,
                steps: [String], expected: [String: String], repetition: Int, rotate: Bool,
                remainingSteps: [String] = [], finalExpected: [String: String]) {
        let id = "\(approach)/\(journey)/\(variant)/\(checkpoint)/\(repetition)"
        let start = Date()
        var status = "execution_error"
        var reason = ""
        var before: [String: String] = [:]
        var observed: [String: String] = [:]
        var finalObserved: [String: String] = [:]
        var actualTransitions: [String] = []
        var geometryBefore = ""
        var geometryAfter = ""
        let fixture = "\(journey)/\(variant)"
        let app: XCUIApplication
        if activeFixture == fixture, let running = activeApp, running.state == .runningForeground {
            app = running
            // Reset before rotating back so no previous case can trigger an injected defect.
            app.buttons["reset"].tap()
            XCUIDevice.shared.orientation = .portrait
        } else {
            activeApp?.terminate()
            app = XCUIApplication()
            XCUIDevice.shared.orientation = .portrait
            app.launchEnvironment = ["FR_JOURNEY": journey, "FR_VARIANT": variant]
            app.launch()
            activeApp = app
            activeFixture = fixture
        }

        func values() -> [String: String]? {
            var result: [String: String] = [:]
            for key in expected.keys.sorted() {
                let element = app.staticTexts[key]
                guard element.exists, let value = element.value as? String else { return nil }
                result[key] = value
            }
            return result
        }
        func waitForGeometry(_ value: String) -> Bool {
            let predicate = NSPredicate(format: "value == %@", value)
            return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate,
                                           object: app.staticTexts["geometry"])], timeout: 8) == .completed
        }

        if !app.buttons["step1"].waitForExistence(timeout: 10) || !waitForGeometry("portrait") {
            reason = "App did not become ready in portrait"
        } else {
            var prepared = true
            for step in steps {
                guard app.buttons[step].exists && app.buttons[step].isHittable else {
                    prepared = false; reason = "Missing or untappable action: \(step)"; break
                }
                app.buttons[step].tap()
            }
            if prepared, let captured = values() {
                before = captured
                geometryBefore = app.staticTexts["geometry"].label
                if captured != expected {
                    reason = "Precondition failed before transition"
                } else {
                    if rotate {
                        XCUIDevice.shared.orientation = .landscapeLeft
                        if waitForGeometry("landscape") {
                            actualTransitions = ["rotate-portrait-to-landscape"]
                        } else { reason = "Requested rotation did not change window geometry" }
                    }
                    geometryAfter = app.staticTexts["geometry"].label
                    if reason.isEmpty, let after = values() {
                        observed = after
                        status = after == expected ? "passed" : "functional_failure"
                        if status == "functional_failure" { reason = "Declared invariant changed" }
                        // Finish the same journey, even after an invariant failure, to detect effects
                        // such as a submission duplicated only on completion.
                        for action in remainingSteps {
                            guard app.buttons[action].exists && app.buttons[action].isHittable else {
                                status = "execution_error"; reason = "Cannot complete action: \(action)"; break
                            }
                            app.buttons[action].tap()
                        }
                        if status != "execution_error", let completed = values() {
                            finalObserved = completed
                            if completed != finalExpected {
                                status = "functional_failure"
                                reason = "Declared invariant changed during transition or completion"
                            }
                        } else if status != "execution_error" {
                            status = "execution_error"; reason = "Cannot read final invariant UI"
                        }
                    } else if reason.isEmpty { reason = "Invariant UI disappeared" }
                }
            } else if reason.isEmpty { reason = "Cannot read declared invariant UI" }
        }
        var reproduction = ["Launch \(journey) with \(variant) fixture"]
        reproduction.append(contentsOf: steps)
        if rotate { reproduction.append("Rotate portrait to landscape") }
        reproduction.append("Check checkpoint values")
        reproduction.append(contentsOf: remainingSteps)
        reproduction.append("Check completion values")
        let record: [String: Any] = [
            "record_type": "foldready-continuity-case", "id": id,
            "approach": approach, "journey": journey, "variant": variant,
            "checkpoint": checkpoint, "repetition": repetition, "status": status,
            "expected": expected, "before": before, "observed": observed, "reason": reason,
            "final_expected": finalExpected, "final_observed": finalObserved,
            "requested_transition": rotate ? "rotate" : "none",
            "actual_transitions": actualTransitions,
            "geometry_before": geometryBefore, "geometry_after": geometryAfter,
            "duration_seconds": Date().timeIntervalSince(start),
            "reproduction": reproduction
        ]
        XCTContext.runActivity(named: id) { activity in
            let data = try! JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = "foldready-case-" + id.replacingOccurrences(of: "/", with: "_")
            attachment.lifetime = .keepAlways
            activity.add(attachment)
            if status != "passed" {
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "evidence-" + id.replacingOccurrences(of: "/", with: "_")
                screenshot.lifetime = .keepAlways
                activity.add(screenshot)
            }
        }
        // Expected fixture defects are data; XCTest failures indicate a broken measurement harness.
        XCTAssertNotEqual(status, "execution_error", "\(id): \(reason)")
    }
}
