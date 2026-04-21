import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var deviceService = DeviceService()
    @State private var locationService = LocationService()
    @State private var tunnelService = TunnelService()
    @State private var savedLocationsService = SavedLocationsService()
    @State private var selectedDevice: iOSDevice?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showInfo = false

    var body: some View {
        NavigationSplitView {
            SavedLocationsView(
                savedLocationsService: savedLocationsService,
                selectedCoordinate: $selectedCoordinate
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        } detail: {
            VStack(spacing: 0) {
                MapContentView(selectedCoordinate: $selectedCoordinate)

                Divider()

                LocationControlView(
                    locationService: locationService,
                    tunnelService: tunnelService,
                    selectedDevice: selectedDevice,
                    selectedCoordinate: $selectedCoordinate
                )
                .background(.bar)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                devicePickerMenu
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("About iGPS Changer")
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
        .onAppear {
            deviceService.startAutoScan()
            Task { await tunnelService.checkStatus() }
        }
        .onDisappear {
            deviceService.stopAutoScan()
        }
        .onChange(of: deviceService.devices) { _, newDevices in
            if selectedDevice == nil, let first = newDevices.first {
                selectedDevice = first
            }
            if let selected = selectedDevice, !newDevices.contains(selected) {
                selectedDevice = newDevices.first
            }
        }
    }

    private var devicePickerMenu: some View {
        Menu {
            if deviceService.devices.isEmpty {
                Label("No devices connected", systemImage: "iphone.slash")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(deviceService.devices) { device in
                    Button {
                        selectedDevice = device
                    } label: {
                        if selectedDevice?.id == device.id {
                            Label(device.name, systemImage: "checkmark")
                        } else {
                            Label(device.name, systemImage: device.systemImageName)
                        }
                    }
                }
            }
            Divider()
            Button {
                Task { await deviceService.refreshDevices() }
            } label: {
                Label("Refresh Devices", systemImage: "arrow.clockwise")
            }
            .disabled(deviceService.isScanning)
        } label: {
            HStack(spacing: 5) {
                if deviceService.isScanning {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: selectedDevice?.systemImageName ?? "iphone.slash")
                        .foregroundStyle(selectedDevice != nil ? .primary : .secondary)
                }
                Text(selectedDevice?.name ?? "No Device")
                    .fontWeight(.medium)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .fixedSize()
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Info Sheet

private struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text("iGPS Changer")
                    .font(.title.bold())
            }

            // Description
            VStack(alignment: .leading, spacing: 10) {
                infoRow(icon: "iphone.and.arrow.forward", text: "This app lets you mock (spoof) the GPS location of your iOS device.")
                infoRow(icon: "cable.connector", text: "Your iOS device must be connected to your Mac via USB cable.")
                infoRow(icon: "iphone", text: "The connected device will appear in the device picker at the top center of the window.")
                infoRow(icon: "iphone.gen3", text: "If you have multiple devices connected, select the one you want to spoof from the picker.")
                infoRow(icon: "mappin.and.ellipse", text: "You can save pinned locations to the sidebar on the left for quick access.")
            }
            .padding(.horizontal, 4)

            Divider()

            // Footer
            VStack(spacing: 4) {
                Text("Developed by Erol Isildak")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("erolisildakk@gmail.com") {
                    openURL(URL(string: "mailto:erolisildakk@gmail.com")!)
                }
                .buttonStyle(.plain)
                .font(.footnote)
                .foregroundStyle(.blue)
            }

            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
        .padding(28)
        .frame(width: 400)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
