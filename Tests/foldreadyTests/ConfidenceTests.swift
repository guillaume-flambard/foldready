import Testing
import Foundation
@testable import foldready

@Suite("Confidence")
struct ConfidenceTests {

    @Test func orderIsHighThenMediumThenLow() {
        #expect(Confidence.high > Confidence.medium)
        #expect(Confidence.medium > Confidence.low)
    }

    @Test func aFindingCarriesConfidenceAndDefaultsToHigh() {
        let finding = Finding(check: "adaptive-layout", severity: .major,
                              message: "m", file: "A.swift", line: 1)
        #expect(finding.confidence == .high)
    }

    @Test func gateFiltersBelowTheConfiguredConfidence() throws {
        let policy = try JSONDecoder().decode(GatePolicy.self,
            from: Data(#"{"minConfidence":"high"}"#.utf8))
        #expect(policy.minConfidence == "high")
    }
}
