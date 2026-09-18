import XCTest

@MainActor
final class GeneratedTests: CaseRecorder {
    func testMatrix() throws {
        let data = Data(settings["FR_SPEC"]!.utf8)
        let specification = try JSONDecoder().decode(JourneyFile.self, from: data)
        for journey in specification.journeys where selected.contains(journey.id) {
            for variant in variants {
                for repetition in 1...repetitions {
                    let final = journey.checkpoints.last!
                    record(approach: "generated", journey: journey.id, variant: variant,
                           checkpoint: "control", steps: final.steps, expected: final.expected,
                           repetition: repetition, rotate: false, finalExpected: final.expected)
                    for point in journey.checkpoints {
                        record(approach: "generated", journey: journey.id, variant: variant,
                               checkpoint: point.id, steps: point.steps, expected: point.expected,
                               repetition: repetition, rotate: true,
                               remainingSteps: Array(final.steps.dropFirst(point.steps.count)), finalExpected: final.expected)
                    }
                }
            }
        }
    }
}
