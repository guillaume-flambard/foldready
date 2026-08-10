import Foundation

enum JSONReport {

    static func render(_ result: AuditResult) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let dict: [String: Any] = [
            "app": result.appName,
            "root": result.root,
            "generatedAt": ISO8601DateFormatter().string(from: result.generatedAt),
            "score": result.totalScore,
            "grade": result.grade,
            "risk": result.risk,
            "estimatedPortingHours": result.hoursEstimate,
            "stats": [
                "swiftFiles": result.stats.swiftFiles,
                "swiftuiFiles": result.stats.swiftuiFiles,
                "uikitFiles": result.stats.uikitFiles,
                "xibOrStoryboard": result.stats.xibOrStoryboard,
                "infoPlists": result.stats.infoPlists
            ],
            "checks": result.outcomes.map { o in
                [
                    "key": o.key,
                    "title": o.title,
                    "weight": o.weight,
                    "score": (o.score * 100).rounded(),
                    "detail": o.detail
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

        let data = try! JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
