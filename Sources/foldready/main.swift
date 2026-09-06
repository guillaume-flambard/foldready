import Foundation

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

struct CliOptions {
    var path: String
    var appName: String?
    var outDir: String?
    var json: Bool = false
    var open: Bool = false
    var visual: Bool = false
    var screenshotsDir: String?
    var port: Bool = false
    var verify: Bool = false
    var gate: Bool = false
    var apply: Bool = false
    var build: Bool = false
    var baseline: String?
    var config: String?
    var writeBaseline: Bool = false
    var workOrderPath: String?
}

func usage() -> Never {
    print("""
    foldready v\(foldreadyVersion) - Fold-Ready audit of an iOS app source tree.

    USAGE
      foldready <path> [options]          Audit an iOS source tree
      foldready visual <dir> [--open]     Analyze screenshots only (captured layout)
      foldready port <path> [options]     Generate porting patches (or apply with --apply)
      foldready verify <path> [options]   Re-audit after a port (score delta)
      foldready gate <path> [options]     Audit and enforce a readiness policy (for CI)

    OPTIONS
      --name <name>           App name used in the report (default: folder name)
      --out <dir>             Write report files to <dir> (default: ./foldready-report)
      --with-screenshots <dir> Add a "Captured layout" check from PNG screenshots in <dir>
      --json                  Also write result.json (machine readable)
      --open                  Open the HTML report in the default browser
      --apply                 (port) write the provably safe edits to the working tree
      --work-order <file>     (verify) re-check a work order written by `port`
      --build                 (verify) build + capture the app on the widest simulator, add the visual check
      --config <file>         (gate) policy file (default: <path>/\(GatePolicy.defaultFileName))
      --baseline <file>       (gate) baseline result (default: <path>/\(GatePolicy.defaultBaselineName))
      --write-baseline        (gate) write the current result to the baseline path and exit
      --version               Print version
      -h, --help              Show this help

    GATE EXIT CODES
      0  policy satisfied, or no policy configured
      1  the run itself failed (unreadable tree, malformed config or baseline)
      2  policy breach: the audit ran and a rule was violated
    """)
    exit(0)
}

func parseArgs(_ args: [String]) -> CliOptions {
    var opts = CliOptions(path: "")
    var i = 0
    while i < args.count {
        let a = args[i]
        switch a {
        case "-h", "--help": usage()
        case "--version":
            print("foldready \(foldreadyVersion)")
            exit(0)
        case "visual":
            opts.visual = true
        case "port":
            opts.port = true
        case "verify":
            opts.verify = true
        case "gate":
            opts.gate = true
        case "--apply":
            opts.apply = true
        case "--write-baseline":
            opts.writeBaseline = true
        case "--baseline":
            i += 1
            if i < args.count { opts.baseline = args[i] }
        case "--config":
            i += 1
            if i < args.count { opts.config = args[i] }
        case "--build":
            opts.build = true
        case "--work-order":
            i += 1
            if i < args.count { opts.workOrderPath = args[i] }
        case "--name":
            i += 1
            if i < args.count { opts.appName = args[i] }
        case "--out":
            i += 1
            if i < args.count { opts.outDir = args[i] }
        case "--with-screenshots":
            i += 1
            if i < args.count { opts.screenshotsDir = args[i] }
        case "--json": opts.json = true
        case "--open": opts.open = true
        default:
            if opts.path.isEmpty { opts.path = a }
            else { print("unknown argument: \(a)"); usage() }
        }
        i += 1
    }
    guard !opts.path.isEmpty else {
        print("error: missing <path>")
        usage()
    }
    return opts
}

func listPNGs(in dir: String) -> [String] {
    let fm = FileManager.default
    guard let files = try? fm.contentsOfDirectory(atPath: dir) else { return [] }
    return files
        .filter { $0.hasSuffix(".png") }
        .sorted()
        .map { (dir as NSString).appendingPathComponent($0) }
}

func color(_ s: String, _ code: String) -> String {
    guard isatty(1) != 0 else { return s }
    return "\u{001B}\(code)m\(s)\u{001B}0m"
}


/// Prints the blockers before any score. A binary consequence must not arrive after a
/// grade that reads like a school mark.
func printBlockers(_ result: AuditResult) {
    for blocker in result.blockers {
        let tag = blocker.stopsLaunch ? color("BLOCKER", "31") : color("OPT-OUT", "33")
        let where_ = blocker.file.map { " (\($0))" } ?? ""
        print("  \(tag)  \(blocker.title)\(where_)")
        print("           \(blocker.consequence)")
    }
}

