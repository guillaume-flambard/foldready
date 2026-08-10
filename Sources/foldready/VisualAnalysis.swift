import Foundation
import CoreGraphics
import ImageIO

struct VisualResult: Sendable {
    let file: String
    let width: Int
    let height: Int
    let letterbox: Double
    let contentCoverage: Double
    let layoutScore: Double

    var isPortrait: Bool { height > width }
}

enum VisualError: Error, CustomStringConvertible {
    case cannotLoad(String)
    var description: String {
        switch self {
        case .cannotLoad(let p): return "cannot decode image: \(p)"
        }
    }
}

struct PixelRow {
    let r: Double
    let g: Double
    let b: Double
    let uniform: Bool
}

enum VisualAnalysis {

    /// Detects letterboxing: uniform margin bands at the edges whose color
    /// differs from the center content background. A phone app rendered on a
    /// wider canvas shows exactly that (black bars around a portrait column),
    /// while an app that reflows fills the frame edge to edge.
    static func analyze(png path: String) throws -> VisualResult {
        let url = URL(fileURLWithPath: path)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw VisualError.cannotLoad(path)
        }

        let w = img.width
        let h = img.height
        guard w > 0, h > 0 else { throw VisualError.cannotLoad(path) }

        var px = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &px,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw VisualError.cannotLoad(path) }
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Row and column statistics.
        let rows = rowStats(px, w: w, h: h)
        let cols = colStats(px, w: w, h: h)

        // Center background: average color of the inner 60% region.
        let centerBg = centerBackground(px, w: w, h: h)

        func isBar(_ c: (r: Double, g: Double, b: Double)) -> Bool {
            let lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
            let nearFrame = lum < 30 || lum > 225
            return nearFrame && max(abs(c.r - centerBg.r), abs(c.g - centerBg.g), abs(c.b - centerBg.b)) > 60
        }

        let minBandH = Double(h) * 0.03
        let minBandW = Double(w) * 0.03

        func isBarBand(_ row: PixelRow) -> Bool {
            row.uniform && isBar((row.r, row.g, row.b))
        }
        let top = leadingBand(rows, isBarBand) >= Int(minBandH) ? leadingBand(rows, isBarBand) : 0
        let bottom = trailingBand(rows, isBarBand) >= Int(minBandH) ? trailingBand(rows, isBarBand) : 0
        let left = leadingBand(cols, isBarBand) >= Int(minBandW) ? leadingBand(cols, isBarBand) : 0
        let right = trailingBand(cols, isBarBand) >= Int(minBandW) ? trailingBand(cols, isBarBand) : 0

        let letterbox = (Double(top) + Double(bottom)) / Double(h) * 0.5
            + (Double(left) + Double(right)) / Double(w) * 0.5

        // Coverage: fraction of pixels that are not the center background.
        var contentPixels = 0
        for i in 0..<(w * h) {
            let r = Double(px[i * 4]), g = Double(px[i * 4 + 1]), b = Double(px[i * 4 + 2])
            if max(abs(r - centerBg.r), abs(g - centerBg.g), abs(b - centerBg.b)) > 30 {
                contentPixels += 1
            }
        }
        let coverage = Double(contentPixels) / Double(w * h)

        let layoutScore = max(0, 1 - letterbox * 1.5) * (0.7 + 0.3 * coverage)

        return VisualResult(
            file: (path as NSString).lastPathComponent,
            width: w,
            height: h,
            letterbox: letterbox,
            contentCoverage: coverage,
            layoutScore: layoutScore
        )
    }

    static func averageScore(_ results: [VisualResult]) -> Double {
        guard !results.isEmpty else { return 0.5 }
        return results.map(\.layoutScore).reduce(0, +) / Double(results.count)
    }

    // MARK: - Pixel helpers

    private static func rowStats(_ px: [UInt8], w: Int, h: Int) -> [PixelRow] {
        var out = [PixelRow]()
        out.reserveCapacity(h)
        for y in 0..<h {
            var sr = 0.0, sg = 0.0, sb = 0.0
            var s2r = 0.0, s2g = 0.0, s2b = 0.0
            for x in 0..<w {
                let i = (y * w + x) * 4
                let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
                sr += r; sg += g; sb += b
                s2r += r * r; s2g += g * g; s2b += b * b
            }
            let n = Double(w)
            let vr = s2r / n - (sr / n) * (sr / n)
            let vg = s2g / n - (sg / n) * (sg / n)
            let vb = s2b / n - (sb / n) * (sb / n)
            out.append(PixelRow(r: sr / n, g: sg / n, b: sb / n,
                uniform: sqrt(vr) < 6 && sqrt(vg) < 6 && sqrt(vb) < 6))
        }
        return out
    }

    private static func colStats(_ px: [UInt8], w: Int, h: Int) -> [PixelRow] {
        var out = [PixelRow]()
        out.reserveCapacity(w)
        for x in 0..<w {
            var sr = 0.0, sg = 0.0, sb = 0.0
            var s2r = 0.0, s2g = 0.0, s2b = 0.0
            for y in 0..<h {
                let i = (y * w + x) * 4
                let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
                sr += r; sg += g; sb += b
                s2r += r * r; s2g += g * g; s2b += b * b
            }
            let n = Double(h)
            let vr = s2r / n - (sr / n) * (sr / n)
            let vg = s2g / n - (sg / n) * (sg / n)
            let vb = s2b / n - (sb / n) * (sb / n)
            out.append(PixelRow(r: sr / n, g: sg / n, b: sb / n,
                uniform: sqrt(vr) < 6 && sqrt(vg) < 6 && sqrt(vb) < 6))
        }
        return out
    }

    private static func centerBackground(_ px: [UInt8], w: Int, h: Int) -> (r: Double, g: Double, b: Double) {
        let x0 = w * 45 / 100, x1 = w * 55 / 100, y0 = h * 45 / 100, y1 = h * 55 / 100
        var sr = 0.0, sg = 0.0, sb = 0.0, n = 0.0
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * w + x) * 4
                sr += Double(px[i]); sg += Double(px[i + 1]); sb += Double(px[i + 2])
                n += 1
            }
        }
        return (sr / n, sg / n, sb / n)
    }

    private static func leadingBand(_ arr: [PixelRow], _ match: (PixelRow) -> Bool) -> Int {
        var count = 0
        for row in arr {
            if match(row) { count += 1 } else { break }
        }
        return count
    }

    private static func trailingBand(_ arr: [PixelRow], _ match: (PixelRow) -> Bool) -> Int {
        var count = 0
        for row in arr.reversed() {
            if match(row) { count += 1 } else { break }
        }
        return count
    }
}
