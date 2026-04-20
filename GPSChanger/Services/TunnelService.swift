import Foundation
import Observation

@Observable
@MainActor
final class TunnelService {
    enum Status {
        case unknown
        case running
        case notRunning
        case starting
    }

    var status: Status = .unknown
    var errorMessage: String?

    private let tunneldPort = 49151

    // MARK: - Binary Discovery

    static func findBinary() -> String? {
        let home = NSHomeDirectory()
        let pythonVersions = ["3.9", "3.10", "3.11", "3.12", "3.13", "3.14"]
        let candidates = pythonVersions.map { "\(home)/Library/Python/\($0)/bin/pymobiledevice3" }
            + ["/opt/homebrew/bin/pymobiledevice3", "/usr/local/bin/pymobiledevice3"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    var isReady: Bool { status == .running }
    var isStarting: Bool { status == .starting }
    var isBinaryMissing: Bool { TunnelService.findBinary() == nil }

    // MARK: - Status Check

    func checkStatus() async {
        guard TunnelService.findBinary() != nil else {
            status = .notRunning
            return
        }
        // nc -z tries to connect to the port; exits 0 if open, 1 if closed.
        // No sudo needed — works regardless of process owner.
        do {
            _ = try await runShell(
                executable: "/usr/bin/nc",
                arguments: ["-z", "-G", "1", "127.0.0.1", "\(tunneldPort)"]
            )
            status = .running
        } catch {
            status = .notRunning
        }
    }

    // MARK: - Start Tunneld

    func startTunneld() async {
        guard status != .starting else { return }
        status = .starting
        errorMessage = nil

        guard let pmd3 = TunnelService.findBinary() else {
            errorMessage = "pymobiledevice3 not found.\nRun in Terminal: pip3 install pymobiledevice3"
            status = .notRunning
            return
        }

        // Build shell command:
        // HOME must be set to user home so Python finds the packages even when running as root
        let home = NSHomeDirectory()
        let shellCmd = "HOME='\(home)' '\(pmd3)' remote tunneld -d"
        let appleScript = "do shell script \"\(shellCmd)\" with administrator privileges"

        do {
            _ = try await runShell(
                executable: "/usr/bin/osascript",
                arguments: ["-e", appleScript]
            )
            
            // Give tunneld a moment to bind the port (up to 5 seconds)
            for _ in 0..<5 {
                try? await Task.sleep(for: .seconds(1))
                await checkStatus()
                if status == .running { return }
            }
            if status != .running {
                errorMessage = "Tunneld started but port \(tunneldPort) not yet open. Try again."
            }
        } catch let error as ShellError {
            status = .notRunning
            // osascript exit 1 = user cancelled the password dialog
            if case .processFailed(let code, _) = error, code == 1 {
                errorMessage = "Cancelled — admin password required to start the tunnel."
            } else {
                errorMessage = "Failed to start tunnel: \(error.localizedDescription)"
            }
        } catch {
            status = .notRunning
            errorMessage = "Failed to start tunnel: \(error.localizedDescription)"
        }
    }
}
