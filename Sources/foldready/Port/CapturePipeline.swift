import Foundation

/// Captures one simulator launch and its provenance. This does not exercise Duo poses.
enum CapturePipeline {

    static func capture(root: String, appName: String, shotsDir: String) -> String? {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: root) else { return nil }
        let proj = entries.first { $0.hasSuffix(".xcodeproj") }
        let ws = entries.first { $0.hasSuffix(".xcworkspace") }
        guard proj != nil || ws != nil else { return nil }

        guard let runtime = pickRuntime(),
              let target = deviceFor(runtime: runtime) else { return nil }

        let device = target.id
        let captureDir = (shotsDir as NSString).appendingPathComponent(UUID().uuidString)
        boot(device)

        let derived = (root as NSString).appendingPathComponent(".foldready-derived")
        try? fm.removeItem(atPath: derived)

        var buildArgs: [String]
        if let ws {
            buildArgs = ["-workspace", (root as NSString).appendingPathComponent(ws), "-scheme", appName, "-destination", "id=\(device)",
                         "-derivedDataPath", derived, "-configuration", "Debug", "CODE_SIGNING_ALLOWED=NO", "build"]
        } else {
            buildArgs = ["-project", (root as NSString).appendingPathComponent(proj!), "-scheme", appName, "-destination", "id=\(device)",
                         "-derivedDataPath", derived, "-configuration", "Debug", "CODE_SIGNING_ALLOWED=NO", "build"]
        }
        guard run("/usr/bin/xcodebuild", buildArgs, timeout: 600) else { return nil }

        guard let app = findApp(in: derived) else { return nil }
        let infoPath = (app as NSString).appendingPathComponent("Info.plist")
        guard let data = fm.contents(atPath: infoPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any],
              let bundle = dict["CFBundleIdentifier"] as? String else { return nil }

        guard run("/usr/bin/xcrun", ["simctl", "install", device, app], timeout: 120),
              run("/usr/bin/xcrun", ["simctl", "launch", device, bundle], timeout: 60) else { return nil }
        sleep(4)

        try? fm.createDirectory(atPath: captureDir, withIntermediateDirectories: true)
        let shot = (captureDir as NSString).appendingPathComponent("portrait.png")
        guard run("/usr/bin/xcrun", ["simctl", "io", device, "screenshot", shot], timeout: 60) else { return nil }
        let metadata: [String: Any] = [
            "device": target.name, "runtime": runtime,
            "linked_sdk": dict["DTSDKName"] as? String ?? "unknown",
            "bundle_id": bundle, "screenshots": ["portrait.png"],
            "duo_runtime_verified": false,
            "scope": "Single launch screenshot; poses, journeys and transitions were not exercised."
        ]
        guard let json = try? JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]),
              (try? json.write(to: URL(fileURLWithPath: captureDir).appendingPathComponent("capture.json"))) != nil
        else { return nil }
        return captureDir
    }

    // MARK: - Tooling

    private static func pickRuntime() -> String? {
        guard let out = shell("/usr/bin/xcrun", ["simctl", "list", "runtimes", "-j"]),
              let data = out.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let runtimes = json["runtimes"] as? [[String: Any]] else { return nil }
        let ios = runtimes.filter { ($0["platform"] as? String) == "iOS" }
            .compactMap { $0["identifier"] as? String }
        return ios.sorted { $0.compare($1, options: .numeric) == .orderedAscending }.last
    }

    private static func deviceFor(runtime: String) -> (id: String, name: String)? {
        // Prefer the widest iPhone, then fall back to any iPhone type.
        let hints = ["iPhone Duo", "iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 17 Pro", "iPhone 16 Pro", "iPhone 15 Pro Max"]
        guard let types = deviceTypes() else { return nil }
        let names = types.compactMap { $0["name"] as? String }
        for hint in hints {
            if names.contains(hint), let created = createDevice(type: hint, runtime: runtime) { return (created, hint) }
        }
        // fallback: first iPhone-ish type
        for name in names where name.contains("iPhone") {
            if let created = createDevice(type: name, runtime: runtime) { return (created, name) }
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
        let sem = DispatchSemaphore(value: 0)
        p.terminationHandler = { _ in sem.signal() }
        // Drain output while the build runs so a full pipe cannot deadlock it.
        pipe.fileHandleForReading.readabilityHandler = { handle in _ = handle.availableData }
        defer { pipe.fileHandleForReading.readabilityHandler = nil }
        do { try p.run() } catch { return false }
        if sem.wait(timeout: .now() + timeout) == .timedOut {
            if p.isRunning { p.terminate() }
            return false
        }
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
