import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var deviceService = DeviceService()
    @State private var locationService = LocationService()
    @State private var tunnelService = TunnelService()
    @State private var selectedDevice: iOSDevice?
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationSplitView {
            DeviceListView(
                deviceService: deviceService,
                selectedDevice: $selectedDevice
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
        .onAppear {
            deviceService.startAutoScan()
            Task { await tunnelService.checkStatus() }
        }
        .onDisappear {
            deviceService.stopAutoScan()
        }
    }
}
