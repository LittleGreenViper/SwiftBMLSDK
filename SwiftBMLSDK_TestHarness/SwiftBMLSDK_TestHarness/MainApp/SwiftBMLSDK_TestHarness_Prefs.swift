/*
 © Copyright 2024 - 2025, Little Green Viper Software Development LLC
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
import SwiftBMLSDK
import Contacts

/* ###################################################################################################################################### */
// MARK: - Abstraction for the Meeting Type -
/* ###################################################################################################################################### */
public typealias MeetingInstance = SwiftBMLSDK_Parser.Meeting

/* ###################################################################################################################################### */
// MARK: - Persistent Test Harness Settings -
/* ###################################################################################################################################### */
/**
 This stores our various parameters, and also acts as a namespace, for our "global" types.
 */
class SwiftBMLSDK_TestHarness_Prefs: RVS_PersistentPrefs {
    /* ################################################################## */
    /**
     This is used to store the current user location.
     */
    private static var _currentUserLocation: CLLocationCoordinate2D?
    
    /* ################################################################## */
    /**
     This has the results of any search we did.
     */
    private static var _searchResults: SwiftBMLSDK_Parser? { didSet { DispatchQueue.main.async { mainTabController?.updateEnablements() } } }

    /* ################################################################## */
    /**
     This has the results of a server info query.
     */
    private static var _serverInfo: SwiftBMLSDK_Query.ServerInfo?

