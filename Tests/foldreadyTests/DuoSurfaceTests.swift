import Testing
import Foundation
@testable import foldready

/// Writes a tree of files, creating intermediate directories, and returns its root.
private func writeTree(_ files: [String: String], in parent: URL) -> String {
    for (path, content) in files {
        let url = parent.appendingPathComponent(path)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    return parent.path
}

private func tempTree() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr-duo-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func project(generation: Int) -> String {
    """
    // !$*UTF8*$!
    {
    \tarchiveVersion = 1;
    \tclasses = {
    \t};
    \tobjectVersion = 77;
    \tobjects = {
    \t\tABC123 /* Project object */ = {
    \t\t\tisa = PBXProject;
    \t\t\tattributes = {
    \t\t\t\tLastUpgradeCheck = \(generation);
    \t\t\t};
    \t\t};
    \t};
    \trootObject = ABC123 /* Project object */;
    }
    """
}

@Suite("Build floor")
struct BuildFloorTests {

    @Test("A project below the Xcode 27.1 generation reports a gap, not a failure")
    func belowFloor() throws {
        let root = writeTree([
            "App.xcodeproj/project.pbxproj": project(generation: 2600),
            "Feed.swift": """
            import SwiftUI

            struct Feed: View {
                var body: some View { NavigationStack { List(1...5, id: \\.self) { Text("\\($0)") } } }
            }
            """
        ], in: tempTree())

        let result = AuditEngine.run(root: root, appName: "App")
        let check = try #require(result.outcomes.first { $0.key == "build-toolchain" })
        #expect(check.score == 0)
        #expect(check.reference.hasPrefix("https://developer.apple.com/"))

        let finding = try #require(result.findings.first { $0.check == "build-toolchain" })
        #expect(finding.message.contains("does not extend under the status bar and camera"))
        #expect(finding.message.contains("can be stale"))
        #expect(finding.file == "App.xcodeproj/project.pbxproj")
        #expect(result.build.highestUpgradeCheck == 2600)
        #expect(result.build.objectVersions == [77])
    }

    @Test("A project at the Xcode 27.1 generation passes with full marks")
    func atFloor() throws {
        let root = writeTree([
            "App.xcodeproj/project.pbxproj": project(generation: BuildFloor.xcode27_1Generation),
            "Feed.swift": "import SwiftUI\n\nstruct Feed: View { var body: some View { Text(\"hi\") } }\n"
        ], in: tempTree())

        let result = AuditEngine.run(root: root, appName: "App")
        let check = try #require(result.outcomes.first { $0.key == "build-toolchain" })
        #expect(check.score == 1)
        #expect(!result.findings.contains { $0.check == "build-toolchain" })
    }

    @Test("A tree with no project file is not penalised for the build floor")
    func noProject() throws {
        let root = writeTree([
            "Feed.swift": "import SwiftUI\n\nstruct Feed: View { var body: some View { Text(\"hi\") } }\n"
        ], in: tempTree())

        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.outcomes.contains { $0.key == "build-toolchain" })
        #expect(result.build.isEmpty)

        let weights = result.outcomes.reduce(0.0) { $0 + $1.weight }
        #expect(abs(weights - 1) < 0.0001)
    }
}

@Suite("Duo surfaces")
struct DuoSurfaceTests {

    private let panes = """
    import SwiftUI

    struct Panes: View {
        var body: some View {
            HStack {
                GeometryReader { proxy in
                    Color.clear.frame(in: .local)
                }
                GeometryReader { proxy in
                    Color.clear.frame(in: .local)
                }
            }
        }
    }
    """

    @Test("An advisory surface never changes the score")
    func advisoryIsOutsideTheScore() throws {
        let withoutQuery = writeTree(["Panes.swift": panes], in: tempTree())
        let withQuery = writeTree([
            "Panes.swift": panes + "\nlet regions = proxy.reservedRegions(kind: .division)\n"
        ], in: tempTree())

        let a = AuditEngine.run(root: withoutQuery, appName: "App")
        let b = AuditEngine.run(root: withQuery, appName: "App")

        #expect(a.advisory.contains { $0.surface == DuoSurfaces.reservedRegions })
        #expect(!b.advisory.contains { $0.surface == DuoSurfaces.reservedRegions })
        #expect(a.advisory.count > b.advisory.count)

        #expect(a.totalScore == b.totalScore)
        let ja = JSONReport.comparablePayload(a) as? [String: Any]
        let jb = JSONReport.comparablePayload(b) as? [String: Any]
        #expect((ja?["checks"] as? [[String: Any]])?.count == (jb?["checks"] as? [[String: Any]])?.count)
        #expect(ja?["score"] as? Double == jb?["score"] as? Double)
    }

    @Test("Occurrences collapse to one entry per file and surface")
    func boundedReporting() throws {
        let root = writeTree(["Panes.swift": panes], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")

        let reserved = try #require(result.advisory.filter { $0.surface == DuoSurfaces.reservedRegions })
        #expect(reserved.count == 1)
        #expect(reserved[0].collapsed == 4)
        #expect(reserved[0].line == 6)
        #expect(reserved[0].reference.hasPrefix("https://developer.apple.com/"))
        #expect(!reserved[0].runtimeCheck.isEmpty)
    }

    @Test("Preview blocks do not raise advisory questions")
    func previewsAreExcluded() throws {
        let root = writeTree([
            "Preview.swift": """
            import SwiftUI

            struct Panes: View { var body: some View { Text("hi") } }

            #Preview {
                HStack {
                    GeometryReader { proxy in
                        Color.clear.frame(in: .local)
                    }
                }
            }
            """
        ], in: tempTree())

        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.advisory.contains { $0.surface == DuoSurfaces.reservedRegions })
    }

    @Test("Surfaces found in the source reach the runtime checks")
    func surfacesReachRuntimeChecks() throws {
        let root = writeTree(["Panes.swift": panes], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")

        #expect(!result.advisoryRuntimeChecks.isEmpty)
        #expect(result.advisoryRuntimeChecks == DuoSurfaces.runtimeChecks(for: result.advisory))

        let payload = Evidence.payload(surfaceChecks: result.advisoryRuntimeChecks)
        let checks = try #require(payload["runtime_checks_required"] as? [String])
        #expect(checks.count == Evidence.runtimeChecks.count + result.advisoryRuntimeChecks.count)
    }
}
