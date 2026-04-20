import Foundation

struct iOSDevice: Identifiable, Hashable, Sendable {
    let id: String          // UDID
    let name: String
    let osVersion: String
    let deviceType: String  // iPhone, iPad
    let isWired: Bool

    var osVersionMajor: Int {
        Int(osVersion.split(separator: ".").first ?? "0") ?? 0
    }

    var supportsDevicectl: Bool {
        osVersionMajor >= 17
    }

    var systemImageName: String {
        deviceType == "iPad" ? "ipad" : "iphone"
    }
}

struct SearchResult: Identifiable, Sendable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), name: String, address: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
}
