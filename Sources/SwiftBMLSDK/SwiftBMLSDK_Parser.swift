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

import CoreLocation // For coordinates.
import Contacts     // For the in-person address

/* ###################################################################################################################################### */
// MARK: - Baseline Meeting JSON Page Parser -
/* ###################################################################################################################################### */
/**
 This struct will accept raw JSON data from one page of results from the [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and parse it into an immutable struct instance.
 
 This is a **baseline** parser; it doesn't really do anything more than make a simple map of the input JSON into an array of structs. It doesn't change the sorting, and provides a read-only, struct property view.
 
 You use this by instantiating with the public init, with the JSON data from the server, as the only argument.
 
 The parser then automatically populates a `meta` instance, that reports the page metadata from the server, and a `meetings` array, of all meeting instances, and some functional interfaces.
 
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
    
    // MARK: - Exported Public Interface -
    
    // MARK: Public Initializer
    
    /* ################################################# */
    /**
     This is a failable initializer. It parses the JSON data.
     
     - parameter jsonData: A Data instance, with the raw JSON dump.
     */
    public init?(jsonData inJSONData: Data) {
        guard let simpleJSON = try? JSONSerialization.jsonObject(with: inJSONData, options: [.allowFragments]) as? NSDictionary,
              let metaJSON = simpleJSON["meta"] as? [String: Any],
              let meta = Self._parseMeta(metaJSON),
              let meetingsJSON = simpleJSON["meetings"] as? [[String: Any]],
              !meetingsJSON.isEmpty
        else { return nil }
        self.meta = meta
        self.meetings = meetingsJSON.compactMap { Self._parseMeeting($0) }
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
        
        /* ############################################# */
        /**
         Default Initializer.
         
         - parameters:
             - actualSize: This is the actual size of this single page of results, in results (not bytes).
             - pageSize: This is the number of results allowed as a maximum, per page, in results.
             - startingIndex: This is the 0-based starting index, of the total found set (in results), for this page.
             - total: This is the total size of all results in the found set.
             - totalPages: This is the total number of pages that contain the found set.
             - page: This is the 0-based index of this page of results.
             - searchTime: This is the number of seconds, reported by the server, to generate this page of results.
         */
        public init(actualSize inActualSize: Int = 0,
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
    }

    /* ################################################################################################################################## */
    // MARK: Meeting Data Container
    /* ################################################################################################################################## */
    /**
     This struct holds a single parsed meeting instance.
     */
    public struct Meeting: Encodable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
        /* ############################################################################################################################## */
        // MARK: Format Information Container
        /* ############################################################################################################################## */
        /**
         This struct holds a parsed format information instance.
         */
        public struct Format: Codable, CustomStringConvertible, CustomDebugStringConvertible, Hashable, Comparable {
            /* ########################################################################################################################## */
            // MARK: Codable Coding Keys
            /* ########################################################################################################################## */
            /**
             This defines the keys that we use for encoding and decoding.
             */
            private enum _CodingKeys: String, CodingKey {
                /* ######################################### */
                /**
                 This is the short format "key" string.
                 */
                case key
                
                /* ######################################### */
                /**
                 This is the short name for the format.
                 */
                case name

                /* ######################################### */
                /**
                 This is the longer description of the format.
                 */
                case description

                /* ######################################### */
                /**
                 This is the [ISO 639-2](https://www.loc.gov/standards/iso639-2/php/code_list.php) code for the language used for the name and description.
                 */
                case language

                /* ######################################### */
                /**
                 This is the local server ID of the format. We use a String, even though it comes as an Int.
                 */
                case id
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
            public var asString: String { "\(key)\t\(name)\t\(description)" } // \t\(language)\t\(id)" } These confuse ML.
            
            // MARK: Initializers
            
            /* ############################################# */
            /**
             Default initializer
             
             - parameters:
                - key: The format key
                - name: The short format name
                - description: The longer format description
                - language: The language code.
             */
            public init(key inKey: String, name inName: String, description inDescription: String, language inLanguage: String, id inID: String) {
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
            public init(_ inDictionary: [String: Any]) {
                self.init(key: (inDictionary["key"] as? String) ?? "", name: (inDictionary["name"] as? String) ?? "", description: (inDictionary["description"] as? String) ?? "", language: (inDictionary["language"] as? String) ?? "", id: String((inDictionary["id"] as? Int) ?? 0))
            }
            
            // MARK: Comparable Conformance
            
            /* ############################################# */
            /**
             We simply sort by key, so there's consistency in the ordering.
             
             - parameter lhs: The left-hand side of the comparison.
             - parameter rhs: The right-hand side of the comparison.
             
             - returns: True, if the lhs ID is less than the rhs ID.
             */
            public static func < (lhs: Format, rhs: Format) -> Bool { lhs.key < rhs.key }
            
            // MARK: Encodable Conformance
            
            /* ############################################# */
            /**
             Encoder
             
             - parameter to: The encoder to load with our values.
             */
            public func encode(to inEncoder: Encoder) throws {
                var container = inEncoder.container(keyedBy: _CodingKeys.self)
                try container.encode(key, forKey: .key)
                try container.encode(name, forKey: .name)
                try container.encode(description, forKey: .description)
                try container.encode(language, forKey: .language)
                try container.encode(id, forKey: .id)
            }
            
            /* ############################################# */
            /**
             CustomDebugStringConvertible Conformance
             */
            public var debugDescription: String { "\t\t(\(key))\t\(name)\t(\(language))\n\t\t\t\t\(description)\n\t\t\t\t\(id)" }
        }

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
        
        // MARK: Private Property
        
        /* ################################################# */
        /**
         This is actually meant to be used by the `getNextStartDate()` extension method, but Swift [wisely] doesn't let stored properties get declared in extensions.
         */
        private var _cachedNextDate: Date?

        // MARK: Required Instance Properties
        
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

        // MARK: Optional Instance Properties
        
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
         This is a phonr number for a virtual meeting. It is optional.
         */
        public let virtualPhoneNumber: String?
        
        /* ################################################# */
        /**
         This is any additional text, describing the virtual meeting. It is optional.
         */
        public let virtualInfo: String?
        
        // MARK: Computed Properties
        
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
            if (nil != inPersonAddress) || (nil != inPersonVenueName && !inPersonVenueName!.isEmpty),
               (nil != virtualURL && !virtualURL!.absoluteString.isEmpty) || (nil != virtualPhoneNumber && !virtualPhoneNumber!.isEmpty) {
                return .hybrid
            } else if nil != inPersonAddress || (nil != inPersonVenueName && !inPersonVenueName!.isEmpty) {
                return .inPerson
            } else {
                return .virtual
            }
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

        // MARK: Initializer
                
        /* ################################################# */
        /**
         This is a failable initializer, it parses an input dictionary.
         
         - parameter inDictionary: The semi-parsed JSON record for the meeting.
         */
        public init?(_ inDictionary: [String: Any]) {
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
            
            let durationTemp = inDictionary["duration"] as? Int ?? 3600
            self.duration = (0..<86400).contains(durationTemp) ? TimeInterval(durationTemp) : TimeInterval(3600)

            self.formats = (inDictionary["formats"] as? [[String: Any]] ?? []).compactMap { Format($0) }.sorted()

            self.name = (inDictionary["name"] as? String) ?? ""

            if let long = inDictionary["longitude"] as? Double,
               let lat = inDictionary["latitude"] as? Double,
               CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                self.coords = CLLocationCoordinate2D(latitude: lat, longitude: long)
            } else {
                self.coords = nil
            }

            if let timezoneStr = inDictionary["time_zone"] as? String,
               let tz = TimeZone(identifier: timezoneStr) {
                self.timeZone = tz
            } else {
                self.timeZone = .current
            }

            if let comments = inDictionary["comments"] as? String,
               !comments.isEmpty {
                self.comments = comments
            } else {
                self.comments = nil
            }

            if let physicalAddress = inDictionary["physical_address"] as? [String: String] {
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
                self.inPersonAddress = nil
                self.locationInfo = nil
                self.inPersonVenueName = nil
            }

            if let virtualMeetingInfo = inDictionary["virtual_information"] as? [String: String] {
                let urlStr = cleanURI(urlString: virtualMeetingInfo["url"]) ?? ""
                if !urlStr.isEmpty,
                   let virtualURL = URL(string: urlStr) {
                    self.virtualURL = virtualURL
                } else {
                    self.virtualURL = nil
                }
                
                let virtualPhoneNumber = (virtualMeetingInfo["phone_number"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                if !virtualPhoneNumber.isEmpty {
                    self.virtualPhoneNumber = virtualPhoneNumber
                } else {
                    self.virtualPhoneNumber = nil
                }
                
                let virtualInfo = (virtualMeetingInfo["info"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                self.virtualInfo = virtualInfo.isEmpty ? nil : virtualInfo
            } else {
                self.virtualURL = nil
                self.virtualPhoneNumber = nil
                self.virtualInfo = nil
            }
        }
        
        // MARK: Codable Conformance
        
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
            var container = inEncoder.container(keyedBy: _CustomCodingKeys.self)
            
            // These three must always be present.
            try container.encode(serverID, forKey: _CustomCodingKeys(stringValue: "serverID")!)
            try container.encode(localMeetingID, forKey: _CustomCodingKeys(stringValue: "localMeetingID")!)
            
            // These are included in the encoder, but we don't care about them, for the decoder.
            try container.encode(id, forKey: _CustomCodingKeys(stringValue: "id")!)
            let typeString = meetingType.rawValue
            if !typeString.isEmpty {
                try container.encode(typeString, forKey: _CustomCodingKeys(stringValue: "meetingType")!)
            }

            if 0 < weekday {
                try container.encode(weekday, forKey: _CustomCodingKeys(stringValue: "weekday")!)
            }
            
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
                        try container.encode(formatString, forKey: _CustomCodingKeys(stringValue: "format-\(formatIndex)")!)
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

        /* ############################################# */
        /**
         CustomStringConvertible Conformance
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

        /* ############################################# */
        /**
         CustomDebugStringConvertible Conformance
         */
        public var debugDescription: String { description }

        /* ############################################# */
        /**
         Equatable Conformance
         
         - parameter lhs: The left-hand side of the comparison.
         - parameter rhs: The right-hand side of the comparison.
         */
        public static func == (lhs: SwiftBMLSDK_Parser.Meeting, rhs: SwiftBMLSDK_Parser.Meeting) -> Bool { lhs.id == rhs.id }
        
        /* ############################################# */
        /**
         Hashable Conformance
         
         - parameter into: (INOUT) -The hasher to be loaded.
         */
        public func hash(into inOutHasher: inout Hasher) { inOutHasher.combine(id) }
    }
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
// MARK: - Parser Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic filtering and conversion options to the parser.
 */
public extension SwiftBMLSDK_Parser {
    /* ################################################# */
    /**
     This returns the entire meeting list as a simple, 2-dimensional, JSON Data instance. The data is a simple sequence of single-dimension dictionaries.
     
     This is different from the input JSON, as it has the organization and "cleaning" provided by the parser. It also keeps it at 2 dimensions, for easy integration into ML stuff.
     */
    var meetingJSONData: Data? { try? JSONEncoder().encode(meetings) }
    
    /* ################################################# */
    /**
     Returns meetings that have an in-person component.
     */
    var inPersonMeetings: [SwiftBMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType || .inPerson == $0.meetingType ? $0 : nil }
    }
    
    /* ################################################# */
    /**
     Returns meetings that are only in-person.
     */
    var inPersonOnlyMeetings: [SwiftBMLSDK_Parser.Meeting] {
        meetings.compactMap { .inPerson == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that have a virtual component.
     */
    var virtualMeetings: [SwiftBMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType || .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only virtual.
     */
    var virtualOnlyMeetings: [SwiftBMLSDK_Parser.Meeting] {
        meetings.compactMap { .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only hybrid.
     */
    var hybridMeetings: [SwiftBMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType ? $0 : nil }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic interpretation methods to the base class.
 */
extension SwiftBMLSDK_Parser.Meeting {
    // MARK: Computed Properties
    
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

    // MARK: Non-Mutating Instance Methods
    
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
    
    // MARK: Mutating Instance Methods
    
    /* ################################################################## */
    /**
     This is the start time of the next meeting, in the meeting's local timezone (unless `isAdjusted` is true).
     
     The meeting's start date is always compared to our local time, so that means, for example, if we are at Eastern Time (US), and the meeting is at Central Time (US), and starts at 8PM (local),
     then, if we check at 8PM (Eastern), the next meeting start will be at 8PM, the same day (Central). If we are at Central Time, and the meeting is at Eastern Time, then checking at 8PM (Central),
     will show us the meeting starting at 8PM, the next day (In the Eastern Time zone). If isAdjusted is true, then the result will be 9PM (today), and 7PM (tomorrow) (User local), respectively.
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the next meeting.
     
     > NOTE: If the date is invalid, then the distant future will be returned.
     */
    mutating public func getNextStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        // The reason for the cache shenanigans, is because the Calendar.nextDate function is REALLY EXPENSIVE, in terms of performance, so we try to minimize the number of times that it's called.
        guard let dateComponents = dateComponents else { return .distantFuture }
        
        // We do this, to cast our current timezone to the meeting's.
        let adjustedNow: Date = .now._convert(from: .current, to: timeZone)
        
        // We do it this way, in case we are not adjusting a meeting in another timezone.
        if let cached = _cachedNextDate,
           cached <= adjustedNow {
            _cachedNextDate = nil
        }
        
        _cachedNextDate = _cachedNextDate ?? Calendar.current.nextDate(after: adjustedNow, matching: dateComponents, matchingPolicy: .nextTimePreservingSmallerComponents)
        
        return inAdjust && (nil != _cachedNextDate) ? _cachedNextDate!._convert(from: timeZone, to: .current) : _cachedNextDate ?? .distantFuture
    }
    
    /* ################################################################## */
    /**
     This is the start time of the previous meeting, in the meeting's local timezone (unless `isAdjusted` is true).
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the last meeting.

     > NOTE: If the date is invalid, then the distant past will be returned.
     */
    mutating public func getPreviousStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        guard .distantFuture > getNextStartDate(isAdjusted: inAdjust) else { return .distantPast }
        return getNextStartDate().addingTimeInterval(-(60 * 60 * 24 * 7))
    }
}
