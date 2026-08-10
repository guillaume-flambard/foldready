import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func makeContext(w: Int, h: Int) -> CGContext {
    return CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func write(_ img: CGImage, to name: String) {
    let url = URL(fileURLWithPath: "\(outDir)/\(name)")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("no destination")
    }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

let W = 400, H = 800

// 1. Realistic full app screen: light background, content touching all four edges
//    (header, footer, side content). Center background is the light gray.
let full = makeContext(w: W, h: H)
full.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)) // #F0F0F5
full.fill(CGRect(x: 0, y: 0, width: W, height: H))
full.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1))  // dark header
full.fill(CGRect(x: 0, y: 0, width: W, height: 70))
full.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1))  // dark footer
full.fill(CGRect(x: 0, y: H - 60, width: W, height: 60))
full.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1))    // content blocks
full.fill(CGRect(x: 30, y: 120, width: 90, height: 120))
full.fill(CGRect(x: 150, y: 120, width: 90, height: 120))
full.fill(CGRect(x: 270, y: 120, width: 100, height: 120))
full.fill(CGRect(x: 30, y: 300, width: W - 60, height: 60))
write(full.makeImage()!, to: "full.png")

// 2. Full-bleed vertical gradient: torture test, must NOT be flagged as letterbox.
let grad = makeContext(w: W, h: H)
for y in 0..<H {
    let t = CGFloat(y) / CGFloat(H)
    let color = CGColor(red: 0.05 + t * 0.5, green: 0.3, blue: 0.8, alpha: 1)
    grad.setFillColor(color)
    grad.fill(CGRect(x: 0, y: y, width: W, height: 1))
}
write(grad.makeImage()!, to: "gradient.png")

// 3. Letterboxed vertically: near-black frame, white content band centered (50% height).
let boxedV = makeContext(w: W, h: H)
boxedV.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
boxedV.fill(CGRect(x: 0, y: 0, width: W, height: H))
boxedV.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1))
boxedV.fill(CGRect(x: 0, y: H / 4, width: W, height: H / 2))
write(boxedV.makeImage()!, to: "letterboxed-v.png")

// 4. Letterboxed horizontally: near-black frame, content column centered (25% width).
let boxedH = makeContext(w: W, h: H)
boxedH.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
boxedH.fill(CGRect(x: 0, y: 0, width: W, height: H))
boxedH.setFillColor(CGColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1))
boxedH.fill(CGRect(x: W / 4, y: 0, width: W / 2, height: H))
write(boxedH.makeImage()!, to: "letterboxed-h.png")

print("wrote 4 fixtures to \(outDir)")
