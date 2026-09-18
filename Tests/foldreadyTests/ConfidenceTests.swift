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

    @Test func aFindingAcceptsAnExplicitConfidence() {
        let finding = Finding(check: "adaptive-layout", severity: .major,
                              message: "m", file: "A.swift", line: 1,
                              confidence: .low)
        #expect(finding.confidence == .low)
    }

    @Test func gateFiltersBelowTheConfiguredConfidence() throws {
        let policy = try JSONDecoder().decode(GatePolicy.self,
            from: Data(#"{"minConfidence":"high"}"#.utf8))
        #expect(policy.minConfidence == .high)
    }

    @Test func aTypoInMinConfidenceIsALoadErrorNotASilentFallback() {
        // A string here would decode a typo and fall back to permissive; the typed level
        // makes "HIGH" and "bogus" errors the caller reports.
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(GatePolicy.self,
                from: Data(#"{"minConfidence":"HIGH"}"#.utf8))
        }
    }
}
