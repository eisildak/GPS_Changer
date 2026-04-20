import Foundation
import Observation

@Observable
@MainActor
final class DeviceService {
    var devices: [iOSDevice] = []
    var isScanning = false
    var errorMessage: String?

    private var scanTask: Task<Void, Never>?

    func startAutoScan() {
        scanTask?.cancel()
        scanTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshDevices()
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    func stopAutoScan() {
        scanTask?.cancel()
        scanTask = nil
    }

    func refreshDevices() async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        do {
            let tmpPath = (NSTemporaryDirectory() as NSString)
                .appendingPathComponent("gps_changer_\(UUID().uuidString).json")
            defer { try? FileManager.default.removeItem(atPath: tmpPath) }

            _ = try await runShell(arguments: [
                "devicectl", "list", "devices",
                "--json-output", tmpPath
            ])

            guard let data = FileManager.default.contents(atPath: tmpPath) else {
                devices = []
                return
            }

            devices = try parseDevices(from: data)
        } catch {
            errorMessage = error.localizedDescription
            devices = []
        }
    }

    private func parseDevices(from data: Data) throws -> [iOSDevice] {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"] as? [String: Any],
            let deviceList = result["devices"] as? [[String: Any]]
        else {
            return []
        }

        return deviceList.compactMap { raw -> iOSDevice? in
            let conn = raw["connectionProperties"] as? [String: Any]
            let transport = conn?["transportType"] as? String ?? ""
            guard transport == "wired" else { return nil }

            let props = raw["deviceProperties"] as? [String: Any]
            let hw = raw["hardwareProperties"] as? [String: Any]

            guard
                let udid = hw?["udid"] as? String,
                let name = props?["name"] as? String
            else { return nil }

            let platform = hw?["platform"] as? String ?? ""
            guard platform == "iOS" else { return nil }

            let osVersion = props?["osVersionNumber"] as? String ?? "0"
            let deviceType = hw?["deviceType"] as? String ?? "iPhone"

            return iOSDevice(
                id: udid,
                name: name,
                osVersion: osVersion,
                deviceType: deviceType,
                isWired: true
            )
        }
    }
}
