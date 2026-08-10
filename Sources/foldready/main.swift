import Foundation

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

let version = "0.1.0"

struct CliOptions {
    var path: String
    var appName: String?
    var outDir: String?
    var json: Bool = false
    var open: Bool = false
    var visual: Bool = false
    var screenshotsDir: String?
}

func usage() -> Never {
    print("""
    foldready v\(version) - Fold-Ready audit of an iOS app source tree.

    USAGE
      foldready <path> [options]          Audit an iOS source tree
      foldready visual <dir> [--open]     Analyze screenshots only (captured layout)

    OPTIONS
      --name <name>           App name used in the report (default: folder name)
      --out <dir>             Write report files to <dir> (default: ./foldready-report)
      --with-screenshots <dir> Add a "Captured layout" check from PNG screenshots in <dir>
      --json                  Also write result.json (machine readable)
      --open                  Open the HTML report in the default browser
      --version               Print version
      -h, --help              Show this help
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
            print("foldready \(version)")
            exit(0)
        case "visual":
            opts.visual = true
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

    let screenshots = opts.screenshotsDir.map { listPNGs(in: $0) } ?? []
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
    print("  score: \(color(String(Int(result.totalScore)), "33"))/100  grade \(result.grade)  risk \(result.risk)")
    print("  est. porting effort: \(color("\(result.hoursEstimate) h", "32"))")
    print("  \(result.stats.swiftFiles) Swift files (\(result.stats.swiftuiFiles) SwiftUI, \(result.stats.uikitFiles) UIKit)")
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
