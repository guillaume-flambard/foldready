import Foundation

/// Builds an iOS app for the widest available simulator, launches it and captures
/// a screenshot, so the audit's "Captured layout" pixel check can score the real
/// rendering. Mirrors Scripts/capture.sh in-process.
enum CapturePipeline {

    static func capture(root: String, appName: String, shotsDir: String) -> String? {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: root) else { return nil }
        let proj = entries.first { $0.hasSuffix(".xcodeproj") }
        let ws = entries.first { $0.hasSuffix(".xcworkspace") }
        guard proj != nil || ws != nil else { return nil }

        guard let runtime = pickRuntime(),
              let device = deviceFor(runtime: runtime) else { return nil }

        boot(device)

        let derived = (root as NSString).appendingPathComponent(".foldready-derived")
        try? fm.removeItem(atPath: derived)

        var buildArgs: [String]
        if let ws {
            buildArgs = ["-workspace", ws, "-scheme", appName, "-destination", "id=\(device)",
                         "-derivedDataPath", derived, "-configuration", "Debug", "CODE_SIGNING_ALLOWED=NO", "build"]
        } else {
            buildArgs = ["-project", proj!, "-scheme", appName, "-destination", "id=\(device)",
                         "-derivedDataPath", derived, "-configuration", "Debug", "CODE_SIGNING_ALLOWED=NO", "build"]
        }
        guard run("/usr/bin/xcodebuild", buildArgs, timeout: 600) else { return nil }

        guard let app = findApp(in: derived) else { return nil }
        let infoPath = (app as NSString).appendingPathComponent("Info.plist")
        guard let data = fm.contents(atPath: infoPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any],
              let bundle = dict["CFBundleIdentifier"] as? String else { return nil }

        _ = run("/usr/bin/xcrun", ["simctl", "install", device, app], timeout: 120)
        _ = run("/usr/bin/xcrun", ["simctl", "launch", device, bundle], timeout: 60)
        sleep(4)

        try? fm.createDirectory(atPath: shotsDir, withIntermediateDirectories: true)
        let shot = (shotsDir as NSString).appendingPathComponent("portrait.png")
        guard run("/usr/bin/xcrun", ["simctl", "io", device, "screenshot", shot], timeout: 60) else { return nil }
        return shotsDir
    }

    // MARK: - Tooling

    private static func pickRuntime() -> String? {
        guard let out = shell("/usr/bin/xcrun", ["simctl", "list", "runtimes", "-j"]),
              let data = out.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let runtimes = json["runtimes"] as? [[String: Any]] else { return nil }
        let ios = runtimes.filter { ($0["platform"] as? String) == "iOS" }
            .compactMap { $0["identifier"] as? String }
        return ios.max() // prefer newest
    }

    private static func deviceFor(runtime: String) -> String? {
        // Prefer the widest iPhone, then fall back to any iPhone type.
        let hints = ["iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 17 Pro", "iPhone 16 Pro", "iPhone 15 Pro Max"]
        guard let types = deviceTypes() else { return nil }
        let names = types.compactMap { $0["name"] as? String }
        for hint in hints {
            if names.contains(hint), let created = createDevice(type: hint, runtime: runtime) { return created }
        }
        // fallback: first iPhone-ish type
        for name in names where name.contains("iPhone") {
            if let created = createDevice(type: name, runtime: runtime) { return created }
        }
        return nil
    }

    private static func deviceTypes() -> [[String: Any]]? {
        guard let out = shell("/usr/bin/xcrun", ["simctl", "list", "devicetypes", "-j"]),
              let data = out.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["devicetypes"] as? [[String: Any]] else { return nil }
        return list
    }

    private static func createDevice(type: String, runtime: String) -> String? {
        let name = "FoldReady-\(UUID().uuidString.prefix(6))"
        let args = ["simctl", "create", name, type, runtime]
        guard let out = shell("/usr/bin/xcrun", args) else { return nil }
        let udid = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return udid.isEmpty ? nil : udid
    }

    private static func boot(_ device: String) {
        _ = run("/usr/bin/xcrun", ["simctl", "boot", device], timeout: 60)
        _ = run("/usr/bin/xcrun", ["simctl", "bootstatus", device, "-b"], timeout: 120)
    }

    private static func findApp(in derived: String) -> String? {
        let fm = FileManager.default
        let products = (derived as NSString).appendingPathComponent("Build/Products")
        guard let en = fm.enumerator(atPath: products) else { return nil }
        while let rel = en.nextObject() as? String {
            if rel.hasSuffix(".app") {
                let url = URL(fileURLWithPath: rel)
                let parent = url.deletingLastPathComponent().lastPathComponent
                if parent.hasPrefix("Debug-") || parent == "Debug" || parent.contains("iphonesimulator") {
                    return (products as NSString).appendingPathComponent(rel)
                }
            }
        }
        return nil
    }

    // MARK: - Process helpers

    @discardableResult
    private static func run(_ path: String, _ args: [String], timeout: Double = 120) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do {
            try p.run()
        } catch { return false }
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if p.isRunning { p.terminate() }
            sem.signal()
        }
        sem.wait()
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    private static func shell(_ path: String, _ args: [String]) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
