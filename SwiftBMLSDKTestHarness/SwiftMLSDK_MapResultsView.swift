/*
 © Copyright 2024, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import SwiftUI
import MapKit
import CoreLocation

/* ###################################################################################################################################### */
// MARK: - Text Map Search Selection View -
/* ###################################################################################################################################### */
/**
 */
struct SwiftMLSDK_MapResultsView: View {
    /* ################################################################################################################################## */
    // MARK: A Basic Map Location For Markers
    /* ################################################################################################################################## */
    /**
     */
    struct MeetingLocation: Codable, Equatable, Identifiable {
        let id: UUID
        var latitude: Double
        var longitude: Double
    }

    /* ################################################################################################################################## */
    // MARK: Handles Storage of the Map Coordinate Region
    /* ################################################################################################################################## */
    /**
     */
    class MapViewModel: ObservableObject {
        /* ################################################# */
        /**
         This gives us a state reference for the map camera position.
         */
        @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(center: .naws, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(0.0125), longitudeDelta: CLLocationDegrees(0.0125))))
    }

    /* ################################################# */
    /**
     */
    @State private var _locations = [MeetingLocation]()
    
    /* ################################################# */
    /**
     */
    @ObservedObject var mapModel = MapViewModel()

    /* ################################################# */
    /**
     */
    var body: some View {
        VStack {
            MapReader { proxy in
                Map(position: $mapModel.cameraPosition, interactionModes: [.pan,.zoom]) {
                    Marker("NAWS", systemImage: "diamond.fill", coordinate: .naws)
                    ForEach(_locations) { location in
                        Marker("Tap Location", systemImage: "hand.tap", coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    }
                }
                .mapStyle(
                    .hybrid(elevation: .realistic)
                )
                .mapControls {
                    MapScaleView()
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        let newLocation = MeetingLocation(id: UUID(), latitude: coordinate.latitude, longitude: coordinate.longitude)
                        _locations.append(newLocation)
                    }
                }
            }
        }
    }
}

/* ##################################################### */
/**
 Just the preview generator.
 */
struct SwiftMLSDK_MapResultsView_Previews: PreviewProvider {
    /* ############################################# */
    /**
     */
    static var previews: some View {
        SwiftMLSDK_MapResultsView()
    }
}
