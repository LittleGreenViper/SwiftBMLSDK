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
import SwiftBMLSDK
import Contacts

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
    private static var _searchResults: SwiftBMLSDK_Parser?
    
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
         These are all the keys, in an Array of String.
         */
        static var allKeys: [String] {
            [
                locationCenter_maxRadius.rawValue,
                locationCenter_latitude.rawValue,
                locationCenter_longitude.rawValue
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
        queryInstance.meetingSearch(specification: SwiftBMLSDK_Query.SearchSpecification(locationRadius: locationRadius, locationCenter: locationCenter)) { inSearchResults, inError in
            Self._searchResults = inSearchResults
            DispatchQueue.main.async { inCompletion() }
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

/* ###################################################################################################################################### */
// MARK: - Parser Extension -
/* ###################################################################################################################################### */
/**
 This extension adds a specialization for machine learning.
 */
public extension SwiftBMLSDK_Parser {
    /* ################################################# */
    /**
     This returns the entire meeting list as an ML text processor dataset.
     The meeting is described in a single line of text, and the labels are the meeting type (virtual, in-person, and hybrid).
     */
    var textProcessorJSONData: Data? {
        /* ############################################ */
        /**
         This returns an English string, describing the meeting, in a natural language manner.
         
         - parameter meeting: The meeting instance we're describing.
         */
        func makeMeetingDescription(meeting inMeeting: Meeting) -> String {
            /* ######################################## */
            /**
             Gets a localized version of the weekday name from an index.
             
             [Cribbed from Here](http://stackoverflow.com/questions/7330420/how-do-i-get-the-name-of-a-day-of-the-week-in-the-users-locale#answer-34289913)
             
             - parameter inWeekdayNumber: 1-based index (1 - 7)
             - parameter isShort: Optional. If true, then the shortened version of the name will be returned. Default is false.
             
             - returns: The localized, full-length weekday name. Nil, if there's a problem.
             */
            func weekdayNameFromWeekdayNumber(_ inWeekdayNumber: Int, isShort inIsShort: Bool = false) -> String? {
                /* #################################### */
                /**
                 This returns the weekday, unadjusted for a differing week start.
                 
                 - parameter inWeekdayNumber: 1-based index (1 - 7)
                 
                 - returns: The unadjusted weekday index (1-based). 0, if there was an out-of-range issue.
                 */
                func unAdjustedWeekdayNumber(_ inWeekdayNumber: Int) -> Int {
                    guard (1..<8).contains(inWeekdayNumber) else { return 0 }
                    let index = Calendar.current.firstWeekday + (inWeekdayNumber - 1)
                    return 7 < index ? index - 7 : index
                }

                let weekdayIndex = unAdjustedWeekdayNumber(inWeekdayNumber) - 1
                let weekdaySymbols = inIsShort ? Calendar.current.veryShortWeekdaySymbols: Calendar.current.weekdaySymbols
                guard  (0..<weekdaySymbols.count).contains(weekdayIndex) else { return nil }
                return weekdaySymbols[weekdayIndex]
            }
            
            guard let weekday = weekdayNameFromWeekdayNumber(inMeeting.weekday),
                  let localizedTZName = inMeeting.timeZone.localizedName(for: .standard, locale: .current)
            else { return "" }
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            let startTimeString = df.string(from: inMeeting.startTime)
            let duration = Int(round(inMeeting.duration / 60))
            var meetingString = "\"\(inMeeting.name)\" is an \(inMeeting.organization.rawValue.uppercased()) meeting, which starts at \(startTimeString), \(localizedTZName), every \(weekday), and lasts for \(duration) minutes."
            if let physicalLocation = inMeeting.inPersonAddress {
                let addressFormatter = CNPostalAddressFormatter()
                addressFormatter.style = .mailingAddress
                
                var venue = ""
                
                if let venueName = inMeeting.inPersonVenueName,
                   !venueName.isEmpty {
                    venue = venueName + "\n"
                }
                
                meetingString += "\nIt meets in-person, at \(venue)\(addressFormatter.string(from: physicalLocation))."
            } else if let venueName = inMeeting.inPersonVenueName,
                      !venueName.isEmpty {
                meetingString += "\nIt meets in-person, at \(venueName)."
            }
            
            if let locationAdd = inMeeting.locationInfo,
               !locationAdd.isEmpty {
                meetingString += "\nAdditional Location Information: \(locationAdd)."
            }

            if let coords = inMeeting.coords,
               CLLocationCoordinate2DIsValid(coords) {
                let latitude = round(coords.latitude * 100000) / 100000
                let longitude = round(coords.longitude * 100000) / 100000
                meetingString += "\nThe meeting coordinates are (\(latitude), \(longitude))."
            }
            
            if let virtualURL = inMeeting.virtualURL {
                meetingString += "\nThe meeting is accessible as a virtual meeting. The URL for the meeting is \(virtualURL.absoluteString)."
            }
            
            if let virtualInfo = inMeeting.virtualInfo,
               !virtualInfo.isEmpty {
                meetingString += "\nAdditional Virtual Instructions: \(virtualInfo)."
            }
            
            if let virtualPhoneNumber = inMeeting.virtualPhoneNumber {
                meetingString += "\nThe meeting is accessible as a phone meeting. The Phone number for the meeting is \(virtualPhoneNumber)."
            }
            
            inMeeting.formats.forEach {
                meetingString += "\n\($0.description)."
            }
            
            #if DEBUG
                print(meetingString)
            #endif
            return meetingString
        }
        
        var jsonString: [[String: String]] = []
        
        meetings.forEach { meeting in
            let type = meeting.meetingType.rawValue
            let id = String(meeting.id)
            let description = makeMeetingDescription(meeting: meeting)
            jsonString.append(["id": id, "type": type, "meeting": description])
        }
        
        return try? JSONEncoder().encode(jsonString)
    }
}
