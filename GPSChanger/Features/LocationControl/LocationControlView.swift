import SwiftUI
import CoreLocation

struct LocationControlView: View {
    var locationService: LocationService
    var tunnelService: TunnelService
    var selectedDevice: iOSDevice?
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var searchService = SearchService()
    @State private var searchText = ""
    @State private var showResults = false

    private var canAct: Bool {
        selectedDevice != nil && !locationService.isSending && tunnelService.isReady
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tunnel status banner (only when not ready)
            if !tunnelService.isReady {
                tunnelBanner
                Divider()
            }

            HStack(alignment: .top, spacing: 16) {
                // Search + results
                VStack(alignment: .leading, spacing: 0) {
                    searchField
                        .frame(maxWidth: 360)

                    if showResults && !searchService.results.isEmpty {
                        searchResultsList
                            .frame(maxWidth: 360)
                    }
                }

                Spacer()

                // Coordinate info
                coordinateLabel

                Spacer()

                // Buttons
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Status bar
            if let status = locationService.statusMessage {
                statusBar(status)
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: 6) {
            if searchService.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            }

            TextField("Search address or place…", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        searchService.clear()
                        showResults = false
                    } else {
                        searchService.search(query: newValue)
                        showResults = true
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchService.clear()
                    showResults = false
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.separatorColor), lineWidth: 0.5)
        )
    }

    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchService.results) { result in
                Button {
                    selectedCoordinate = CLLocationCoordinate2D(
                        latitude: result.latitude,
                        longitude: result.longitude
                    )
                    searchText = result.name
                    showResults = false
                    searchService.clear()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(result.name)
                                .font(.callout)
                                .lineLimit(1)
                            Text(result.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                }
                .buttonStyle(.plain)
                .background(Color(.windowBackgroundColor).opacity(0.001))
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                if result.id != searchService.results.last?.id {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.top, 2)
    }

    private var coordinateLabel: some View {
        Group {
            if let coord = selectedCoordinate {
                VStack(alignment: .leading, spacing: 2) {
                    Label(
                        String(format: "%.5f", coord.latitude),
                        systemImage: "location.fill"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)

                    Text(String(format: "%.5f", coord.longitude))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)
                }
            } else {
                Text("Tap on map to pin a location")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                Task {
                    if let device = selectedDevice, let coord = selectedCoordinate {
                        await locationService.setLocation(device: device, coordinate: coord)
                    }
                }
            } label: {
                Label("Set Location", systemImage: "location.fill")
                    .frame(minWidth: 110)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAct || selectedCoordinate == nil)

            Button {
                Task {
                    if let device = selectedDevice {
                        await locationService.clearLocation(device: device)
                    }
                }
            } label: {
                if locationService.isSending {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Clear GPS", systemImage: locationService.isActive ? "location.slash.fill" : "location.slash")
                }
            }
            .buttonStyle(.bordered)
            .tint(locationService.isActive ? .red : nil)
            .disabled(!canAct)
        }
    }

    private var tunnelBanner: some View {
        HStack(spacing: 8) {
            if tunnelService.isStarting {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 14, height: 14)
                Text("Starting tunnel service…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if tunnelService.isBinaryMissing {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("pymobiledevice3 not installed — run:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("pip3 install pymobiledevice3")
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            } else {
                Image(systemName: "network.slash")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Tunnel service not running")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Start Tunnel") {
                    Task { await tunnelService.startTunneld() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)

                if let err = tunnelService.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
    }

    private func statusBar(_ status: LocationService.StatusMessage) -> some View {
        HStack(spacing: 6) {
            Image(systemName: status.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(status.isError ? .red : .green)
                .font(.caption)
            Text(status.text)
                .font(.caption)
                .foregroundStyle(status.isError ? .red : .green)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
