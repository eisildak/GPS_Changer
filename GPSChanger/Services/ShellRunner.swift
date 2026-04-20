import Foundation

enum ShellError: Error, LocalizedError {
    case executableNotFound(String)
    case processFailed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound(let path):
            return "Executable not found: \(path)"
        case .processFailed(let code, let stderr):
            return "Process failed (exit \(code)): \(stderr)"
        }
    }
}

/// Run a process, wait for it to exit, and return stdout. Throws on non-zero exit.
func runShell(executable: String = "/usr/bin/xcrun", arguments: [String]) async throws -> String {
    guard FileManager.default.isExecutableFile(atPath: executable) else {
        throw ShellError.executableNotFound(executable)
    }

    let executableURL = URL(filePath: executable)
    let args = arguments

    return try await Task.detached(priority: .userInitiated) { @Sendable in
        let process = Process()
        process.executableURL = executableURL
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw ShellError.processFailed(exitCode: process.terminationStatus, stderr: errStr)
        }

        return String(data: outData, encoding: .utf8) ?? ""
    }.value
}

/// Start a process in the background without waiting. Returns the running Process.
/// The caller is responsible for terminating the process when done.
func startShell(executable: String, arguments: [String]) throws -> Process {
    guard FileManager.default.isExecutableFile(atPath: executable) else {
        throw ShellError.executableNotFound(executable)
    }
    let process = Process()
    process.executableURL = URL(filePath: executable)
    process.arguments = arguments
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()
    return process
}
