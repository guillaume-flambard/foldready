import Testing
import Foundation
@testable import foldready

private func tree(_ files: [String: String]) -> String {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-wo-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (name, content) in files {
        let url = dir.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    return dir.path
}

private let unreadyApp = [
    "Feed.swift": """
    import SwiftUI

    struct Feed: View {
        var body: some View {
            NavigationStack {
                List(1...5, id: \\.self) { Text("\\($0)") }
            }
        }
    }
    """,
    "Legacy.swift": """
    import UIKit

    final class Legacy: UIViewController {
        func layout() { _ = UIScreen.main.bounds.width }
    }
    """
]

private let readyApp = [
    "Feed.swift": """
    import SwiftUI

    @main
    struct DemoApp: App {
        @SceneStorage("selection") var selection: String?
        var body: some Scene { WindowGroup { Feed() } }
    }

    struct Feed: View {
        @Environment(\\.horizontalSizeClass) private var sizeClass
        var body: some View {
            NavigationSplitView {
                List(1...5, id: \\.self) { Text("\\($0)") }
            } detail: {
                Text("detail")
            }
        }
    }
    """
]

@Suite("Work order")
struct WorkOrderTests {

    @Test("Entries cite the platform requirement, not a FoldReady transform")
    func entriesAreAgentExecutable() {
        let result = AuditEngine.run(root: tree(unreadyApp), appName: "Unready")
        let order = WorkOrderBuilder.build(from: result)
        #expect(!order.entries.isEmpty)
        for entry in order.entries {
            #expect(entry.reference.hasPrefix("https://developer.apple.com/"))
            #expect(!entry.requiredEndState.isEmpty)
            #expect(!entry.acceptance.described.isEmpty)
            #expect(!entry.checkKey.isEmpty)
        }
        // Nothing in an entry names a FoldReady internal: the work must be executable by
        // an agent that has never seen this tool.
        for entry in order.entries {
            #expect(!entry.requiredEndState.lowercased().contains("foldready"))
        }
    }

    @Test("A ready app produces no work order entries")
    func readyAppHasNothingToHandOver() {
        let result = AuditEngine.run(root: tree(readyApp), appName: "Ready")
        let order = WorkOrderBuilder.build(from: result)
        #expect(order.entries.isEmpty)
        #expect(order.markdown().contains("Nothing to hand over"))
    }

    @Test("Verification reports fixed, unchanged and regressed per entry")
    func perEntryStatus() {
        let before = AuditEngine.run(root: tree(unreadyApp), appName: "Unready")
        let order = WorkOrderBuilder.build(from: before)
        let after = AuditEngine.run(root: tree(readyApp), appName: "Unready")

        let statuses = order.entries.map { order.status(of: $0, after: after) }
        #expect(statuses.contains(.fixed))
        #expect(!statuses.contains(.regressed))

        // Nothing done: every entry stays unchanged.
        let untouched = order.entries.map { order.status(of: $0, after: before) }
        #expect(untouched.allSatisfy { $0 == .unchanged })
    }

    @Test("An entry that was already satisfied and breaks again reads as regressed")
    func regression() {
        let ready = AuditEngine.run(root: tree(readyApp), appName: "Ready")
        let entry = WorkOrderEntry(
            id: "scene-lifecycle", title: "Adopt the UIScene lifecycle", checkKey: "scene",
            file: nil, line: nil, requiredEndState: "scene lifecycle adopted",
            reference: Reference.sceneLifecycle,
            acceptance: .noBlocker(id: Blockers.sceneLifecycleMissing),
            metWhenWritten: true)
        let order = WorkOrder(app: "Ready", generatedAt: Date(), score: ready.totalScore,
            entries: [entry])

        let broken = AuditEngine.run(root: tree(unreadyApp), appName: "Ready")
        #expect(order.status(of: entry, after: broken) == .regressed)
        #expect(order.status(of: entry, after: ready) == .fixed)
    }

    @Test("The work order round-trips through its machine form")
    func roundTrip() throws {
        let result = AuditEngine.run(root: tree(unreadyApp), appName: "Unready")
        let order = WorkOrderBuilder.build(from: result)

        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("work-order-\(UUID().uuidString).json").path
        try order.json().write(toFile: path, atomically: true, encoding: .utf8)

        let reloaded = try #require(WorkOrder.load(path: path))
        #expect(reloaded.entries.count == order.entries.count)
        for (a, b) in zip(order.entries, reloaded.entries) {
            #expect(a.id == b.id)
            #expect(a.acceptance == b.acceptance)
            #expect(a.metWhenWritten == b.metWhenWritten)
            #expect(a.file == b.file)
        }
    }
}
