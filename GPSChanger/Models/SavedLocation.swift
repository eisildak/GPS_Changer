import Foundation
import CoreLocation

struct SavedLocation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Observable
@MainActor
final class SavedLocationsService {
    var locations: [SavedLocation] = []

    private let key = "saved_locations"

    init() { load() }

    func add(name: String, coordinate: CLLocationCoordinate2D) {
        let location = SavedLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        locations.append(location)
        persist()
    }

    func delete(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
        persist()
    }

    func rename(_ location: SavedLocation, to name: String) {
        guard let idx = locations.firstIndex(where: { $0.id == location.id }) else { return }
        locations[idx].name = name
        persist()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data)
        else { return }
        locations = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(locations) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
