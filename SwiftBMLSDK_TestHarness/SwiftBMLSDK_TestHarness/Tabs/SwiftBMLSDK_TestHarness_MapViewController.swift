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
     The mask is fairly transparent.
     */
    private static let _maskAlphaValue: CGFloat = 0.25

    /* ################################################################## */
    /**
     The center circle will be twice this, in diameter, in display units.
     */
    private static let _centerCircleRadiusInDisplayUnits: CGFloat = 12
    
    /* ################################################################## */
    /**
     The center circle is slightly transparent.
     */
    private static let _centerAlphaValue: CGFloat = 0.5

    /* ################################################################## */
    /**
     */
    private weak var _circleLayer: CALayer?
    
    /* ################################################################## */
    /**
     */
    private weak var _centerDot: CALayer?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var mapView: MKMapView?
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController {
    /* ################################################################## */
    /**
     This sets the map to a region around the user's current location.
     */
    func setUpMap() {
        /* ############################################################## */
        /**
         */
        func setUpMask() {
            /* ######################################################### */
            /**
             This creates the center circle overlay.
             */
            func setTheCenterOverlay() {
                _centerDot?.removeFromSuperlayer()
                _centerDot = nil
                
                guard let mapBounds = mapView?.bounds else { return }
                
                let centerLayer = CAShapeLayer()
                centerLayer.fillColor = UIColor.systemRed.withAlphaComponent(Self._centerAlphaValue).cgColor
                var containerRect = CGRect(origin: .zero, size: CGSize(width: Self._centerCircleRadiusInDisplayUnits, height: Self._centerCircleRadiusInDisplayUnits))
                containerRect.origin = CGPoint(x: ((mapBounds.size.width - Self._centerCircleRadiusInDisplayUnits) / 2), y: ((mapBounds.size.height - Self._centerCircleRadiusInDisplayUnits) / 2))
                let circlePath = UIBezierPath(ovalIn: containerRect)
                centerLayer.path = circlePath.cgPath
                
                mapView?.layer.addSublayer(centerLayer)
                _centerDot = centerLayer
            }

            _circleLayer?.removeFromSuperlayer()
            _circleLayer = nil

            guard let mapBounds = mapView?.bounds else { return }
            let squareSide = min(mapBounds.size.width, mapBounds.size.height)
            let cutOutOrigin = CGPoint(x: (mapBounds.size.width - squareSide) / 2,
                                       y: (mapBounds.size.height - squareSide) / 2)
            let cutoutRect = CGRect(origin: cutOutOrigin,
                                    size: CGSize(width: squareSide, height: squareSide))
            
            let path = CGMutablePath()
            let fillPath = UIBezierPath(rect: mapBounds)
            let circlePath = UIBezierPath(ovalIn: cutoutRect)
            path.addPath(fillPath.cgPath)
            path.addPath(circlePath.cgPath)
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = mapBounds
            maskLayer.fillColor = UIColor.white.cgColor
            maskLayer.path = path
            maskLayer.fillRule = .evenOdd
            
            let circleLayer = CALayer()
            circleLayer.frame = mapBounds
            circleLayer.backgroundColor = UIColor.black.withAlphaComponent(Self._maskAlphaValue).cgColor
            circleLayer.mask = maskLayer
            mapView?.layer.addSublayer(circleLayer)
            _circleLayer = circleLayer
            setTheCenterOverlay()
        }
        
        let regionSizeInMeters = CLLocationDistance(prefs.locationRadius * 2)

        guard let coordinateRegion = mapView?.regionThatFits(MKCoordinateRegion(center: prefs.locationCenter, latitudinalMeters: regionSizeInMeters, longitudinalMeters: regionSizeInMeters)) else { return }
        
        mapView?.delegate = nil
        mapView?.setRegion(coordinateRegion, animated: false)
        setUpMask()
        mapView?.delegate = self
    }
    
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController {
    /* ################################################################## */
    /**
     Called when the layout has completed.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setUpMap()
    }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapViewController: MKMapViewDelegate {
    /* ################################################################## */
    /**
     */
    func mapView(_ inMapView: MKMapView, regionDidChangeAnimated: Bool) {
        let span = inMapView.region.span
        let center = inMapView.region.center
        let south = CLLocation(latitude: (center.latitude - span.latitudeDelta) / 2, longitude: center.longitude)
        let north = CLLocation(latitude: (center.latitude + span.latitudeDelta) / 2, longitude: center.longitude)
        let west = CLLocation(latitude: center.latitude, longitude: (center.longitude - span.longitudeDelta) / 2)
        let east = CLLocation(latitude: center.latitude, longitude: (center.longitude + span.longitudeDelta) / 2)
        
        prefs.locationCenter = center
        prefs.locationRadius = min(south.distance(from: north), west.distance(from: east)) / 2
    }
}
