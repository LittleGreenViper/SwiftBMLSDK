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

import CoreLocation
import MapKit
import RVS_Persistent_Prefs
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Persistent Test Harness Settings -
/* ###################################################################################################################################### */
/**
 This stores our various parameters, and also acts as a namespace, for our "global" types.
 */
class SwiftBMLSDK_TestHarness_Prefs: RVS_PersistentPrefs {
    /* ################################################################################################################################## */
    // MARK: Search Criteria
    /* ################################################################################################################################## */
    /**
     This is a criteria for our search. It is designed to be mutated.
     */
    struct SearchCriteria {
        /* ################################################################## */
        /**
         From [this SO answer](https://stackoverflow.com/a/35321619/879365)
         
         - parameter region: The region to convert to a map rect.
         
         - returns: The MkMapRect that corresponds to the input MKCoordinateRegion.
         */
        private static func _mKMapRectForCoordinateRegion(region inRegion: MKCoordinateRegion) -> MKMapRect {
            let topLeft = CLLocationCoordinate2D(latitude: inRegion.center.latitude + (inRegion.span.latitudeDelta/2), longitude: inRegion.center.longitude - (inRegion.span.longitudeDelta/2))
            let bottomRight = CLLocationCoordinate2D(latitude: inRegion.center.latitude - (inRegion.span.latitudeDelta/2), longitude: inRegion.center.longitude + (inRegion.span.longitudeDelta/2))

            let a = MKMapPoint(topLeft)
            let b = MKMapPoint(bottomRight)
            
            let squareSize = min(abs(a.x-b.x), abs(a.y-b.y))
            return MKMapRect(origin: MKMapPoint(x: min(a.x, b.x), y: min(a.y, b.y)), size: MKMapSize(width: squareSize, height: squareSize))
        }

        // MARK: Stored Properties
        /* ############################################################## */
        /**
         The maximum search radius, in meters. This must be greater than zero, if we are a valid search.
         */
        var maxLocationRadiusInMeters: CLLocationDistance = 0
        
        /* ############################################################## */
        /**
         The center of a location-based search. This must be a valid long/lat, if we are a valid search.
         */
        var locationCenter: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
        
        // MARK: Computed Properties
        /* ############################################################## */
        /**
         Returns true, if the search is a valid location-based search.
         */
        var isLocationBasedSearch: Bool { 0 < maxLocationRadiusInMeters && CLLocationCoordinate2DIsValid(locationCenter) }
        
        /* ################################################################## */
        /**
         This returns the location search as a square region, centered on the location center.
         It also stores the location, or clears it, if the input region is nil or invalid.
         */
        var locationRegion: MKCoordinateRegion? {
            get {
                guard isLocationBasedSearch else { return nil }
                let multiplierX = MKMapPointsPerMeterAtLatitude(locationCenter.latitude)
                let multiplierY = MKMapPointsPerMeterAtLatitude(0)
                let regionCenter = MKMapPoint(locationCenter)
                let regionWidth = (maxLocationRadiusInMeters * 2) * multiplierX
                let regionHeight = (maxLocationRadiusInMeters * 2) * multiplierY
                let mapRect = MKMapRect(x: regionCenter.x, y: regionCenter.y, width: regionWidth, height: regionHeight)
                return MKCoordinateRegion(mapRect)
            }
            set {
                guard let newValue = newValue else { 
                    locationCenter = kCLLocationCoordinate2DInvalid
                    maxLocationRadiusInMeters = 0
                    return
                }
                
                let center = newValue.center
                let span = newValue.span
                
                guard CLLocationCoordinate2DIsValid(center) else {
                    locationCenter = kCLLocationCoordinate2DInvalid
                    maxLocationRadiusInMeters = 0
                    return
                }
                
                let multiplierX = MKMapPointsPerMeterAtLatitude(center.latitude)
                let mapRect = Self._mKMapRectForCoordinateRegion(region: newValue)
                let radius = mapRect.width / multiplierX
                
                guard 0 < radius else {
                    locationCenter = kCLLocationCoordinate2DInvalid
                    maxLocationRadiusInMeters = 0
                    return
                }
                
                locationCenter = center
                maxLocationRadiusInMeters = radius
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: RVS_PersistentPrefs Conformance
    /* ################################################################################################################################## */
    /**
     This is an enumeration that will list the prefs keys for us.
     */
    enum Keys: String {
        /* ############################################################## */
        /**
         The maximum search radius, in meters.
         */
        case locationCenter_maxRadius

        /* ############################################################## */
        /**
         The latitude center of a location-based search.
         */
        case locationCenter_latitude
        
        /* ############################################################## */
        /**
         The longitude center of a location-based search.
         */
        case locationCenter_longitude
        
        /* ############################################################## */
        /**
         These are all the keys, in an Array of String.
         */
        static var allKeys: [String] { [
            locationCenter_maxRadius.rawValue,
            locationCenter_latitude.rawValue,
            locationCenter_longitude.rawValue
        ] }
    }
    
    /* ################################################################## */
    /**
     The maximum search radius, in meters.
     */
    @objc dynamic var locationRadius: Double {
        get { values[Keys.locationCenter_maxRadius.rawValue] as? Double ?? 0 }
        set { values[Keys.locationCenter_maxRadius.rawValue] = newValue }
    }
    
    /* ################################################################## */
    /**
     The center of a location-based search.
     */
    @objc dynamic var locationCenter: CLLocationCoordinate2D {
        get {
            guard let lat = values[Keys.locationCenter_latitude.rawValue] as? Double,
                  let lng = values[Keys.locationCenter_longitude.rawValue] as? Double
            else { return kCLLocationCoordinate2DInvalid }
            
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            values[Keys.locationCenter_latitude.rawValue] = newValue.latitude
            values[Keys.locationCenter_longitude.rawValue] = newValue.longitude
        }
    }
}
