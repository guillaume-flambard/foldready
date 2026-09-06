import Foundation

/// The machine-readable audit result: FoldReady's public contract, documented in
/// `docs/result-contract.md`. CI gates, the ranking site and third-party consumers read
/// this, so the rules in `openspec/specs/audit/result-contract` apply to every change
/// here: stable check keys, repository-relative finding paths, no absolute host paths,
/// and a `schema_version` bump on any removal, rename or change of meaning.
enum JSONReport {

    static func render(_ result: AuditResult) -> String {
        let data = try! JSONSerialization.data(
            withJSONObject: payload(result),
            options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// The payload without the generation timestamp: everything a consumer compares
    /// between two runs. Two audits of the same tree with the same version must produce
    /// an identical value here.
    static func comparablePayload(_ result: AuditResult) -> [String: Any] {
        var p = payload(result)
        p.removeValue(forKey: "generated_at")
        return p
    }

    /// Rounds to `places` decimals and returns a decimal number, so JSON serialisation
    /// prints the value a human would write.
    private static func decimal(_ value: Double, places: Int) -> NSDecimalNumber {
        NSDecimalNumber(string: String(format: "%.\(places)f", value))
    }

    static func payload(_ result: AuditResult) -> [String: Any] {
        [
            "schema_version": resultSchemaVersion,
            "foldready_version": foldreadyVersion,
            "app": result.appName,
            "generated_at": ISO8601DateFormatter().string(from: result.generatedAt),
            "score": result.totalScore,
            "grade": result.grade,
            "risk": result.risk,
            "estimated_porting_hours": result.hoursEstimate,
            "score_is_provisional": result.scoreIsProvisional,
            "blockers": result.blockers.map { b -> [String: Any] in
                var d: [String: Any] = [
                    "id": b.id,
                    "title": b.title,
                    "consequence": b.consequence,
                    "reference": b.reference,
                    "stops_launch": b.stopsLaunch
                ]
                if let file = b.file { d["file"] = file }
                return d
            },
            "stats": [
                "swift_files": result.stats.swiftFiles,
                "ui_files": result.stats.uiFiles,
                "excluded_files": result.stats.excludedFiles,
                "swiftui_files": result.stats.swiftuiFiles,
                "uikit_files": result.stats.uikitFiles,
                "xib_or_storyboard": result.stats.xibOrStoryboard,
                "info_plists": result.stats.infoPlists
            ],
            "checks": result.outcomes.map { o in
                [
                    "key": o.key,
                    "title": o.title,
                    // Decimal, not Double: a weight of 0.08 has no exact binary form and
                    // serialises as 0.080000000000000002, which makes two identical
                    // results look different to anything diffing the JSON.
                    "weight": decimal(o.weight, places: 4),
                    "score": (o.score * 100).rounded(),
                    "reference": o.reference,
                    "detail": o.detail,
                    "signals": o.signals.mapValues { decimal($0, places: 3) }
                ] as [String: Any]
            },
            "findings": result.findings.map { f in
                var d: [String: Any] = [
                    "check": f.check,
                    "severity": f.severity.rawValue,
                    "message": f.message
                ]
                if let file = f.file { d["file"] = file }
                if let line = f.line { d["line"] = line }
                return d
            }
        ]
    }
}
