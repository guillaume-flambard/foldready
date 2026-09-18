import Testing
import Foundation
@testable import foldready

private func lexed(_ source: String) -> LexedFile {
    SwiftLexer.lex(FileContent(path: "App/View.swift", content: source))
}

/// Writes a tree of files, creating intermediate directories, and returns its root path.
/// Copied from `DuoSurfaceTests.swift`, where the helpers are file-private.
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
        .appendingPathComponent("fr-lexed-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("Lexer")
struct LexerTests {

    @Test func lineCommentIsDropped() {
        let file = lexed("let a = 1 // UIScreen.main.bounds\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func nestedBlockCommentIsDropped() {
        let source = """
        /* outer /* inner UIScreen.main.bounds */ still */
        let a = 1
        """
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func stringLiteralContentsAreDropped() {
        let file = lexed("let s = \"UIScreen.main.bounds\"\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func multilineStringContentsAreDropped() {
        let source = """
        let s = \"\"\"
        UIScreen.main.bounds
        \"\"\"
        """
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func rawStringContentsAreDropped() {
        let file = lexed("let s = #\"UIScreen.main.bounds\"#\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func interpolationIsRealCode() {
        let file = lexed("let s = \"\\(UIScreen.main.bounds.width)\"\n")
        #expect(file.matches(Exclusions.screenMainBounds))
    }

    @Test func escapedQuoteDoesNotEndTheString() {
        let source = "let s = \"a \\\" UIScreen.main.bounds\"\n"
        #expect(!lexed(source).matches(Exclusions.screenMainBounds))
    }

    @Test func codeAfterACommentSurvives() {
        let file = lexed("let a = 1 // note\nlet b = UIScreen.main.bounds\n")
        #expect(file.matches(Exclusions.screenMainBounds))
    }

    @Test func lineNumbersSurviveCommentStripping() {
        let file = lexed("let a = 1 // note\nlet b = UIScreen.main.bounds\n")
        let line = file.lines.first { $0.code.contains("UIScreen.main.bounds") }
        #expect(line?.number == 2)
    }

    @Test func unterminatedBlockCommentFailsTheFile() {
        let file = lexed("/* never closed\nlet a = UIScreen.main.bounds\n")
        #expect(file.failed)
    }

    @Test func nestedStringInsideInterpolationIsDropped() {
        let file = lexed("let s = \"\\(mark(\"UIScreen.main.bounds\"))\"\n")
        #expect(!file.matches(Exclusions.screenMainBounds))
    }

    @Test func unterminatedStringFailsTheFile() {
        let file = lexed("let s = \"never closed\n")
        #expect(file.failed)
    }

    @Test func unterminatedMultilineStringFailsTheFile() {
        let file = lexed("let s = \"\"\"\nnever closed\n")
        #expect(file.failed)
    }

    @Test func unterminatedRawStringFailsTheFile() {
        let file = lexed("let s = #\"never closed\n")
        #expect(file.failed)
    }

    @Test func previewBodyIsRecordedAsARange() {
        let source = """
        struct A: View { var body: some View { Text("a") } }
        #Preview {
            Text("b")
        }
        """
        let file = lexed(source)
        #expect(!file.previewRanges.isEmpty)
    }

    @Test func braceInsideAStringDoesNotBreakPreviewTracking() {
        let source = """
        #Preview {
            Text("}")
        }
        struct After: View { var body: some View { Text("x") } }
        """
        let file = lexed(source)
        let after = file.lines.first { $0.code.contains("struct After") }
        #expect(after != nil)
        #expect(!(file.previewRanges.last?.contains((after?.number ?? 0) - 1) ?? false))
    }
}

@Suite("Lexed checks")
struct LexedCheckTests {

    @Test func aSymbolOnlyInACommentDoesNotScore() {
        let root = writeTree(["App/View.swift": """
        import SwiftUI
        // UIScreen.main.bounds
        struct View1: View { var body: some View { Text("x") } }
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")
        #expect(!result.findings.contains { $0.message.contains("UIScreen.main.bounds") })
    }

    @Test func anUnlexableFileIsReportedAndNotScored() {
        let root = writeTree(["App/Broken.swift": """
        import SwiftUI
        /* never closed
        let x = UIScreen.main.bounds
        """], in: tempTree())
        let result = AuditEngine.run(root: root, appName: "App")

        #expect(result.stats.failedFiles == 1)
        #expect(!result.findings.contains { $0.file == "App/Broken.swift" })

        let html = HTMLReport.render(result)
        #expect(html.contains(
            "<div class=\"k\">Files the lexer could not read</div><div class=\"v\">1</div>"))
    }
}
