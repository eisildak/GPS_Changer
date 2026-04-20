import Foundation
import MapKit
import Observation

@Observable
@MainActor
final class SearchService {
    var results: [SearchResult] = []
    var isSearching = false

    private var searchTask: Task<Void, Never>?

    func search(query: String, regionCenter: CLLocationCoordinate2D? = nil) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            clear()
            return
        }

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }

            self.isSearching = true
            defer { self.isSearching = false }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            if let center = regionCenter {
                request.region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
                )
            }

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                guard !Task.isCancelled else { return }
                self.results = response.mapItems.prefix(6).compactMap { item in
                    guard let location = item.placemark.location else { return nil }
                    return SearchResult(
                        name: item.name ?? "Unknown",
                        address: item.placemark.title ?? "",
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.results = []
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        results = []
    }
}
