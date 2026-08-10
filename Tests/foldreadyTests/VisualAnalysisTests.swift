import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import foldready

private func makeContext(w: Int, h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

private func write(_ img: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("no dest")
    }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

private func tempPNG(_ name: String, draw: (CGContext) -> Void) -> String {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("fr-tests", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent(name)
    let ctx = makeContext(w: 400, h: 800)
    draw(ctx)
    write(ctx.makeImage()!, to: url)
    return url.path
}

@Suite("VisualAnalysis")
struct VisualAnalysisTests {

    @Test("full content fills the frame")
    func fullContent() throws {
        let png = tempPNG("full.png") { ctx in
            ctx.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 800))
            ctx.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 70))
            ctx.fill(CGRect(x: 0, y: 740, width: 400, height: 60))
            ctx.fill(CGRect(x: 30, y: 120, width: 90, height: 120))
            ctx.fill(CGRect(x: 270, y: 120, width: 100, height: 120))
        }
        let r = try VisualAnalysis.analyze(png: png)
        #expect(r.letterbox == 0)
        #expect(r.layoutScore > 0.7)
    }

    @Test("full-bleed gradient is not flagged as letterbox")
    func gradientNotLetterbox() throws {
        let png = tempPNG("gradient.png") { ctx in
            for y in 0..<800 {
                let t = CGFloat(y) / 800
                ctx.setFillColor(CGColor(red: 0.05 + t * 0.5, green: 0.3, blue: 0.8, alpha: 1))
                ctx.fill(CGRect(x: 0, y: y, width: 400, height: 1))
            }
        }
        let r = try VisualAnalysis.analyze(png: png)
        #expect(r.letterbox == 0)
    }

    @Test("vertical letterbox is detected")
    func verticalLetterbox() throws {
        let png = tempPNG("letterboxed-v.png") { ctx in
            ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 800))
            ctx.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 200, width: 400, height: 400))
        }
        let r = try VisualAnalysis.analyze(png: png)
        #expect(r.letterbox >= 0.2)
        #expect(r.layoutScore < 0.65)
    }

    @Test("horizontal letterbox is detected")
    func horizontalLetterbox() throws {
        let png = tempPNG("letterboxed-h.png") { ctx in
            ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 800))
            ctx.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1))
            ctx.fill(CGRect(x: 100, y: 0, width: 200, height: 800))
        }
        let r = try VisualAnalysis.analyze(png: png)
        #expect(r.letterbox >= 0.2)
        #expect(r.layoutScore < 0.65)
    }
}
