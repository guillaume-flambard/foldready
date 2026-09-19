import Foundation

/// Test paths removed when the test process exits.
///
/// `FileManager.default.temporaryDirectory` is not emptied between runs, so a
/// directory a test creates and never deletes stays on disk for the life of the
/// machine. Every helper here registers what it creates, so one run leaves the
/// system temporary directory as it found it.
private final class TemporaryPathRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var paths: [URL] = []

    func add(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        paths.append(url)
    }

    func drain() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        let all = paths
        paths.removeAll()
        return all
    }
}

private let registry = TemporaryPathRegistry()

private func removeTemporaryPaths() {
    for path in registry.drain() {
        try? FileManager.default.removeItem(at: path)
    }
}

enum TestTemporaryDirectory {
    /// Installs the exit hook once, before the first registration.
    private static let removalAtExit: Void = { atexit(removeTemporaryPaths) }()

    /// A fresh directory under the system temporary directory, removed at exit.
    static func make(_ name: String) -> URL {
        _ = removalAtExit
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fr-\(name)-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return register(url)
    }

    /// Registers a path the caller created itself, such as a standalone file.
    @discardableResult
    static func register(_ url: URL) -> URL {
        _ = removalAtExit
        registry.add(url)
        return url
    }
}