/// Runs the audit, evaluates the policy, prints the verdict, and returns the exit code.
/// Kept separate from `main` so the gate's reporting is readable in one place.
func runGate(root: String, appName: String, opts: CliOptions, screenshots: [String]) -> GateExit {
    let configPath = opts.config ?? (root as NSString).appendingPathComponent(GatePolicy.defaultFileName)
    let baselinePath = opts.baseline ?? (root as NSString).appendingPathComponent(GatePolicy.defaultBaselineName)

    let result = AuditEngine.run(root: root, appName: appName, screenshots: screenshots)

    if opts.writeBaseline {
        do {
            try Baseline.serialise(result).write(toFile: baselinePath, atomically: true, encoding: .utf8)
        } catch {
            FileHandle.standardError.write(Data("error: cannot write baseline '\(baselinePath)': \(error)\n".utf8))
            return .error
        }
        print(color("FoldReady gate", "36") + " - \(appName)")
        print("  baseline written: \(baselinePath)  (score \(Int(result.totalScore)))")
        print("  commit it, so an accepted regression is a reviewable diff.")
        return .pass
    }

    let policy: GatePolicy
    let baseline: Baseline?
    do {
        policy = try GatePolicy.load(path: configPath) ?? .empty
        // An explicit --baseline wins over the policy file's own baseline path.
        let resolved = opts.baseline ?? policy.baseline.map {
            (root as NSString).appendingPathComponent($0)
        } ?? baselinePath
        baseline = try Baseline.load(path: resolved)
    } catch {
        FileHandle.standardError.write(Data("error: \(error)\n".utf8))
        return .error
    }

    let outcome = GateEngine.evaluate(result: result, baseline: baseline, policy: policy)

    // The gate writes the same artefacts as an audit, so a CI job can fail the build and
    // still publish the report a reviewer needs.
    let outDir = opts.outDir ?? (root as NSString).appendingPathComponent("foldready-report")
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    let htmlPath = (outDir as NSString).appendingPathComponent("foldready-report.html")
    try? HTMLReport.render(result).write(toFile: htmlPath, atomically: true, encoding: .utf8)
    try? JSONReport.render(result).write(
        toFile: (outDir as NSString).appendingPathComponent("result.json"),
        atomically: true, encoding: .utf8)

    print(color("FoldReady gate", "36") + " - \(appName)")
    printBlockers(result)
    print("  score: \(color(String(Int(result.totalScore)), "33"))/100  grade \(result.grade)  risk \(result.risk)")
    if let description = outcome.baselineDescription {
        print("  baseline: \(description)")
    }

    print("  report: \(htmlPath)")

    if !outcome.policyConfigured {
        print("  no policy configured (\(configPath) absent or empty) — reporting only.")
        print("  write a baseline with: foldready gate \(root) --write-baseline")
        if opts.json { printGateJSON(result: result, outcome: outcome) }
        return .pass
    }

    for rule in outcome.rules {
        if let reason = rule.skippedReason, rule.passed {
            print("  \(color("skip", "33")) \(rule.name): \(reason)")
            continue
        }
        let mark = rule.passed ? color("pass", "32") : color("FAIL", "31")
        print("  \(mark) \(rule.name): expected \(rule.expected), actual \(rule.actual)")
        if !rule.passed {
            for finding in rule.findings.prefix(5) {
                let location = finding.file.map { "\($0)\(finding.line.map { ":\($0)" } ?? "")" } ?? "(project)"
                print("        \(finding.severity.rawValue)  \(location)  \(finding.message)")
            }
            if rule.findings.count > 5 {
                print("        … \(rule.findings.count - 5) more")
            }
        }
    }

    if opts.json { printGateJSON(result: result, outcome: outcome) }

    return outcome.exitCode
}

/// Emits the full audit result plus the verdict, so one CI step can both fail the build
/// and publish the numbers.
func printGateJSON(result: AuditResult, outcome: GateOutcome) {
    var payload = JSONReport.payload(result)
    payload["gate"] = [
        "passed": outcome.breaches.isEmpty,
        "policy_configured": outcome.policyConfigured,
        "rules": outcome.rules.map { rule -> [String: Any] in
            var d: [String: Any] = [
                "name": rule.name,
                "expected": rule.expected,
                "actual": rule.actual,
                "passed": rule.passed
            ]
            if let reason = rule.skippedReason { d["skipped_reason"] = reason }
            return d
        }
    ]
    if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
       let text = String(data: data, encoding: .utf8) {
        print(text)
    }
}

