import SwiftUI
import MapKit
import CoreLocation

struct MapContentView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let coord = selectedCoordinate {
                    Annotation("Target", coordinate: coord, anchor: .bottom) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(.red.opacity(0.18))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.red)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
            .mapControls {
                MapCompass()
                MapZoomStepper()
                MapScaleView()
            }
            // Use simultaneousGesture so Map's own pan/zoom gestures still work
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCoordinate = coordinate
                        }
                    }
            )
        }
    }

    func moveTo(coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }
}
