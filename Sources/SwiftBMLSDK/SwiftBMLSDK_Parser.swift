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

import Foundation
import CoreLocation // For coordinates
import Contacts     // For the in-person address

/* ###################################################################################################################################### */
// MARK: - CoreLocation Extension -
/* ###################################################################################################################################### */
/**
 These are some useful Core Location tools.
 */
fileprivate extension CLLocationCoordinate2D {
    /* ################################################################## */
    /**
     - parameter inComp: A location (long and lat), to which we are comparing ourselves.
     - parameter precisionInMeters: This is an optional precision (slop area), in meters. If left out, then the match must be exact.
     
     - returns: True, if the locations are equal, according to the given precision.
     */
    func _isEqualTo(_ inComp: CLLocationCoordinate2D, precisionInMeters inPrecisionInMeters: CLLocationDistance = 0.0) -> Bool { CLLocation(latitude: latitude, longitude: longitude).distance(from: CLLocation(latitude: inComp.latitude, longitude: inComp.longitude)) <= inPrecisionInMeters }
}

/* ###################################################################################################################################### */
// MARK: - File Private Date Extension -
/* ###################################################################################################################################### */
/**
 This extension allows us to convert a date to a certain time zone.
 */
fileprivate extension Date {
    /* ################################################################## */
    /**
     Convert a date between two timezones.
     
     Inspired by [this SO answer](https://stackoverflow.com/a/54064820/879365)
     
     - parameter from: The source timezone.
     - paremeter to: The destination timezone.
     
     - returns: The converted date
     */
    func _convert(from inFromTimeZone: TimeZone, to inToTimeZone: TimeZone) -> Date {
        addingTimeInterval(TimeInterval(inToTimeZone.secondsFromGMT(for: self) - inFromTimeZone.secondsFromGMT(for: self)))
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting JSON Page Parser -
/* ###################################################################################################################################### */
/**
 This struct will contain one page of results from a meeting search, and is one of the response parameters to the ``SwiftBMLSDK_Query/QueryResultCompletion`` completion callback.
 
 This is a **baseline** parser; it doesn't really do anything more than make a simple map of the input JSON into an array of structs. It doesn't change the sorting, and provides a read-only, struct property view.
 
 The parser then automatically populates a ``meta`` instance, that reports the page metadata from the server, and a ``meetings`` array, of all meeting instances, and some functional interfaces.
 
 # Supported Systems
 
 This will support iOS 16 (and greater), iPadOS 16 (and greater), tvOS 16 (and greater), macOS 13 (and greater), and watchOS 9 (and greater)
 
 This requires Swift 5 or greater.
 
 # Usage
 
 Do not instantiate this type. That's handled by a ``SwiftBMLSDK_Query`` instance that performs a search, and returns an instance of this struct.
 
 # Dependencies
 
 This parser has no dependencies, other than the Foundation, CoreLocation, and Contacts SDKs, provided by Apple.
 */
public struct SwiftBMLSDK_Parser: Encodable {
    // MARK: - Internal Private Functionality -

    /* ################################################# */
    /**
     This parses the page metadata from the raw dictionary.
     
     - parameter inDictionary: The partly-parsed raw JSON
     */
    private static func _parseMeta(_ inDictionary: [String: Any]) -> PageMeta? {
        guard let actualSize = inDictionary["actual_size"] as? Int,
              let pageSize = inDictionary["page_size"] as? Int,
              let startingIndex = inDictionary["starting_index"] as? Int,
              let total = inDictionary["total"] as? Int,
              let totalPages = inDictionary["total_pages"] as? Int,
              let page = inDictionary["page"] as? Int,
              let searchTime = inDictionary["search_time"] as? TimeInterval
        else { return nil }
        
        return PageMeta(actualSize: actualSize,
                        pageSize: pageSize,
                        startingIndex: startingIndex,
                        total: total,
                        totalPages: totalPages,
                        page: page,
                        searchTime: searchTime
        )
    }

    /* ################################################# */
    /**
     This parses the meetings from the raw dictionary.
     
     - parameter inDictionary: The partly-parsed raw JSON
     */
    private static func _parseMeeting(_ inDictionary: [String: Any]) -> Meeting? { Meeting(inDictionary) }
    
    // MARK: Internal Initializer
    
    /* ################################################# */
    /**
     This is a failable initializer. It parses the JSON data.
     
     - parameter jsonData: A Data instance, with the raw JSON dump.
     */
    internal init?(jsonData inJSONData: Data, specification inSpecification: SwiftBMLSDK_Query.SearchSpecification) {
        guard let simpleJSON = try? JSONSerialization.jsonObject(with: inJSONData, options: [.allowFragments]) as? NSDictionary,
              let metaJSON = simpleJSON["meta"] as? [String: Any],
              let meta = Self._parseMeta(metaJSON),
              let meetingsJSON = simpleJSON["meetings"] as? [[String: Any]],
              !meetingsJSON.isEmpty
        else { return nil }
        self.meta = meta
        self.meetings = meetingsJSON.compactMap {
            let ret = Self._parseMeeting($0)
            switch inSpecification.type {
            case .any:
                return ret
                
            case .hybrid:
                return .hybrid == ret?.meetingType && (!(ret?.inPersonVenueName ?? "").isEmpty || !(ret?.inPersonAddress?.street ?? "").isEmpty) ? ret : nil
                
            case .virtual(let isExclusive):
                return .virtual == ret?.meetingType || (!isExclusive && .hybrid == ret?.meetingType) ? ret : nil
                
            case .inPerson(let isExclusive):
                return (.inPerson == ret?.meetingType || (!isExclusive && .hybrid == ret?.meetingType)) /*&& (!(ret?.inPersonVenueName ?? "").isEmpty || !(ret?.inPersonAddress?.street ?? "").isEmpty)*/ ? ret : nil
            }
        }
    }

    // MARK: -
    // MARK: - Exported Public Interface -

    // MARK: - Public Data Types and Enums -
    
    /* ################################################################################################################################## */
    // MARK: Page Metadata Container
    /* ################################################################################################################################## */
    /**
     This struct holds metadata about the page of meeting results, as reported by the server.
     */
    public struct PageMeta: Encodable {
        /* ############################################# */
        /**
         Default Initializer (internal).
         
         - parameters:
             - actualSize: This is the actual size of this single page of results, in results (not bytes).
             - pageSize: This is the number of results allowed as a maximum, per page, in results.
             - startingIndex: This is the 0-based starting index, of the total found set (in results), for this page.
             - total: This is the total size of all results in the found set.
             - totalPages: This is the total number of pages that contain the found set.
             - page: This is the 0-based index of this page of results.
             - searchTime: This is the number of seconds, reported by the server, to generate this page of results.
         */
        internal init(actualSize inActualSize: Int = 0,
                    pageSize inPageSize: Int = 0,
                    startingIndex inStartingIndex: Int = 0,
                    total inTotal: Int = 0,
                    totalPages inTotalPages: Int = 0,
                    page inPage: Int = 0,
                    searchTime inSearchTime: TimeInterval = 0
        ) {
            actualSize = inActualSize
            pageSize = inPageSize
            startingIndex = inStartingIndex
            total = inTotal
            totalPages = inTotalPages
            page = inPage
            searchTime = inSearchTime
        }

        // MARK: - Exported Public Interface -

        /* ############################################# */
        /**
         This is the actual size of this single page of results, in results (not bytes).
         */
        public let actualSize: Int

        /* ############################################# */
        /**
         This is the number of results allowed as a maximum, per page, in results.
         */
        public let pageSize: Int

        /* ############################################# */
        /**
         This is the 0-based starting index, of the total found set (in results), for this page.
         */
        public let startingIndex: Int

        /* ############################################# */
        /**
         This is the total size of all results in the found set.
         */
        public let total: Int

        /* ############################################# */
        /**
         This is the total number of pages that contain the found set.
         */
        public let totalPages: Int

        /* ############################################# */
        /**
         This is the 0-based index of this page of results.
         */
        public let page: Int

        /* ############################################# */
        /**
         This is the number of seconds, reported by the server, to generate this page of results.
         */
        public let searchTime: TimeInterval
    }

    /* ################################################################################################################################## */
    // MARK: Meeting Data Container
    /* ################################################################################################################################## */
    /**
     This struct holds a single parsed meeting instance.
     
     > NOTE: There is a platform-dependent extension that adds the ``SwiftBMLSDK_Parser/Meeting/directAppURI`` computed property to this type.
     */
    public struct Meeting {
        /* ############################################################################################################################## */
        // MARK: Format Information Container
        /* ############################################################################################################################## */
        /**
         This struct holds a parsed format information instance.
         */
        public struct Format: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Comparable {
            /* ############################################# */
            /**
             Default initializer
             
             - parameters:
                - key: The format key
                - name: The short format name
                - description: The longer format description
                - language: The language code.
             */
            internal init(key inKey: String, name inName: String, description inDescription: String, language inLanguage: String, id inID: String) {
                key = inKey
                name = inName
                description = inDescription
                language = inLanguage
                id = inID
            }

            /* ############################################# */
            /**
             A failable initializer. This initializer parses "raw" format data, and populates the instance properties.
             
             - parameter inDictionary: A simple String-keyed dictionary of partly-parsed values.
             */
            internal init(_ inDictionary: [String: Any]) {
                self.init(key: (inDictionary["key"] as? String) ?? "", name: (inDictionary["name"] as? String) ?? "", description: (inDictionary["description"] as? String) ?? "", language: (inDictionary["language"] as? String) ?? "", id: String((inDictionary["id"] as? Int) ?? 0))
            }

            // MARK: Public Instance Properties
            
            /* ############################################# */
            /**
             This is the short format "key" string.
             */
            public let key: String

            /* ############################################# */
            /**
             This is the short name for the format.
             */
            public let name: String

            /* ############################################# */
            /**
             This is the longer description of the format.
             */
            public let description: String
            
            /* ############################################# */
            /**
             This is the [ISO 639-2](https://www.loc.gov/standards/iso639-2/php/code_list.php) code for the language used for the name and description.
             */
            public let language: String

            /* ############################################# */
            /**
             This is the local server format ID.
             */
            public let id: String

            // MARK: Public Computed Properties
            
            /* ############################################# */
            /**
             Returns the format, as single string, with values separarated by tabs.
             */
            public var asString: String { "\(name) (\(description))" }
            
            // MARK: Comparable Conformance
            
            /* ############################################# */
            /**
             We simply sort by key, so there's consistency in the ordering.
             
             - parameter lhs: The left-hand side of the comparison.
             - parameter rhs: The right-hand side of the comparison.
             
             - returns: True, if the lhs ID is less than the rhs ID.
             */
            public static func < (lhs: Format, rhs: Format) -> Bool { lhs.key < rhs.key }
            
            // MARK: CustomDebugStringConvertible Conformance
            
            /* ############################################# */
            /**
             Returns a simple textual description of the data.
             */
            public var debugDescription: String { "\t\t(\(key))\t\(name)\t(\(language))\n\t\t\t\t\(description)\n\t\t\t\t\(id)" }
        }

        // MARK: Private Properties
        
        /* ################################################# */
        /**
         This is actually meant to be used by the `getNextStartDate()` extension method, but Swift [wisely] doesn't let stored properties get declared in extensions.
         This will always be in the meeting's timezone (no adjustment to local).
         */
        private var _cachedNextDate: Date?
        
        /* ################################################# */
        /**
         This is how many seconds there are, in a week.
         */
        static let oneWeekInSeconds = TimeInterval(604800)

        // MARK: Internal Initializer
                
        /* ################################################# */
        /**
         This is a failable initializer, it parses an input dictionary.
         
         - parameter inDictionary: The semi-parsed JSON record for the meeting.
         */
        internal init?(_ inDictionary: [String: Any]) {
            /* ########################################### */
            /**
             "Cleans" a URI.
             
             - parameter urlString: The URL, as a String. It can be optional.
             
             - returns: an optional String. This is the given URI, "cleaned up" ("https://" or "tel:" may be prefixed)
             */
            func cleanURI(urlString inURLString: String?) -> String? {
                /* ####################################### */
                /**
                 This tests a string to see if a given substring is present at the start.
                 
                 - Parameters:
                 - inString: The string to test.
                 - inSubstring: The substring to test for.
                 
                 - returns: true, if the string begins with the given substring.
                 */
                func string (_ inString: String, beginsWith inSubstring: String) -> Bool {
                    var ret: Bool = false
                    if let range = inString.range(of: inSubstring) {
                        ret = (range.lowerBound == inString.startIndex)
                    }
                    return ret
                }
                
                guard var ret: String = inURLString?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                      let regex = try? NSRegularExpression(pattern: "^(http://|https://|tel://|tel:)", options: .caseInsensitive)
                else { return nil }
                
                // We specifically look for tel URIs.
                let wasTel = string(ret.lowercased(), beginsWith: "tel:")
                
                // Yeah, this is pathetic, but it's quick, simple, and works a charm.
                ret = regex.stringByReplacingMatches(in: ret, options: [], range: NSRange(location: 0, length: ret.count), withTemplate: "")
                
                if ret.isEmpty {
                    return nil
                }
                
                if wasTel {
                    ret = "tel:" + ret
                } else {
                    ret = "https://" + ret
                }
                
                return ret
            }

            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .iso8601)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "HH:mm:ss"

            guard let serverID = inDictionary["server_id"] as? Int,
                  let startTimeStr = inDictionary["start_time"] as? String,
                  let startTime = dateFormatter.date(from: startTimeStr),
                  let localMeetingID = inDictionary["meeting_id"] as? Int,
                  let weekday = inDictionary["weekday"] as? Int,
                  (1..<8).contains(weekday),
                  let organizationStr = inDictionary["organization_key"] as? String
            else { return nil }

            self.weekday = weekday
            self.startTime = startTime
            self.serverID = serverID
            self.localMeetingID = localMeetingID
            self.organization = Organization(rawValue: organizationStr) ?? .none
            
            let durationTemp = inDictionary["duration"] as? Int ?? 3600 // One hour default.
            self.duration = (0..<86400).contains(durationTemp) ? TimeInterval(durationTemp) : TimeInterval(3600)    // Can't be greater than 24 hours.

            self.formats = (inDictionary["formats"] as? [[String: Any]] ?? []).compactMap { Format($0) }.sorted()

            self.name = (inDictionary["name"] as? String) ?? ""

            var fixedCoords = CLLocationCoordinate2D()
            
            var coords: CLLocationCoordinate2D?
            
            if let long = inDictionary["longitude"] as? Double,
               let lat = inDictionary["latitude"] as? Double,
               CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                fixedCoords = CLLocationCoordinate2D(latitude: lat, longitude: long)
                coords = fixedCoords
            }

            if let timezoneStr = inDictionary["time_zone"] as? String,
               let tz = TimeZone(identifier: timezoneStr) {
                self.timeZone = tz
            } else if nil == getenv("IGNORE_NO_TZ") {
                return nil  // Zero-tolerance for no timezone.
            } else {
                self.timeZone = .current
            }

            if let comments = inDictionary["comments"] as? String,
               !comments.isEmpty {
                self.comments = comments
            } else {
                self.comments = nil
            }

            if let physicalAddress = inDictionary["physical_address"] as? [String: String],
               !((physicalAddress["street"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? "").isEmpty,
               !fixedCoords._isEqualTo(CLLocationCoordinate2D(latitude: 34.23596, longitude: -118.56352), precisionInMeters: 200) { // Since the NAWS office is the default BMLT physical location, we make sure that it is not the specified long/lat.
                let mutableGoPostal = CNMutablePostalAddress()
                mutableGoPostal.street = (physicalAddress["street"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.subLocality = (physicalAddress["neighborhood"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.city = (physicalAddress["city"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.state = (physicalAddress["province"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.subAdministrativeArea = (physicalAddress["county"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.postalCode = (physicalAddress["postal_code"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.country = (physicalAddress["nation"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                self.inPersonAddress = mutableGoPostal
                let locationInfo = (physicalAddress["info"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                self.locationInfo = locationInfo.isEmpty ? nil : locationInfo
                let inPersonVenueName = physicalAddress["name"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.inPersonVenueName = inPersonVenueName.isEmpty ? nil : inPersonVenueName
            } else {
                coords = nil
                self.inPersonAddress = nil
                self.locationInfo = nil
                self.inPersonVenueName = nil
            }

            if let virtualMeetingInfo = inDictionary["virtual_information"] as? [String: String] {
                var splitsville = (virtualMeetingInfo["url"] ?? "").split(separator: "#@-@#")
                var splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let urlStr = cleanURI(urlString: splitString) ?? ""
                if !urlStr.isEmpty,
                   let virtualURL = URL(string: urlStr) {
                    self.virtualURL = virtualURL
                } else {
                    self.virtualURL = nil
                }
                
                splitsville = (virtualMeetingInfo["phone_number"] ?? "").split(separator: "#@-@#")
                splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let virtualPhoneNumber = splitString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !virtualPhoneNumber.isEmpty {
                    self.virtualPhoneNumber = virtualPhoneNumber
                } else {
                    self.virtualPhoneNumber = nil
                }
                
                splitsville = (virtualMeetingInfo["info"] ?? "").split(separator: "#@-@#")
                splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let virtualInfo = splitString.trimmingCharacters(in: .whitespacesAndNewlines)
                self.virtualInfo = virtualInfo.isEmpty ? nil : virtualInfo
            } else {
                self.virtualURL = nil
                self.virtualPhoneNumber = nil
                self.virtualInfo = nil
            }
            
            if (inPersonAddress?.street ?? "").isEmpty,
               (inPersonVenueName ?? "").isEmpty,
               nil == virtualURL,
               (virtualPhoneNumber ?? "").isEmpty {
                return nil
            }
            
            self.coords = coords
        }

        // MARK: Public Interface
        
        /* ############################################################################################################################## */
        // MARK: Meeting Type Enum
        /* ############################################################################################################################## */
        /**
         This provides values for the type of meeting.
         */
        public enum MeetingType: String {
            /* ############################################# */
            /**
             The meeting only gathers virtually.
             */
            case virtual

            /* ############################################# */
            /**
             The meeting only gathers in-person.
             */
            case inPerson

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually.
             */
            case hybrid
        }
        
        /* ############################################################################################################################## */
        // MARK: Meeting Type Enum
        /* ############################################################################################################################## */
        /**
         This has the type of meeting, but in a sortable manner.
         */
        public enum SortableMeetingType: Int, Comparable {
            /* ############################################# */
            /**
             Comparable Conformance
             - parameter lhs: The left-hand side of the comparison
             - parameter rhs: The right-hand side of the comparison
             - returns: True, if lhs < rhs.
             */
            public static func < (lhs: SwiftBMLSDK_Parser.Meeting.SortableMeetingType, rhs: SwiftBMLSDK_Parser.Meeting.SortableMeetingType) -> Bool { lhs.rawValue < rhs.rawValue }
            
            /* ############################################# */
            /**
             The meeting only gathers in-person.
             */
            case inPerson

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, by both phone and video.
             */
            case hybrid

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, but only via video.
             */
            case hybrid_video

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, but only via phone.
             */
            case hybrid_phone

            /* ############################################# */
            /**
             The meeting only gathers virtually, by both phone and video.
             */
            case virtual

            /* ############################################# */
            /**
             The meeting only gathers virtually, and only by video.
             */
            case virtual_video

            /* ############################################# */
            /**
             The meeting only gathers virtually, and only by phone.
             */
            case virtual_phone
        }

        /* ############################################################################################################################## */
        // MARK: Organization Type Enum
        /* ############################################################################################################################## */
        /**
         This specifies the organization for the meeting.
         */
        public enum Organization: String, Codable {
            /* ############################################# */
            /**
             No organization specified
             */
            case none

            /* ############################################# */
            /**
             Narcotics Anonymous
             */
            case na
        }

        // MARK: Public Instance Properties
        
        /* ################################################# */
        /**
         This is the unique ID (within the found set) for the data source server.
         */
        public let serverID: Int
        
        /* ################################################# */
        /**
         This is a unique ID (within the data source server) for this meeting.
         */
        public let localMeetingID: Int
        
        /* ################################################# */
        /**
         This is a 1-based weekday index, with 1 being Sunday, and 7 being Saturday.
         */
        public let weekday: Int
        
        /* ################################################# */
        /**
         This is the time of day that the meeting starts (date-independent).
         */
        public let startTime: Date
        
        /* ################################################# */
        /**
         This is the duration, in seconds, of the meeting.
         */
        public let duration: TimeInterval
        
        /* ################################################# */
        /**
         This is the local timezone of this meeting.
         */
        public let timeZone: TimeZone
        
        /* ################################################# */
        /**
         This is the name of the meeting.
         */
        public let name: String

        /* ################################################# */
        /**
         This is the organization to which this meeting belongs.
         */
        public let organization: Organization
        
        /* ################################################# */
        /**
         This contains an array of formats that apply to the meeting.
         */
        public let formats: [Format]

        // MARK: Public Optional Instance Properties
        
        /* ################################################# */
        /**
         This is the physical location of this meeting, or a location used to determine local timezone. It is optional.
         */
        public let coords: CLLocationCoordinate2D?
        
        /* ################################################# */
        /**
         This is any additional comments for the meeting. It is optional.
         */
        public let comments: String?
        
        /* ################################################# */
        /**
         This is the name for an in-person venue. It is optional.
         */
        public let inPersonVenueName: String?
        
        /* ################################################# */
        /**
         This is a physical address of an in-person meeting. It is optional.
         */
        public let inPersonAddress: CNPostalAddress?

        /* ################################################# */
        /**
         This is any additional text, describing the location. It is optional.
         */
        public let locationInfo: String?
        
        /* ################################################# */
        /**
         This is a URL for a virtual meeting. It is optional.
         */
        public let virtualURL: URL?
        
        /* ################################################# */
        /**
         This is a phone number for a virtual meeting. It is optional.
         */
        public let virtualPhoneNumber: String?
        
        /* ################################################# */
        /**
         This is any additional text, describing the virtual meeting. It is optional.
         */
        public let virtualInfo: String?
        
        // MARK: Public Computed Properties
        
        /* ################################################# */
        /**
         This is a unique ID (within the found set) for this meeting, based on the two local IDs.
         */
        public var id: UInt64 { (UInt64(serverID) << 44) + UInt64(localMeetingID) }

        /* ################################################# */
        /**
         The meeting type.
         */
        public var meetingType: MeetingType {
            if (!(inPersonVenueName ?? "").isEmpty || !(inPersonAddress?.street ?? "").isEmpty),
               !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return .hybrid
            } else if !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return .virtual
            } else {
                return .inPerson
            }
        }

        /* ################################################# */
        /**
         The meeting type, as a sortable value.
         */
        public var sortableMeetingType: SortableMeetingType {
            if (!(inPersonVenueName ?? "").isEmpty || !(inPersonAddress?.street ?? "").isEmpty),
               !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return  (!(virtualURL?.absoluteString ?? "").isEmpty && (virtualPhoneNumber ?? "").isEmpty) ? .hybrid_video :
                ((virtualURL?.absoluteString ?? "").isEmpty && !(virtualPhoneNumber ?? "").isEmpty) ? .hybrid_phone : .hybrid
            } else if !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return  (!(virtualURL?.absoluteString ?? "").isEmpty && (virtualPhoneNumber ?? "").isEmpty) ? .virtual_video :
                ((virtualURL?.absoluteString ?? "").isEmpty && !(virtualPhoneNumber ?? "").isEmpty) ? .virtual_phone : .virtual
            } else {
                return .inPerson
            }
        }

        /* ################################################# */
        /**
         The start time, in local meeting timezone, as a military-style integer (HHMM).
         
         Returns -1, if the time could not be calculated.
         */
        public var integerStartTime: Int {
            let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
            
            guard let hour = components.hour,
                  (0..<24).contains(hour),
                  let minute = components.minute,
                  (0..<60).contains(minute)
            else { return -1 }
            
            return (hour * 100) + minute
        }
        
        /* ################################################# */
        /**
         The start time, adjusted to user timezone, as a military-style integer (HHMM).
         
         Returns -1, if the time could not be calculated.
         */
        public var adjustedIntegerStartTime: Int {
            var mutableSelf = self
            let starter = mutableSelf.getNextStartDate(isAdjusted: true)
            let components = Calendar.current.dateComponents([.hour, .minute], from: starter)
            
            guard let hour = components.hour,
                  (0..<24).contains(hour),
                  let minute = components.minute,
                  (0..<60).contains(minute)
            else { return -1 }
            
            return (hour * 100) + minute
        }

        /* ################################################# */
        /**
         Returns the meeting location as a CLLocation.
         > NOTE: This may return nil, as not all meetings have a location.
         */
        public var location: CLLocation? {
            guard let lat = coords?.latitude,
                  let lng = coords?.longitude,
                  CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            else { return nil }
            return CLLocation(latitude: lat, longitude: lng)
        }
    }

    // MARK: Public Immutable Properties
    
    /* ################################################# */
    /**
     The page metadata for this page of meetings.
     */
    public let meta: PageMeta
    
    /* ################################################# */
    /**
     The meeting data for this page of meetings.
     */
    public let meetings: [Meeting]
}

/* ###################################################################################################################################### */
// MARK: - Meeting Equatable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Equatable {
    /* ############################################# */
    /**
     Public Equatable Conformance
     
     - parameter lhs: The left-hand side of the comparison.
     - parameter rhs: The right-hand side of the comparison.
     */
    public static func == (lhs: SwiftBMLSDK_Parser.Meeting, rhs: SwiftBMLSDK_Parser.Meeting) -> Bool { lhs.id == rhs.id }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Hashable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Hashable {
    /* ############################################# */
    /**
     Public Hashable Conformance
     
     - parameter into: (INOUT) -The hasher to be loaded.
     */
    public func hash(into inOutHasher: inout Hasher) { inOutHasher.combine(id) }
}

/* ###################################################################################################################################### */
// MARK: - Meeting CustomStringConvertible Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: CustomStringConvertible {
    /* ############################################# */
    /**
     Public CustomStringConvertible Conformance
     */
    public var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: startTime)
        var ret = "Meeting:\n\t"
        ret += "id:\t\(id)\n\t"
        ret += "serverID:\t\(serverID)\n\t"
        ret += "localMeetingID:\t\(localMeetingID)\n\t"
        ret += "weekday:\t\(weekday)\n\t"
        ret += "startTime:\t\(timeString)\n\t"
        ret += "duration:\t\(duration)\n\t"
        ret += "timeZone:\t\(timeZone.debugDescription)\n\t"
        ret += "organization:\t\(organization.rawValue)\n\t"
        ret += "name:\t\(name)\n\t"
        ret += "formats:\n\(formats.map { $0.debugDescription }.joined(separator: "\n"))\n\t"
        
        if let coords = coords {
            ret += "coords:\t(latitude: \(coords.latitude), longitude: \(coords.longitude))\n\t"
        }
        
        if let comments = comments,
           !comments.isEmpty {
            ret += "comments:\t\(comments)\n\t"
        }

        if let locationInfo = locationInfo,
           !locationInfo.isEmpty {
            ret += "locationInfo:\t\(locationInfo)\n\t"
        }

        if let virtualURL = virtualURL?.absoluteString,
           !virtualURL.isEmpty {
            ret += "virtualURL:\t\(virtualURL)\n\t"
        }

        if let virtualPhoneNumber = virtualPhoneNumber,
           !virtualPhoneNumber.isEmpty {
            ret += "virtualPhoneNumber:\t\(virtualPhoneNumber)\n\t"
        }

        if let virtualInfo = virtualInfo,
           !virtualInfo.isEmpty {
            ret += "virtualInfo:\t\(virtualInfo)\n\t"
        }

        if let inPersonVenueName = inPersonVenueName,
           !inPersonVenueName.isEmpty {
            ret += "inPersonVenueName:\t\(inPersonVenueName)\n\t"
        }

        if nil != inPersonAddress,
           !basicInPersonAddress.isEmpty {
            ret += "inPersonAddress:\t\(basicInPersonAddress)\n\t"
        }

        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting CustomDebugStringConvertible Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: CustomDebugStringConvertible {
    /* ############################################# */
    /**
     Public CustomDebugStringConvertible Conformance
     */
    public var debugDescription: String { description }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Encodable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Encodable {
    /* ############################################################################################################################## */
    // MARK: Codable Coding Keys
    /* ############################################################################################################################## */
    /**
     This defines the keys that we use for encoding and decoding.
     
     This struct was inspired by [this SO answer](https://stackoverflow.com/a/50715560/879365)
     */
    private struct _CustomCodingKeys: CodingKey {
        /* ############################################# */
        /**
         We only keep a string.
         */
        var stringValue: String

        /* ############################################# */
        /**
         We can initialize with a string.
         */
        init?(stringValue inStringValue: String) { stringValue = inStringValue }

        /* ############################################# */
        /**
         We define this, but it won't be used.
         */
        var intValue: Int?

        /* ############################################# */
        /**
         The integer variant always fails.
         */
        init?(intValue: Int) { nil }
    }
    
    /* ############################################# */
    /**
     Encoder
     
     The reason for the "flat" encoding, is that many ML parsers like fairly simple data, without nesting.
     Nested structures, like the coordinates and the formats, are converted to top-level basic data types, so that a JSON file, made from the encoder, is simple and flat.
     
     Formats are encoded into a TDV string, with the fields being tab-separated, and the formats being linefeed-separated.
     
     If a value is not valid, it is not included in the encoding.
     
     - parameter to: The encoder to load with our values.
     */
    public func encode(to inEncoder: Encoder) throws {
        guard (1..<8).contains(weekday) else { return }
        
        var container = inEncoder.container(keyedBy: _CustomCodingKeys.self)
        
        try container.encode(id, forKey: _CustomCodingKeys(stringValue: "id")!)

        // These three must always be present.
        try container.encode(serverID, forKey: _CustomCodingKeys(stringValue: "serverID")!)
        
        try container.encode(localMeetingID, forKey: _CustomCodingKeys(stringValue: "localMeetingID")!)
        
        // These are included in the encoder, but we don't care about them, for the decoder.
        try container.encode(id, forKey: _CustomCodingKeys(stringValue: "id")!)
        let typeString = meetingType.rawValue
        if !typeString.isEmpty {
            try container.encode(typeString, forKey: _CustomCodingKeys(stringValue: "meetingType")!)
        }

        if (1..<8).contains(weekday) {
            try container.encode(weekday, forKey: _CustomCodingKeys(stringValue: "weekdayInt")!)
            // We hardcode, to provide consistency.
            let weekdayString = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][weekday - 1]
            try container.encode(weekdayString, forKey: _CustomCodingKeys(stringValue: "weekdayString")!)
        }
        
        // We hardcode, to provide consistency.
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: startTime)
        if !timeString.isEmpty {
            try container.encode(timeString, forKey: _CustomCodingKeys(stringValue: "startTime")!)
        }
        
        if 0 < duration {
            try container.encode(duration, forKey: _CustomCodingKeys(stringValue: "duration")!)
        }
        
        let tzString = timeZone.identifier
        if !tzString.isEmpty {
            try container.encode(tzString, forKey: _CustomCodingKeys(stringValue: "timezone")!)
        }
        
        let orgString = organization.rawValue
        if !orgString.isEmpty {
            try container.encode(orgString, forKey: _CustomCodingKeys(stringValue: "organization")!)
        }
        
        if !name.isEmpty {
            try container.encode(name, forKey: _CustomCodingKeys(stringValue: "name")!)
        }
        
        if !formats.isEmpty {
            var formatIndex = 0
            
            try formats.forEach {
                let formatString = $0.asString
                if !formatString.isEmpty {
                    try container.encode(formatString, forKey: _CustomCodingKeys(stringValue: "format-\($0.id)")!)
                    formatIndex += 1
                }
            }
        }
        
        if let comments = comments,
           !comments.isEmpty {
            try? container.encode(comments, forKey: _CustomCodingKeys(stringValue: "comments")!)
        }
        
        if let locationInfo = locationInfo,
           !locationInfo.isEmpty {
            try? container.encode(locationInfo, forKey: _CustomCodingKeys(stringValue: "locationInfo")!)
        }
        
        if let virtualURL = virtualURL?.absoluteString,
           !virtualURL.isEmpty {
            try? container.encode(virtualURL, forKey: _CustomCodingKeys(stringValue: "virtualURL")!)
        }
        
        if let virtualPhoneNumber = virtualPhoneNumber,
           !virtualPhoneNumber.isEmpty {
            try? container.encode(virtualPhoneNumber, forKey: _CustomCodingKeys(stringValue: "virtualPhoneNumber")!)
        }
        
        if let virtualInfo = virtualInfo,
           !virtualInfo.isEmpty {
            try? container.encode(virtualInfo, forKey: _CustomCodingKeys(stringValue: "virtualInfo")!)
        }

        if let latitude = coords?.latitude,
           let longitude = coords?.longitude {
            try? container.encode(Double(round(1000000.0 * latitude) / 1000000.0), forKey: _CustomCodingKeys(stringValue: "coords_lat")!)
            try? container.encode(Double(round(1000000.0 * longitude) / 1000000.0), forKey: _CustomCodingKeys(stringValue: "coords_lng")!)
        }
        
        if let inPersonVenueName = inPersonVenueName,
           !inPersonVenueName.isEmpty {
            try? container.encode(inPersonVenueName, forKey: _CustomCodingKeys(stringValue: "inPersonVenueName")!)
        }
        
        if let string = inPersonAddress?.street,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_street")!)
        }
        
        if let string = inPersonAddress?.subLocality,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_subLocality")!)
        }
        
        if let string = inPersonAddress?.city,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_city")!)
        }
        
        if let string = inPersonAddress?.state,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_state")!)
        }
        
        if let string = inPersonAddress?.subAdministrativeArea,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_subAdministrativeArea")!)
        }
        
        if let string = inPersonAddress?.postalCode,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_postalCode")!)
        }
        
        if let string = inPersonAddress?.country,
           !string.isEmpty {
            try? container.encode(string, forKey: _CustomCodingKeys(stringValue: "inPersonAddress_country")!)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic interpretation methods to the base class.
 */
extension SwiftBMLSDK_Parser.Meeting {
    // MARK: Public Computed Properties
    
    /* ################################################################## */
    /**
     True, if the meeting has a virtual component.
     */
    public var hasVirtual: Bool { .virtual == meetingType || .hybrid == meetingType }
    
    /* ################################################################## */
    /**
     True, if the meeting has an in-person component.
     */
    public var hasInPerson: Bool { .inPerson == meetingType || .hybrid == meetingType }
    
    /* ################################################# */
    /**
     This returns the start time as seconds from midnight.
     
     It returns -1, if there was a problem.
     */
    public var startTimeInSecondsFromMidnight: TimeInterval {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        guard let startHour = components.hour,
              let startMinute = components.minute,
              (0..<24).contains(startHour),
              (0..<60).contains(startMinute)
        else { return -1 }
        return TimeInterval(startHour * 3600 + startMinute * 60)
    }
    
    /* ################################################# */
    /**
     This returns the start time and weekday as date components.
     */
    public var dateComponents: DateComponents? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        guard let startHour = components.hour,
              let startMinute = components.minute
        else { return nil}
        return DateComponents(calendar: .current, hour: startHour, minute: startMinute, weekday: weekday)
    }

    /* ################################################# */
    /**
     This returns the address as a basic readable address.
     */
    public var basicInPersonAddress: String {
        var ret = inPersonVenueName ?? ""
        if let postalAddress = inPersonAddress {
            let formatter = CNPostalAddressFormatter()
            formatter.style = .mailingAddress
            
            ret += (!ret.isEmpty ? "\n" : "") + formatter.string(from: postalAddress)
        }

        return ret
    }
    
    // MARK: Public Non-Mutating Instance Methods
    
    /* ################################################################## */
    /**
     Returns the linear distance, in meters, between the input coordinate, and the meeting's coordinate.
     
     > NOTE: May return nil, as not all meetings have a valid coordinate.
     
     - parameter from: The coordinates of the location we are comparing to the meeting's location.
     - returns: An optional (may be nil) float, with the exact distance between the meeting's location, and the input. It is always positive (or 0), if not nil.
     */
    public func distanceInMeters(from inFrom: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let myLocation = location,
              CLLocationCoordinate2DIsValid(inFrom)
        else { return nil }
        
        return myLocation.distance(from: CLLocation(latitude: inFrom.latitude, longitude: inFrom.longitude))
    }
    
    /* ################################################################## */
    /**
     Returns the number of seconds until the meeting starts (non-mutating. If the cache has not been updated, then this is not accurate).
     */
    public var nextMeetingIn: TimeInterval {
        let adjustedNow = Date.now._convert(from: .current, to: timeZone)
        if let cachedDate = _cachedNextDate,
           adjustedNow < cachedDate {
            var ret = adjustedNow.distance(to: cachedDate)
            
            if 0 > ret {
                ret = floor(ret)
            } else {
                ret = ceil(ret)
            }
        
            return ret
        }
        
        return 0
    }

    // MARK: Public Mutating Instance Methods

    /* ################################################################## */
    /**
     Returns the number of seconds until the meeting starts.
     
     - returns: The number of seconds, before the next start.
     */
    mutating public func meetingStartsIn() -> TimeInterval {
        let now = Date.now
        let meetingStartTime = getNextStartDate(isAdjusted: true)
        var ret = now.distance(to: meetingStartTime)
        
        if 0 > ret {
            ret = floor(ret)
        } else {
            ret = ceil(ret)
        }
    
        return ret
    }

    /* ################################################################## */
    /**
     Returns true, if the meeting is currently in progress.
     
     > NOTE: This is possibly an expensive (in performance) operation, as it may reset the cache.
     
     - returns: The number of seconds, before the next start.
     */
    mutating public func isMeetingInProgress() -> Bool {
        let meetingStartTime = getPreviousStartDate(isAdjusted: true)
        let meetingEndTime = meetingStartTime.addingTimeInterval(duration)
        
        return (meetingStartTime..<meetingEndTime).contains(.now)
    }

    /* ################################################################## */
    /**
     This is the start time of the next meeting, in the meeting's local timezone (unless `isAdjusted` is true).
     
     The meeting's start date is always compared to our local time, so that means, for example, if we are at Eastern Time (US), and the meeting is at Central Time (US), and starts at 8PM (local),
     then, if we check at 8PM (Eastern), the next meeting start will be at 8PM, the same day (Central). If we are at Central Time, and the meeting is at Eastern Time, then checking at 8PM (Central),
     will show us the meeting starting at 8PM, the next day (In the Eastern Time zone). If isAdjusted is true, then the result will be 9PM (today), and 7PM (tomorrow) (User local), respectively.
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the next meeting (can be ignored, for purposes of updating the cache).
     
     > NOTE: If the date is invalid, then the distant future will be returned.
     */
    @discardableResult
    mutating public func getNextStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        let adjustedNow = Date.now._convert(from: .current, to: timeZone)

        if let cachedDate = _cachedNextDate,
           adjustedNow > cachedDate {
            _cachedNextDate = nil
        }
        
        // We make the components from scratch, because that's faster.
        let hour = integerStartTime / 100
        let minute = integerStartTime - (hour * 100)
        
        let dateComp = DateComponents(hour: hour, minute: minute, weekday: weekday)
        
        // The reason for all the cache shenanigans, is because `Calendar.current.nextDate` is REALLY EXPENSIVE, in regards to performance, so we try to use a cache, where possible.
        if let nextDate = _cachedNextDate ?? Calendar.current.nextDate(after: adjustedNow, matching: dateComp, matchingPolicy: .nextTimePreservingSmallerComponents) {
            _cachedNextDate = nextDate
            return inAdjust ? nextDate._convert(from: timeZone, to: .current) : nextDate
        }
        
        return Date.distantFuture
    }
    
    /* ################################################################## */
    /**
     This is the start time of the previous meeting, in the meeting's local timezone (unless `isAdjusted` is true).
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the last meeting.

     > NOTE: If the date is invalid, then the distant past will be returned.
     */
    mutating public func getPreviousStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        let nextStart = getNextStartDate(isAdjusted: inAdjust)
        
        guard .distantFuture > nextStart else { return .distantPast }
        
        return nextStart.addingTimeInterval(-Self.oneWeekInSeconds)
    }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension -
/* ###################################################################################################################################### */
/**
 This extension allows us to perform additional operations on an Array of meetings.
 */
public extension Array where Element == SwiftBMLSDK_Parser.Meeting {
    /* ################################################################################################################################## */
    // MARK: Weekday Filtering Enum
    /* ################################################################################################################################## */
    /**
     This defines a 1-based Gregorian weekday specification.
     All meetings consider 1 to be Sunday, so the local week start should be converted (see init, below).
     */
    enum Weekdays: Int {
        /* ############################################# */
        /**
         Sunday
         */
        case sunday = 1
        
        /* ############################################# */
        /**
         Monday
         */
        case monday
        
        /* ############################################# */
        /**
         Tuesday
         */
        case tuesday
        
        /* ############################################# */
        /**
         Wednesday
         */
        case wednesday

        /* ############################################# */
        /**
         Thursday
         */
        case thursday

        /* ############################################# */
        /**
         Friday
         */
        case friday

        /* ############################################# */
        /**
         Saturday
         */
        case saturday
        
        /* ############################################# */
        /**
         This allows us to set the weekday as adjusted from our locale.
         - parameter rawValue: 1 -> 7, with 1 being the first day of the week.
         - parameter isAdjusted: Optional (default is true), telling the initializer to adjust from the current locale week start, to the 1 == Sunday start, required by the meeting instance.
         */
        init?(rawValue inRawValue: Int, isAdjusted inIsAdjusted: Bool = true) {
            var rawVal = inRawValue
            
            if inIsAdjusted {
                rawVal = rawVal - Calendar.current.firstWeekday + 1
                if 1 > rawVal {
                    rawVal += 7
                }
            }
            
            self.init(rawValue: rawVal)
        }
    }
    
    /* ################################################# */
    /**
     Subscript that allows us to specify a particular meeting type.
     - parameter inMeetingType: The type of meeting we are looking for.
     */
    subscript(_ inMeetingType: SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType) -> [SwiftBMLSDK_Parser.Meeting] {
        switch inMeetingType {
        case .hybrid:
            return compactMap { .hybrid == $0.meetingType ? $0 : nil }
            
        case .virtual(let isExclusive):
            return compactMap { .virtual == $0.meetingType ? $0 : (isExclusive ? nil : (.hybrid == $0.meetingType ? $0 : nil)) }
            
        case .inPerson(let isExclusive):
            return compactMap { .inPerson == $0.meetingType ? $0 : (isExclusive ? nil : (.hybrid == $0.meetingType ? $0 : nil)) }

        default:
            return self
        }
    }

    /* ################################################# */
    /**
     Subscript that allows us to filter for multiple weekdays.
     - parameter inWeekdaySet: The weekdays to filter for. This is in the local meeting timezone.
     */
    subscript(_ inWeekdaySet: Set<Weekdays>) -> [SwiftBMLSDK_Parser.Meeting] {
        guard !inWeekdaySet.isEmpty else { return self }
        return compactMap {
            guard let meetingWeekday = Weekdays(rawValue: $0.weekday) else { return nil }
            return inWeekdaySet.contains(meetingWeekday) ? $0 : nil
        }
    }

    /* ################################################# */
    /**
     Subscript that allows us to filter for a single weekday. This is in the local meeting timezone.
     - parameter inWeekday: The weekday to filter for. This is in the local meeting timezone.
     */
    subscript(_ inWeekday: Weekdays) -> [SwiftBMLSDK_Parser.Meeting] { self[Set<Weekdays>([inWeekday])] }

    /* ################################################# */
    /**
     Subscript that allows us to filter for meetings that start within a certain time range. This is in the local meeting timezone.
     
     - parameter inStartTimeRangeInSecondsFromMidnight: An open range, of start times, 0..<86400.
     */
    subscript(_ inStartTimeRangeInSecondsFromMidnight: Range<TimeInterval>) -> [SwiftBMLSDK_Parser.Meeting] {
        guard 0 <= inStartTimeRangeInSecondsFromMidnight.lowerBound,
              86400 >= inStartTimeRangeInSecondsFromMidnight.upperBound
        else { return [] }
        return compactMap { inStartTimeRangeInSecondsFromMidnight.contains($0.startTimeInSecondsFromMidnight) ? $0 : nil }
    }

    /* ################################################# */
    /**
     This returns the entire meeting list as a simple, 2-dimensional, JSON Data instance. The data is a simple sequence of single-dimension dictionaries.
     
     This is different from the input JSON, as it has the organization and "cleaning" provided by the parser. It also keeps it at 2 dimensions, for easy integration into ML stuff.
     */
    var asJSONData: Data? { try? JSONEncoder().encode(self) }
}

/* ###################################################################################################################################### */
// MARK: - Parser Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic filtering and conversion options to the parser.
 */
public extension SwiftBMLSDK_Parser {
    /* ################################################# */
    /**
     Returns meetings that have an in-person component.
     */
    var inPersonMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.inPerson(isExclusive: false)] }
    
    /* ################################################# */
    /**
     Returns meetings that are only in-person.
     */
    var inPersonOnlyMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.inPerson(isExclusive: true)] }

    /* ################################################# */
    /**
     Returns meetings that have a virtual component.
     */
    var virtualMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.virtual(isExclusive: false)] }

    /* ################################################# */
    /**
     Returns meetings that are only virtual.
     */
    var virtualOnlyMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.virtual(isExclusive: true)] }

    /* ################################################# */
    /**
     Returns meetings that are only hybrid.
     */
    var hybridMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.hybrid] }
}
