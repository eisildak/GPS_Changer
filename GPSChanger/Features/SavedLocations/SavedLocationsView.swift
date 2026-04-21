import SwiftUI
import CoreLocation

struct SavedLocationsView: View {
    var savedLocationsService: SavedLocationsService
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var showSaveSheet = false
    @State private var editingLocation: SavedLocation?

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(savedLocationsService.locations) { location in
                    Button {
                        selectedCoordinate = location.coordinate
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(location.name)
                                .font(.callout)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Text(String(format: "%.5f, %.5f", location.latitude, location.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Rename") {
                            editingLocation = location
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            if let idx = savedLocationsService.locations.firstIndex(where: { $0.id == location.id }) {
                                savedLocationsService.delete(at: IndexSet([idx]))
                            }
                        }
                    }
                }
                .onDelete { savedLocationsService.delete(at: $0) }
            }
            .listStyle(.sidebar)
            .overlay {
                if savedLocationsService.locations.isEmpty {
                    ContentUnavailableView(
                        "No Saved Locations",
                        systemImage: "mappin.slash",
                        description: Text("Pin a location on the map\nthen tap Save Pin")
                    )
                }
            }

            Divider()

            Button {
                showSaveSheet = true
            } label: {
                Label("Save Pin", systemImage: "mappin.and.ellipse")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(selectedCoordinate == nil)
            .padding(10)
        }
        .navigationTitle("iGPS Changer")
        .sheet(isPresented: $showSaveSheet) {
            SaveLocationSheet(coordinate: selectedCoordinate) { name in
                if let coord = selectedCoordinate {
                    savedLocationsService.add(name: name, coordinate: coord)
                }
            }
        }
        .sheet(item: $editingLocation) { location in
            RenameLocationSheet(location: location) { newName in
                savedLocationsService.rename(location, to: newName)
            }
        }
    }
}

// MARK: - Save Sheet

private struct SaveLocationSheet: View {
    let coordinate: CLLocationCoordinate2D?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Save Location")
                .font(.headline)

            if let coord = coordinate {
                Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}

// MARK: - Rename Sheet

private struct RenameLocationSheet: View {
    let location: SavedLocation
    let onRename: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(location: SavedLocation, onRename: @escaping (String) -> Void) {
        self.location = location
        self.onRename = onRename
        self._name = State(initialValue: location.name)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Location")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onRename(trimmed)
        dismiss()
    }
}
