import Testing
import Foundation
@testable import foldready

private func tree(_ files: [String: String]) -> String {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-score-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (name, content) in files {
        let url = dir.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    return dir.path
}

/// `count` clean SwiftUI files plus `offending` files reading fixed screen geometry.
private func app(clean: Int, offending: Int, prefix: String = "F") -> [String: String] {
    var files: [String: String] = [:]
    for i in 0..<clean {
        files["\(prefix)Clean\(i).swift"] = """
        import SwiftUI

        struct Clean\(i): View {
            @Environment(\\.horizontalSizeClass) private var sizeClass
            var body: some View { Text("clean") }
        }
        """
    }
    for i in 0..<offending {
        files["\(prefix)Bad\(i).swift"] = """
        import UIKit

        final class Bad\(i): UIViewController {
            func layout() { _ = UIScreen.main.bounds.width }
        }
        """
    }
    return files
}

@Suite("Scoring")
struct ScoringTests {

    @Test("A UIKit app that adapts is not penalised for being UIKit")
    func uikitCanScoreWell() {
        let uikit = tree([
            "Info.plist": "<plist><dict></dict></plist>",
            "Scene.swift": """
            import UIKit

            final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
                var window: UIWindow?
            }
            """,
            "Root.swift": """
            import UIKit

            final class Root: UITabBarController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                    sidebar.preferredPlacement = .sidebar
                    let regular = traitCollection.horizontalSizeClass == .regular
                    _ = regular
                }
            }
            """,
            "List.swift": """
            import UIKit

            final class ListVC: UIViewController {
                let table = UITableView()
                let restorationIdentifier2 = "list"
                override func viewDidLoad() {
                    super.viewDidLoad()
                    restorationIdentifier = "list"
                    let regular = traitCollection.horizontalSizeClass == .regular
                    _ = regular
                }
            }
            """
        ])
        let result = AuditEngine.run(root: uikit, appName: "UIKitApp")
        #expect(result.blockers.isEmpty, "a scene delegate is a scene lifecycle")
        #expect(result.totalScore >= 85, "score was \(result.totalScore)")
        #expect(result.grade == "A")
        #expect(!result.outcomes.contains { $0.key == "framework" },
                "the framework-ratio check is gone")
    }

    @Test("Two apps of very different sizes with the same density score the same")
    func densityIsSizeIndependent() {
        let small = AuditEngine.run(root: tree(app(clean: 18, offending: 2)), appName: "Small")
        let large = AuditEngine.run(root: tree(app(clean: 180, offending: 20)), appName: "Large")

        let sSmall = small.outcomes.first { $0.key == "adaptive-layout" }?.score ?? -1
        let sLarge = large.outcomes.first { $0.key == "adaptive-layout" }?.score ?? -2
        #expect(abs(sSmall - sLarge) < 0.01, "\(sSmall) vs \(sLarge)")
    }

    @Test("A denser problem scores lower than a sparser one")
    func densityOrders() {
        let sparse = AuditEngine.run(root: tree(app(clean: 95, offending: 5)), appName: "Sparse")
        let dense = AuditEngine.run(root: tree(app(clean: 70, offending: 30)), appName: "Dense")
        let a = sparse.outcomes.first { $0.key == "adaptive-layout" }?.score ?? 0
        let b = dense.outcomes.first { $0.key == "adaptive-layout" }?.score ?? 1
        #expect(a > b)
    }

    @Test("Icon frames, previews, test paths and XCUIScreen produce no scored finding")
    func exclusions() {
        let root = tree([
            "Icons.swift": """
            import SwiftUI

            struct Icons: View {
                var body: some View {
                    Circle().frame(width: 16, height: 16)
                }
            }

            #Preview {
                Icons().frame(width: 400, height: 800)
            }
            """,
            "Snapshots/SnapshotHelper.swift": """
            import XCTest

            func shot() { _ = XCUIScreen.main.screenshot() }
            """,
            "MyAppTests/LayoutTests.swift": """
            import UIKit

            final class LayoutTests {
                func t() { _ = UIScreen.main.bounds }
            }
            """
        ])
        let result = AuditEngine.run(root: root, appName: "Excl")
        let scored = result.findings.filter { $0.check == "adaptive-layout" }
        #expect(scored.isEmpty, "got \(scored.map(\.message))")
        #expect(result.stats.excludedFiles >= 2)
    }

    @Test("A check that does not apply redistributes its weight")
    func notApplicableRedistributes() {
        // No list or scroll view anywhere: state preservation does not apply.
        let root = tree(app(clean: 4, offending: 0))
        let result = AuditEngine.run(root: root, appName: "NoState")
        #expect(!result.outcomes.contains { $0.key == "state" })
        let sum = result.outcomes.reduce(0.0) { $0 + $1.weight }
        #expect(abs(sum - 1.0) < 0.0001)
    }

    @Test("Blockers are reported outside the score and lead the work order")
    func blockersLead() {
        let root = tree([
            "Info.plist": """
            <?xml version="1.0" encoding="UTF-8"?>
            <plist version="1.0"><dict>
            <key>UIRequiresFullScreen</key>
            <true/>
            </dict></plist>
            """,
            "Feed.swift": """
            import SwiftUI

            struct Feed: View {
                var body: some View {
                    NavigationStack { List(1...3, id: \\.self) { Text("\\($0)") } }
                }
            }
            """
        ])
        let result = AuditEngine.run(root: root, appName: "Blocked")
        #expect(result.blockers.count == 2, "no scene lifecycle and a full-screen opt-out")
        #expect(result.blockers.contains { $0.stopsLaunch })
        #expect(result.scoreIsProvisional)
        #expect(!result.outcomes.contains { $0.key == "scene" || $0.key == "full-screen" },
                "blocking facts are not weighted checks")

        let order = WorkOrderBuilder.build(from: result)
        #expect(order.entries.first?.id == "scene-lifecycle")
        #expect(order.entries.contains { $0.id == "full-screen-opt-out" })
    }

    @Test("A policy can forbid blockers without setting a score floor")
    func policyForbidsBlockers() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("fr-policy-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent(GatePolicy.defaultFileName).path
        try #"{ "forbid_blockers": true }"#.write(toFile: path, atomically: true, encoding: .utf8)
        let policy = try #require(try GatePolicy.load(path: path))

        let blocked = AuditEngine.run(root: tree(["Feed.swift": """
            import SwiftUI
            struct Feed: View { var body: some View { Text("x") } }
            """]), appName: "Blocked")
        #expect(GateEngine.evaluate(result: blocked, baseline: nil, policy: policy).exitCode == .breach)

        let fine = AuditEngine.run(root: tree(["App.swift": """
            import SwiftUI
            @main struct A: App { var body: some Scene { WindowGroup { Text("x") } } }
            """]), appName: "Fine")
        #expect(fine.blockers.isEmpty)
        #expect(GateEngine.evaluate(result: fine, baseline: nil, policy: policy).exitCode == .pass)
    }
}