    /* ################################################################## */
    /**
     This is our query instance.
     */
    private static var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))
    
    /* ################################################################## */
    /**
     The main tab controller registers itself, here.
     */
    public static var mainTabController: SwiftBMLSDK_TestHarness_TabBarController?

    /* ################################################################################################################################## */
    // MARK: RVS_PersistentPrefs Conformance
    /* ################################################################################################################################## */
    /**
     This is an enumeration that will list the prefs keys for us.
     */
    enum Keys: String {
        /* ############################################################## */
        /**
         The maximum search radius, in meters If auto_radius is true, then this is the absolute maximum, before giving up.
         */
        case locationCenter_maxRadius = "kMaxRadius"
        
        /* ############################################################## */
        /**
         The latitude center of a location-based search.
         */
        case locationCenter_latitude = "kLat"
        
        /* ############################################################## */
        /**
         The longitude center of a location-based search.
         */
        case locationCenter_longitude = "kLng"
        
        /* ############################################################## */
        /**
         This is true, if we are doing an auto-radius search.
         */
        case auto_radius = "kAuto"
        
        /* ############################################################## */
        /**
         The minimum number of meetings for auto-radius (ignored if auto_radius is false).
         */
        case auto_radius_minimum = "kAutoMin"

        /* ############################################################## */
        /**
         These are all the keys, in an Array of String.
         */
        static var allKeys: [String] {
            [
                locationCenter_maxRadius.rawValue,
                locationCenter_latitude.rawValue,
                locationCenter_longitude.rawValue,
                auto_radius.rawValue,
                auto_radius_minimum.rawValue
            ]
        }
    }
    
    /* ################################################################## */
    /**
     This is a list of the keys for our prefs.
     We should use the enum for the keys (rawValue).
     */
    override var keys: [String] { Keys.allKeys }
    
    /* ################################################################## */
    /**
     Set to true, when changes are made. Set to false, when you want to set a baseline.
     */
    var isDirty: Bool = false {
        didSet {
            if isDirty {
                Self._searchResults = nil
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Public Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_Prefs {
    /* ################################################################## */
    /**
     This is used to store the current user location.
     */
    public var currentUserLocation: CLLocationCoordinate2D? {
        get { Self._currentUserLocation }
        set { Self._currentUserLocation = newValue }
    }

    /* ################################################################## */
    /**
     This has the results of any search we did.
     */
    public var searchResults: SwiftBMLSDK_Parser? { Self._searchResults }
    
    /* ################################################################## */
    /**
     This has the results of a server info query.
     */
    public var serverInfo: SwiftBMLSDK_Query.ServerInfo? { Self._serverInfo }

    /* ################################################################## */
    /**
     This is our query instance.
     */
    public var queryInstance: SwiftBMLSDK_Query { Self._queryInstance }

    /* ################################################################## */
    /**
     The maximum search radius, in meters.
     */
    public var locationRadius: Double {
        get { values[Keys.locationCenter_maxRadius.rawValue] as? Double ?? 0 }
        set {
            isDirty = true
            values[Keys.locationCenter_maxRadius.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The center of a location-based search.
     */
    public var locationCenter: CLLocationCoordinate2D {
        get {
            guard let lat = values[Keys.locationCenter_latitude.rawValue] as? Double,
                  let lng = values[Keys.locationCenter_longitude.rawValue] as? Double
            else { return kCLLocationCoordinate2DInvalid }
            
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        set {
            isDirty = true
            values[Keys.locationCenter_latitude.rawValue] = newValue.latitude
            values[Keys.locationCenter_longitude.rawValue] = newValue.longitude
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if the search is an auto-radius search.
     */
    public var isAutoRadius: Bool {
        get { values[Keys.auto_radius.rawValue] as? Bool ?? false }
        set {
            isDirty = true
            values[Keys.auto_radius.rawValue] = newValue
        }
    }

    /* ################################################################## */
    /**
     The minimum number of meetings to find, for an auto-radius search (ignored if isAutoRadius is false).
     */
    public var minimumAutoRadiusMeetings: Int {
        get { values[Keys.auto_radius_minimum.rawValue] as? Int ?? 10 }
        set {
            isDirty = true
            values[Keys.auto_radius_minimum.rawValue] = newValue
        }
    }

    /* ############################################################## */
    /**
     Returns true, if the search is a valid location-based search.
     */
    public var isLocationBasedSearch: Bool { 0 < locationRadius && CLLocationCoordinate2DIsValid(locationCenter) }
    
    /* ################################################################## */
    /**
     Some cribbing from [this SO answer](https://stackoverflow.com/a/35321619/879365).
     
     This takes a map region, then cuts a square out of the middle of it, using the least axis to determine the size of the square.
     It takes one side of the square, and cuts it in half, to create the radius.
     
     This returns the location search as a square region, centered on the location center.
     It also stores the location, or clears it, if the input region is nil or invalid.
     */
    public var locationRegion: MKCoordinateRegion? {
        get {
            guard isLocationBasedSearch else { return nil }
            let multiplierX = MKMapPointsPerMeterAtLatitude(locationCenter.latitude)
            let multiplierY = MKMapPointsPerMeterAtLatitude(0)
            let regionCenter = MKMapPoint(locationCenter)
            let regionWidth = (locationRadius * 2) * multiplierX
            let regionHeight = (locationRadius * 2) * multiplierY
            let mapRect = MKMapRect(x: regionCenter.x, y: regionCenter.y, width: regionWidth, height: regionHeight)
            return MKCoordinateRegion(mapRect)
        }
        set {
            guard let newValue = newValue else {
                locationCenter = kCLLocationCoordinate2DInvalid
                locationRadius = 0
                return
            }
            
            guard CLLocationCoordinate2DIsValid(newValue.center),
                  0 < newValue.span.latitudeDelta,
                  0 < newValue.span.longitudeDelta
            else {
                locationCenter = kCLLocationCoordinate2DInvalid
                locationRadius = 0
                return
            }
            
            let topLeft = CLLocationCoordinate2D(latitude: newValue.center.latitude + (newValue.span.latitudeDelta/2), longitude: newValue.center.longitude - (newValue.span.longitudeDelta/2))
            let bottomRight = CLLocationCoordinate2D(latitude: newValue.center.latitude - (newValue.span.latitudeDelta/2), longitude: newValue.center.longitude + (newValue.span.longitudeDelta/2))
            
            let a = MKMapPoint(topLeft)
            let b = MKMapPoint(bottomRight)
            
            let mapRect = MKMapRect(origin: MKMapPoint(x: min(a.x, b.x), y: min(a.y, b.y)), size: MKMapSize(width: abs(a.x - b.x), height: abs(a.y - b.y)))
            
            let radius = (min(mapRect.width / MKMapPointsPerMeterAtLatitude(newValue.center.latitude), mapRect.height / MKMapPointsPerMeterAtLatitude(0))) / 2
            
            guard 0 < radius else {
                locationCenter = kCLLocationCoordinate2DInvalid
                locationRadius = 0
                return
            }
            
            locationCenter = newValue.center
            locationRadius = radius
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Public Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_Prefs {
    /* ############################################################## */
    /**
     Simply sets the search results to nil.
     */
    public func clearSearchResults() {
        Self._searchResults = nil
    }
    
    /* ############################################################## */
    /**
     This fetches the meetings from the aggregator, using the current settings. This populates the `searchResults` property.
     
     - parameter completion: A tail completion proc, with no parameters. It is called in the main thread.
     */
    public func performSearch(completion inCompletion: @escaping () -> Void) {
        clearSearchResults()
        if isAutoRadius,
           0 < locationRadius,
           0 < minimumAutoRadiusMeetings {
            queryInstance.meetingAutoRadiusSearch(minimumNumberOfResults: minimumAutoRadiusMeetings, specification: SwiftBMLSDK_Query.SearchSpecification(type: .inPerson(isExclusive: false), locationCenter: locationCenter, locationRadius: locationRadius)) { inSearchResults, inError in
                Self._searchResults = inSearchResults
                DispatchQueue.main.async { inCompletion() }
            }
        } else {
            queryInstance.meetingSearch(specification: SwiftBMLSDK_Query.SearchSpecification(type: .inPerson(isExclusive: false), locationCenter: locationCenter, locationRadius: locationRadius)) { inSearchResults, inError in
                Self._searchResults = inSearchResults
                DispatchQueue.main.async { inCompletion() }
            }
        }
    }

    /* ############################################################## */
    /**
     This fetches the server info from the aggregator. This populates the `serverInfo` property.
     
     - parameter completion: A tail completion proc, with no parameters. It is called in the main thread.
     */
    public func getServerInfo(completion inCompletion: @escaping () -> Void) {
        Self._serverInfo = nil
        clearSearchResults()
        queryInstance.serverInfo { inServerInfo , inError in
            Self._serverInfo = inServerInfo
            DispatchQueue.main.async { inCompletion() }
        }
    }
}
