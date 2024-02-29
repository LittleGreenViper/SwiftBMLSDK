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

import MapKit
import RVS_Generic_Swift_Toolbox
import RVS_UIKit_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Map Results Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_MapResultsViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var mapView: MKMapView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController {
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* ################################################################## */
    /**
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        
        guard let allCoords = prefs.searchResults?.meetings.allCoords,
              !allCoords.isEmpty
        else { return }
        
        guard let mapRegion = MKCoordinateRegion(coordinates: allCoords),
              let newRegion = mapView?.regionThatFits(mapRegion) else { return }
        
        mapView?.region = newRegion
    }
}

/* ###################################################################################################################################### */
// MARK: - Region Extension For Transforming Array of Coordinates to A Region -
/* ###################################################################################################################################### */
/**
 Inspired by [this GitHub gist](https://gist.github.com/dionc/46f7e7ee9db7dbd7bddec56bd5418ca6).
 */
extension MKCoordinateRegion {
    /* ################################################################## */
    /**
     */
    private typealias _Transform = (CLLocationCoordinate2D) -> (CLLocationCoordinate2D)
    
    /* ################################################################## */
    /**
     Latitude -180...180 -> 0...360
     */
    private static func _transform(c inCoords: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard 0 > inCoords.longitude else { return inCoords }

        return CLLocationCoordinate2D(latitude: inCoords.latitude, longitude: 360 + inCoords.longitude)
    }
    
    /* ################################################################## */
    /**
     Latitude 0...360 -> -180...180
     */
    private static func _inverseTransform(c inCoords: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard 180 < inCoords.longitude else { return inCoords }

        return CLLocationCoordinate2D(latitude: inCoords.latitude, longitude: -360 + inCoords.longitude)
    }
    
    /* ################################################################## */
    /**
     */
    private static func _region(for inCoordinateArray: [CLLocationCoordinate2D], transform inTransform: _Transform, inverseTransform inInverseTransform: _Transform) -> MKCoordinateRegion? {
        // handle empty array
        guard !inCoordinateArray.isEmpty else { return nil }
        // handle single coordinate
        guard 1 < inCoordinateArray.count else {
            return MKCoordinateRegion(center: inCoordinateArray[0], span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }
        
        let transformed = inCoordinateArray.map(inTransform)
        
        // find the span
        guard let minLat = transformed.min(by: { $0.latitude < $1.latitude })?.latitude,
              let maxLat = transformed.max(by: { $0.latitude < $1.latitude })?.latitude,
              let minLon = transformed.min(by: { $0.longitude < $1.longitude })?.longitude,
              let maxLon = transformed.max(by: { $0.longitude < $1.longitude })?.longitude
        else { return nil }
        
        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        
        // find the center of the span
        let center = inInverseTransform(CLLocationCoordinate2D(latitude: (maxLat - span.latitudeDelta / 2), longitude: maxLon - span.longitudeDelta / 2))
        
        return MKCoordinateRegion(center: center, span: span)
    }

    /* ################################################################## */
    /**
     */
    public init?(coordinates inCoordinateArray: [CLLocationCoordinate2D]) {
        // first create a region centered around the prime meridian
        let primeRegion = MKCoordinateRegion._region(for: inCoordinateArray, transform: { $0 }, inverseTransform: { $0 })
        // next create a region centered around the 180th meridian
        let transformedRegion = MKCoordinateRegion._region(for: inCoordinateArray, transform: MKCoordinateRegion._transform, inverseTransform: MKCoordinateRegion._inverseTransform)
        // return the region that has the smallest longitude delta
        if let a = primeRegion,
           let b = transformedRegion,
           let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        } else if let a = primeRegion {
            self = a
        } else if let b = transformedRegion {
            self = b
        } else {
            return nil
        }
    }
}
