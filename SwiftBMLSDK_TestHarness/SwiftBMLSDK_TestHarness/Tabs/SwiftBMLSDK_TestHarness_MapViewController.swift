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
import UIKit
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Search Map View Controller -
/* ###################################################################################################################################### */
/**
 This manages the Search Map View.
 */
class SwiftBMLSDK_TestHarness_MapViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     */
    var center = CLLocationCoordinate2D()
    
    /* ################################################################## */
    /**
     */
    var radius = CLLocationDistance(0)
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var mapView: MKMapView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var circleOverlayView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController {
    /* ################################################################## */
    /**
     This sets the map to a region around the user's current location.
     */
    func setMapCenter() {
        let regionSizeInMeters = CLLocationDistance(radius * 2)
        
        guard let coordinateRegion = mapView?.regionThatFits(MKCoordinateRegion(center: center, latitudinalMeters: regionSizeInMeters, longitudinalMeters: regionSizeInMeters)) else { return }
        
        let oldDelegate = mapView?.delegate
        mapView?.delegate = nil
        mapView?.setRegion(coordinateRegion, animated: false)
        mapView?.delegate = oldDelegate
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setMapCenter()
    }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController: MKMapViewDelegate {
    
}
