import Foundation

enum ContinuityCommand {
    static func run(_ arguments: [String]) -> Int32 {
        guard let script = Bundle.module.url(forResource: "runner", withExtension: "py") else {
            fputs("Missing bundled continuity runner.\n", stderr)
            return 1
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [script.path] + arguments
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            fputs("Cannot start continuity runner: \(error)\n", stderr)
            return 1
        }
    }
}
