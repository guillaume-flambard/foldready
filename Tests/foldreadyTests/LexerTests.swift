import Testing
import Foundation
@testable import foldready

private func lexed(_ source: String) -> LexedFile {
    SwiftLexer.lex(FileContent(path: "App/View.swift", content: source))
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
