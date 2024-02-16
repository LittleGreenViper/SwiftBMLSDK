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

extension CLLocationCoordinate2D {
  static let centralPark = CLLocationCoordinate2D(latitude: 40.7826, longitude: -73.9656)
}

/* ###################################################################################################################################### */
// MARK: - Text Map Search Selection View -
/* ###################################################################################################################################### */
/**
 */
struct SwiftMLSDK_MapView: View {
    /* ################################################################################################################################## */
    // MARK: Handles Storage of the Map Coordinate Region
    /* ################################################################################################################################## */
    /**
     */
    class MapViewModel: ObservableObject {
        /* ################################################# */
        /**
         */
        @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(center: .centralPark, span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125)))
    }

    /* ################################################################################################################################## */
    // MARK: Used to Capture User Location
    /* ################################################################################################################################## */
    /**
     */
    class LocationCatcher: NSObject, CLLocationManagerDelegate {
        /* ############################################# */
        /**
         */
        private let _locationManager: CLLocationManager
        
        /* ################################################# */
        /**
         */
        @ObservedObject var mapModel = MapViewModel()

        /* ############################################# */
        /**
         */
        override init() {
            _locationManager = CLLocationManager()
            super.init()
            _locationManager.delegate = self
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
        /* ############################################# */
        /**
         */
        func startUpdating() {
            _locationManager.requestWhenInUseAuthorization()
            _locationManager.startUpdatingLocation()
        }
        
        /* ############################################# */
        /**
         */
        func stopUpdating() {
            _locationManager.stopUpdatingLocation()
        }
        
        /* ############################################# */
        /**
         */
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            stopUpdating()
            guard let lastLocation = locations.last,
                  let span = mapModel.cameraPosition.region?.span
            else { return }
            mapModel.cameraPosition = .region(MKCoordinateRegion(center: lastLocation.coordinate, span: span))
            print(#function, lastLocation)
        }
    }

    /* ################################################# */
    /**
     */
    private let _locationCatcher: LocationCatcher

    /* ################################################# */
    /**
     */
    @ObservedObject var mapModel = MapViewModel()

    /* ################################################# */
    /**
     */
    var body: some View {
        VStack {
            Map(position: $mapModel.cameraPosition, interactionModes: [.pan,.zoom]) {
                Marker("Central Park", systemImage: "diamond.fill", coordinate: .centralPark)
            }
            .mapStyle(
                .hybrid(elevation: .realistic)
            )
            .mapControls {
                MapScaleView()
            }
            .onAppear {
                _locationCatcher.startUpdating()
            }
        }
    }
    
    /* ################################################# */
    /**
     */
    init() {
        _locationCatcher = LocationCatcher()
        _locationCatcher.mapModel = mapModel
    }
}

/* ##################################################### */
/**
 Just the preview generator.
 */
struct MyView_Previews: PreviewProvider {
    /* ############################################# */
    /**
     */
    static var previews: some View {
        SwiftMLSDK_MapView()
    }
}
