import Foundation

struct PortOptions {
    var tiers: [TransformTier] = [.safe, .review, .manual]
    var apply: Bool = false
    var outDir: String?
}

enum PortEngine {

    static func run(root: String, appName: String, options: PortOptions) -> PortResult {
        let swift = walk(extension: "swift", at: root)
        let plists = walk(extension: "plist", at: root)
        let input = TransformInput(root: root, swiftFiles: swift, plists: plists)

        let all = [
            Transforms.removeFullScreen(input),
            Transforms.sidebarOptIn(input),
            Transforms.sceneLifecycle(input),
            Transforms.screenBounds(input),
            Transforms.adaptiveNavigation(input),
            Transforms.statePreservation(input),
            Transforms.dehardcodeFrames(input),
        ]

        let patches = all
            .filter { !$0.isNoop && options.tiers.contains($0.tier) }
            .sorted { $0.tier < $1.tier }

        var appliedCount = 0
        var skippedNotes: [String] = []
        if options.apply {
            // Group edits by file so multiple transforms on the same file compose.
            var editsByPath: [String: [FileEdit]] = [:]
            for patch in patches {
                for edit in patch.edits where edit.before != edit.after && !edit.path.contains("..") {
                    editsByPath[edit.path, default: []].append(edit)
                }
                for (path, content) in patch.newFiles {
                    let full = (root as NSString).appendingPathComponent(path)
                    if FileManager.default.fileExists(atPath: full) {
                        skippedNotes.append("\(path): new file already exists, skipped.")
                    } else if writeNewFile(root: root, path: path, content: content) {
                        appliedCount += 1
                    }
                }
            }
            for (path, edits) in editsByPath.sorted(by: { $0.key < $1.key }) {
                let full = (root as NSString).appendingPathComponent(path)
                guard let data = FileManager.default.contents(atPath: full),
                      var current = String(data: data, encoding: .utf8) else {
                    skippedNotes.append("\(path): cannot read file, edits skipped.")
                    continue
                }
                var appliedHere = 0
                for edit in edits {
                    if current == edit.before {
                        current = edit.after
                        appliedHere += 1
                        continue
                    }
                    // The edit was computed against the pristine file; merge it into
                    // the current content via ordered line operations so transforms
                    // on the same file compose.
                    let a = edit.before.components(separatedBy: .newlines)
                    let b = edit.after.components(separatedBy: .newlines)
                    if let merged = applyOps(current, Diff.operations(a, b)) {
                        current = merged
                        appliedHere += 1
                    } else {
                        skippedNotes.append("\(path): an edit could not be merged into the current content (conflict), skipped.")
                    }
                }
                do {
                    try current.write(toFile: full, atomically: true, encoding: .utf8)
                    appliedCount += appliedHere
                } catch {
                    skippedNotes.append("\(path): write failed — \(error.localizedDescription)")
                }
            }
        }

        let plan = PortPlan(patches: patches, skippedNotes: skippedNotes)
        let reportPath = writeReport(root: root, appName: appName, plan: plan, applied: options.apply, outDir: options.outDir)
        return PortResult(appName: appName, plan: plan, applied: options.apply,
            appliedCount: appliedCount, reportPath: reportPath)
    }

    // MARK: - File IO

    private static func walk(extension ext: String, at root: String) -> [FileContent] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: root) else { return [] }
        var result: [FileContent] = []
        while let rel = enumerator.nextObject() as? String {
            let url = URL(fileURLWithPath: rel)
            guard url.pathExtension == ext else { continue }
            let components = url.pathComponents
            if components.contains(".build") || components.contains(".git") || components.contains("node_modules")
                || components.contains("Pods") || components.contains("DerivedData") || components.contains("foldready-port") { continue }
            let full = (root as NSString).appendingPathComponent(rel)
            guard let data = fm.contents(atPath: full), let text = String(data: data, encoding: .utf8) else { continue }
            result.append(FileContent(path: rel, content: text))
        }
        return result
    }

    private static func writeNewFile(root: String, path: String, content: String) -> Bool {
        let full = (root as NSString).appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: full) { return false }
        do {
            try content.write(toFile: full, atomically: true, encoding: .utf8)
            return true
        } catch { return false }
    }

    /// Replay ordered line ops onto the current content, preserving lines that other
    /// transforms inserted (context lines skip forward). Returns nil on conflict.
    private static func applyOps(_ current: String, _ ops: [Diff.Op]) -> String? {
        let linesC = current.components(separatedBy: .newlines)
        var out: [String] = []
        var r = 0
        for op in ops {
            switch op {
            case .context(let line):
                while r < linesC.count && linesC[r] != line {
                    out.append(linesC[r]) // keep lines inserted by other transforms
                    r += 1
                }
                guard r < linesC.count else { return nil }
                out.append(line)
                r += 1
            case .remove(let line):
                guard r < linesC.count, linesC[r] == line else { return nil }
                r += 1
            case .insert(let line):
                out.append(line)
            }
        }
        while r < linesC.count { out.append(linesC[r]); r += 1 }
        return out.joined(separator: "\n")
    }

    // MARK: - Report

    private static func writeReport(root: String, appName: String, plan: PortPlan, applied: Bool, outDir: String?) -> String? {
        let dir = outDir ?? (root as NSString).appendingPathComponent("foldready-port")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let path = (dir as NSString).appendingPathComponent("porting-report.md")

        let tierLabel: [TransformTier: String] = [.safe: "SAFE (auto-apply)", .review: "REVIEW (check the diff)", .manual: "MANUAL (suggested)"]
        var md = "# FoldReady — porting report: \(appName)\n\n"
        md += applied ? "**Applied \(plan.patches.map(\.edits.count).reduce(0, +)) edits to the working tree.**\n\n" : "**Dry run — review the patches, then re-run with `--apply`.**\n\n"

        for patch in plan.patches {
            md += "## \(patch.title) · \(tierLabel[patch.tier] ?? patch.tier.rawValue)\n\n"
            if !patch.notes.isEmpty {
                md += patch.notes.map { "- \($0)" }.joined(separator: "\n") + "\n\n"
            }
            if !patch.diff.isEmpty {
                md += "```diff\n\(patch.diff)```\n\n"
            }
        }
        if !plan.skippedNotes.isEmpty {
            md += "## Skips & conflicts\n\n"
            md += plan.skippedNotes.map { "- \($0)" }.joined(separator: "\n") + "\n\n"
        }
        do {
            try md.write(toFile: path, atomically: true, encoding: .utf8)
            return path
        } catch { return nil }
    }
}