func main() {
    let opts = parseArgs(Array(CommandLine.arguments.dropFirst()))

    let root = (opts.path as NSString).expandingTildeInPath
    let fm = FileManager.default
    var isDir: ObjCBool = ObjCBool(false)
    guard fm.fileExists(atPath: root, isDirectory: &isDir), isDir.boolValue else {
        print("error: '\(opts.path)' is not a directory")
        exit(1)
    }

    let appName = opts.appName ?? (root as NSString).lastPathComponent

    if opts.port {
        let options = PortOptions(apply: opts.apply, outDir: opts.outDir)
        let result = PortEngine.run(root: root, appName: appName, options: options)
        print(color("FoldReady port", "36") + " - \(appName)")
        let mode = options.apply ? "applied" : "dry run"
        print("  mode: \(color(mode, options.apply ? "32" : "33"))")
        if options.apply { print("  \(color("\(result.appliedCount) edits written", "32")) to the working tree") }
        for patch in result.plan.patches {
            let n = patch.edits.count + patch.newFiles.count
            print("  \(color("[SAFE]", "32"))  \(patch.title)  (\(n) file\(n == 1 ? "" : "s"))")
            for note in patch.notes.prefix(2) { print("      - \(note)") }
        }
        if result.plan.patches.isEmpty { print("  no mechanically safe edit to make.") }
        let entries = result.workOrder.entries
        print("  \(color("work order", "36")): \(entries.count) item(s) needing judgement")
        for entry in entries.prefix(5) { print("      - \(entry.title)  (\(entry.location))") }
        if entries.count > 5 { print("      … \(entries.count - 5) more") }
        if let report = result.reportPath {
            print("  report: \(report)")
            let dir = (report as NSString).deletingLastPathComponent
            let patch = result.plan.patches.map(\.diff).joined()
            if !patch.isEmpty {
                let patchPath = (dir as NSString).appendingPathComponent("port.patch")
                try? patch.write(toFile: patchPath, atomically: true, encoding: .utf8)
            }
            // Per-transform patches (downloadable/applyable individually).
            if !result.plan.patches.isEmpty {
                let patchesDir = (dir as NSString).appendingPathComponent("patches")
                try? FileManager.default.createDirectory(atPath: patchesDir, withIntermediateDirectories: true)
                for p in result.plan.patches where !p.diff.isEmpty {
                    let path = (patchesDir as NSString).appendingPathComponent("\(p.transformId).patch")
                    try? p.diff.write(toFile: path, atomically: true, encoding: .utf8)
                }
            }
            if opts.json {
                let jsonPath = (dir as NSString).appendingPathComponent("porting-report.json")
                let patches = result.plan.patches.map { p -> [String: Any] in
                    [
                        "id": p.transformId,
                        "title": p.title,
                        "files": p.edits.count + p.newFiles.count,
                        "edits": p.edits.count,
                        "newFiles": p.newFiles.count,
                        "hasPatch": !p.diff.isEmpty,
                        "notes": p.notes,
                    ]
                }
                let obj: [String: Any] = ["app": appName, "applied": options.apply, "patches": patches]
                if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) {
                    try? data.write(to: URL(fileURLWithPath: jsonPath))
                }
            }
            if opts.open {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                p.arguments = [report]
                try? p.run()
            }
        }
        exit(0)
    }

    var screenshots = opts.screenshotsDir.map { listPNGs(in: $0) } ?? []
    if opts.build && screenshots.isEmpty {
        let shotsDir = (root as NSString).appendingPathComponent("foldready-screenshots")
        print("  building + capturing on the widest simulator…")
        if let dir = CapturePipeline.capture(root: root, appName: appName, shotsDir: shotsDir) {
            screenshots = listPNGs(in: dir)
            print("  captured \(screenshots.count) screenshot(s) → \(shotsDir)")
        } else {
            print("  build/capture failed (no project, or build error) — static score only.")
        }
    }

    if opts.gate {
        exit(runGate(root: root, appName: appName, opts: opts, screenshots: screenshots).rawValue)
    }

    if opts.verify {
        let result = AuditEngine.run(root: root, appName: appName, screenshots: screenshots)
        print(color("FoldReady verify", "36") + " - \(appName)")
        printBlockers(result)
        print("  score after port: \(color(String(Int(result.totalScore)), "33"))/100  grade \(result.grade)")
        for o in result.outcomes where o.key == "captured-layout" {
            print("  captured layout: \(color(String(format: "%.0f%%", o.score * 100), o.score >= 0.6 ? "32" : "33"))  (\(o.detail))")
        }

        // A work order closes the loop: per-entry status, not just a new total.
        let workOrderPath = opts.workOrderPath
            ?? (root as NSString).appendingPathComponent("foldready-port/work-order.json")
        if let workOrder = WorkOrder.load(path: workOrderPath) {
            var counts: [WorkOrder.Status: Int] = [:]
            print("  work order: \(workOrder.entries.count) item(s) from a score of \(Int(workOrder.score))")
            for entry in workOrder.entries {
                let status = workOrder.status(of: entry, after: result)
                counts[status, default: 0] += 1
                let code = status == .fixed ? "32" : (status == .regressed ? "31" : "33")
                print("    \(color(status.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0), code)) \(entry.title)  (\(entry.location))")
            }
            let delta = result.totalScore - workOrder.score
            let sign = delta >= 0 ? "+" : ""
            print("  \(counts[.fixed] ?? 0) fixed, \(counts[.unchanged] ?? 0) unchanged, \(counts[.regressed] ?? 0) regressed  ·  score \(sign)\(Int(delta))")
        } else if opts.workOrderPath != nil {
            print("  no work order could be read at \(workOrderPath)")
        } else {
            print("  no work order found — run `foldready port \(root)` first for per-item status.")
        }
        print("  full audit: foldready \(root) --name \"\(appName)\"")
        exit(0)
    }

    if opts.visual {
        let shots = listPNGs(in: root)
        guard !shots.isEmpty else {
            print("error: no PNG files found in \(root)")
            exit(1)
        }
        var results: [VisualResult] = []
        for s in shots {
            if let r = try? VisualAnalysis.analyze(png: s) { results.append(r) }
            else { print("  skip (undecodable): \(s)") }
        }
        let avg = VisualAnalysis.averageScore(results)
        print(color("FoldReady visual", "36") + " - \(shots.count) screenshot(s)")
        for r in results {
            let pct = Int((r.layoutScore * 100).rounded())
            print("  \(color(String(format: "%3d", pct) + "%", pct >= 60 ? "32" : (pct >= 35 ? "33" : "31")))  \(r.file)  \(r.width)x\(r.height)  letterbox \(String(format: "%.0f%%", r.letterbox * 100))")
        }
        print("  combined captured-layout: \(color(String(format: "%.0f%%", avg * 100), avg >= 0.6 ? "32" : "33"))")
        exit(0)
    }

    let result = AuditEngine.run(root: root, appName: appName, screenshots: screenshots)

    let outDir = opts.outDir ?? (root as NSString).appendingPathComponent("foldready-report")
    try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

    let html = HTMLReport.render(result)
    let htmlPath = (outDir as NSString).appendingPathComponent("foldready-report.html")
    try? html.write(toFile: htmlPath, atomically: true, encoding: .utf8)

    if opts.json {
        let json = JSONReport.render(result)
        let jsonPath = (outDir as NSString).appendingPathComponent("result.json")
        try? json.write(toFile: jsonPath, atomically: true, encoding: .utf8)
    }

    print(color("FoldReady", "36") + " - \(appName)")
    printBlockers(result)
    let provisional = result.scoreIsProvisional ? " (provisional: the app opted out of a resizable scene)" : ""
    print("  score: \(color(String(Int(result.totalScore)), "33"))/100  grade \(result.grade)  risk \(result.risk)\(provisional)")
    print("  est. porting effort: \(color("\(result.hoursEstimate) h", "32"))")
    print("  \(result.stats.uiFiles) UI files of \(result.stats.swiftFiles) Swift files (\(result.stats.excludedFiles) excluded: tests, previews, vendored)")
    for o in result.outcomes {
        let pct = Int((o.score * 100).rounded())
        print("    \(color(String(format: "%3d", pct) + "%", pct >= 60 ? "32" : (pct >= 35 ? "33" : "31")))  \(o.title)")
    }
    print("  report: \(htmlPath)")

    if opts.open {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = [htmlPath]
        try? p.run()
    }
}

main()
