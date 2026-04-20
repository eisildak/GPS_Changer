import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationService {
    var isSending = false
    var isActive = false          // true while a mock location process is running
    var statusMessage: StatusMessage?

    enum StatusMessage {
        case success(String)
        case error(String)

        var text: String {
            switch self {
            case .success(let msg): return msg
            case .error(let msg): return msg
            }
        }

        var isError: Bool {
            if case .error = self { return true }
            return false
        }
    }

    // Holds the long-running simulate-location process
    private var mockProcess: Process?

    func setLocation(device: iOSDevice, coordinate: CLLocationCoordinate2D) async {
        isSending = true
        statusMessage = nil
        defer { isSending = false }

        guard let pmd3 = TunnelService.findBinary() else {
            statusMessage = .error("pymobiledevice3 not found. Run: pip3 install pymobiledevice3")
            return
        }

        // Kill any existing mock process first
        stopMockProcess()

        do {
            // simulate-location set is long-running: it holds the mock while alive.
            // We start it without waiting so the UI stays responsive.
            let process = try startShell(
                executable: pmd3,
                arguments: [
                    "developer", "dvt", "simulate-location", "set",
                    "--",
                    String(format: "%.7f", coordinate.latitude),
                    String(format: "%.7f", coordinate.longitude)
                ]
            )
            mockProcess = process
            isActive = true
            statusMessage = .success(
                "Location set: \(String(format: "%.5f", coordinate.latitude)), \(String(format: "%.5f", coordinate.longitude))"
            )
        } catch {
            isActive = false
            statusMessage = .error(buildErrorMessage(error))
        }
    }

    func clearLocation(device: iOSDevice) async {
        isSending = true
        statusMessage = nil
        defer { isSending = false }

        // Terminate the long-running mock process — this stops the simulation
        stopMockProcess()

        // Also send an explicit clear to reset the device immediately
        if let pmd3 = TunnelService.findBinary() {
            _ = try? await runShell(
                executable: pmd3,
                arguments: ["developer", "dvt", "simulate-location", "clear"]
            )
        }

        isActive = false
        statusMessage = .success("Location cleared — device is using real GPS")
    }

    private func stopMockProcess() {
        guard let process = mockProcess, process.isRunning else {
            mockProcess = nil
            return
        }
        process.terminate()
        mockProcess = nil
    }

    private func buildErrorMessage(_ error: Error) -> String {
        if let shellError = error as? ShellError,
           case .processFailed(_, let stderr) = shellError {
            if stderr.contains("Unable to connect to Tunneld") || stderr.contains("tunneld") {
                return "Tunnel not running — click \"Start Tunnel\" first."
            }
            if stderr.contains("InvalidServiceError") || stderr.contains("DeviceNotFoundError") {
                return "Device error — ensure Developer Mode is enabled and device is trusted."
            }
            if !stderr.isEmpty { return stderr }
        }
        return error.localizedDescription
    }
}
