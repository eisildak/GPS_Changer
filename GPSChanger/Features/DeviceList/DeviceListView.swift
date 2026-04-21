import SwiftUI

struct DeviceListView: View {
    var deviceService: DeviceService
    @Binding var selectedDevice: iOSDevice?

    var body: some View {
        VStack(spacing: 0) {
            List(deviceService.devices, selection: $selectedDevice) { device in
                DeviceRow(device: device)
                    .tag(device)
            }
            .listStyle(.sidebar)
            .onChange(of: deviceService.devices) { _, newDevices in
                // Auto-select when there's exactly one device and nothing is selected
                if selectedDevice == nil, let first = newDevices.first {
                    selectedDevice = first
                }
                // Clear selection if selected device disconnected
                if let selected = selectedDevice, !newDevices.contains(selected) {
                    selectedDevice = newDevices.first
                }
            }
            .overlay {
                if !deviceService.isScanning && deviceService.devices.isEmpty {
                    ContentUnavailableView(
                        "No Devices",
                        systemImage: "iphone.slash",
                        description: Text("Connect an iPhone via USB\nand enable Developer Mode")
                    )
                }
            }

            Divider()

            HStack(spacing: 8) {
                if deviceService.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(deviceService.devices.isEmpty ? .orange : .green)
                }

                Text(deviceService.isScanning ? "Scanning…" : "\(deviceService.devices.count) device(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Task { await deviceService.refreshDevices() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(deviceService.isScanning)
                .help("Refresh")
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
        }
        .navigationTitle("iGPS Changer")
    }
}

private struct DeviceRow: View {
    let device: iOSDevice

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: device.systemImageName)
                .foregroundStyle(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("iOS \(device.osVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !device.supportsDevicectl {
                        Text("· Requires iOS 17+")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "cable.connector")
                .foregroundStyle(.green)
                .font(.caption2)
        }
        .padding(.vertical, 3)
    }
}
