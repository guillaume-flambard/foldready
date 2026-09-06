import Foundation

/// FoldReady release version, reported in the JSON result so a consumer can tell which
/// engine produced a score.
let foldreadyVersion = "0.2.0"

/// Version of the machine-readable result contract documented in `docs/result-contract.md`.
///
/// Bump when a field is removed, renamed, or changes meaning, or when scoring changes in
/// a way that invalidates committed baselines. Adding an optional field does not bump it.
let resultSchemaVersion = 1
