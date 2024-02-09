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
import Contacts     // For the postal address

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
// MARK: - Public Special Array Extension for Summarizing Data -
/* ###################################################################################################################################### */
public extension Array where Element == MeetingJSONParser.Meeting {
    /* ################################################# */
    /**
     This returns the entire list as a simple, 2-dimensional, JSON Data instance. The data is a simple sequence of single-dimension dictionaries.
     
     This is different from the input JSON, as it has the organization and "cleaning" provided by the parser. It also keeps it at 2 dimensions, for easy integration into ML stuff.
     */
    var jsonData: Data? { try? JSONEncoder().encode(self) }

    /* ################################################# */
    /**
     This reduces the entire array into a tagged String data table array.
     
     This aggregates columns. The key is the column name, and the array are all the values that apply to that column.
     */
    var taggedStringSummary: [String: [String]] {
        var ret = [String: [String]]()
        
        forEach { meeting in
            meeting.taggedStringData.forEach { key, value in
                if var prev = ret[key] {
                    prev.append(value)
                    ret[key] = prev
                } else {
                    ret[key] = [value]
                }
            }
        }
        
        return ret
    }
    
    /* ################################################# */
    /**
     Returns meetings that have an in-person component.
     */
    var inPersonMeetings: [MeetingJSONParser.Meeting] {
        compactMap { .hybrid == $0.meetingType || .inPerson == $0.meetingType ? $0 : nil }
    }
    
    /* ################################################# */
    /**
     Returns meetings that are only in-person.
     */
    var inPersonOnlyMeetings: [MeetingJSONParser.Meeting] {
        compactMap { .inPerson == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that have a virtual component.
     */
    var virtualMeetings: [MeetingJSONParser.Meeting] {
        compactMap { .hybrid == $0.meetingType || .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only virtual.
     */
    var virtualOnlyMeetings: [MeetingJSONParser.Meeting] {
        compactMap { .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only hybrid.
     */
    var hybridMeetings: [MeetingJSONParser.Meeting] {
        compactMap { .hybrid == $0.meetingType ? $0 : nil }
    }
}

/* ###################################################################################################################################### */
// MARK: - Public Meeting JSON Page Parser -
/* ###################################################################################################################################### */
/**
 This struct will accept raw JSON data from one page of results from the `LGV_MeetingServer`, and parse it into a immutable struct instance.
 
 You use this by instantiating with the failable init (at the end of the file), with the JSON data from the server, as the only argument.
 
 The parser then automatically populates a `meta` instance, that reports the page metadata from the server, and a `meetings` array, of all meeting instances, and some functional interfaces.
 
 This parser has no dependencies, other than the Foundation, CoreLocation, and Contacts SDKs, provided by Apple. It is Codable, but should really be decoded, as opposed to encoded.
 */
public struct MeetingJSONParser: Codable {
    /* ################################################################################################################################## */
    // MARK: Page Metadata Container
    /* ################################################################################################################################## */
    /**
     This struct holds metadata about the page of meeting results, as reported by the server.
     */
    public struct PageMeta: Codable {
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
    public struct Meeting: Codable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
        /* ############################################################################################################################## */
        // MARK: Format Information Container
        /* ############################################################################################################################## */
        /**
         This struct holds a parsed format information instance.
         */
        public struct Format: Codable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
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
            }

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
             Returns the format, as single string, with values separarated by tabs.
             */
            public var asString: String { "\(key)\t\(name)\t\(description)\t\(language)" }
            
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
            public init(key inKey: String, name inName: String, description inDescription: String, language inLanguage: String) throws {
                self.key = inKey
                self.name = inName
                self.description = inDescription
                self.language = inLanguage
            }

            /* ############################################# */
            /**
             A failable initializer. This initializer parses "raw" format data, and populates the instance properties.
             
             - parameter inDictionary: A simple String-keyed dictionary of partly-parsed values.
             */
            public init?(_ inDictionary: [String: Any]) {
                self.key = (inDictionary["key"] as? String) ?? ""
                self.name = (inDictionary["name"] as? String) ?? ""
                self.description = (inDictionary["description"] as? String) ?? ""
                self.language = (inDictionary["language"] as? String) ?? ""
            }
            
            // MARK: Codable Conformance
            
            /* ############################################# */
            /**
             Decodable initializer
             
             - parameter from: The decoder to use as a source of values.
             */
            public init(from inDecoder: Decoder) throws {
                let container: KeyedDecodingContainer<_CodingKeys> = try inDecoder.container(keyedBy: _CodingKeys.self)
                self.key = try container.decode(String.self, forKey: .key)
                self.name = try container.decode(String.self, forKey: .name)
                self.description = try container.decode(String.self, forKey: .description)
                self.language = try container.decode(String.self, forKey: .language)
            }
            
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
            }
            
            /* ############################################# */
            /**
             CustomDebugStringConvertible Conformance
             */
            public var debugDescription: String { String(self.description) }
        }

        /* ############################################################################################################################## */
        // MARK: Codable Coding Keys
        /* ############################################################################################################################## */
        /**
         This defines the keys that we use for encoding and decoding.
         */
        private enum _CodingKeys: String, CodingKey {
            /* ############################################# */
            /**
             This is a unique ID (within the found set) for this meeting.
             */
            case id
            
            /* ############################################# */
            /**
             This is the unique ID (within the found set) for the data source server.
             */
            case serverID
            
            /* ############################################# */
            /**
             This is a unique ID (within the data source server) for this meeting.
             */
            case localMeetingID
            
            /* ############################################# */
            /**
             This is the basic meeting type (in-person, virtual, or hybrid).
             */
            case meetingType

            /* ############################################# */
            /**
             This is a 1-based weekday index.
             */
            case weekday
            
            /* ############################################# */
            /**
             This is the time of day that the meeting starts.
             */
            case startTime
            
            /* ############################################# */
            /**
             This is the duration, in seconds, of the meeting.
             */
            case duration
            
            /* ############################################# */
            /**
             This is the local timezone of this meeting.
             */
            case timezone
            
            /* ############################################# */
            /**
             This is the organization to which this meeting belongs.
             */
            case organization
            
            /* ############################################# */
            /**
             The latitude of the meeting.
             */
            case coords_lat = "latitude"
            
            /* ############################################# */
            /**
             The longitude of the meeting.
             */
            case coords_lng = "longitude"

            /* ############################################# */
            /**
             This is the name of the meeting.
             */
            case name
            
            /* ############################################# */
            /**
             This is any additional comments for the meeting.
             */
            case comments
            
            /* ############################################# */
            /**
             This the venue name for the in-person meeting.
             */
            case inPersonVenueName
            
            /* ############################################# */
            /**
             This the street address for the in-person meeting.
             */
            case inPersonAddress_street

            /* ############################################# */
            /**
             This the neighborhood for the in-person meeting.
             */
            case inPersonAddress_subLocality
            
            /* ############################################# */
            /**
             This the municipality for the in-person meeting.
             */
            case inPersonAddress_city
            
            /* ############################################# */
            /**
             This the province/state for the in-person meeting.
             */
            case inPersonAddress_state
            
            /* ############################################# */
            /**
             This the county for the in-person meeting.
             */
            case inPersonAddress_subAdministrativeArea
            
            /* ############################################# */
            /**
             This the postal code for the in-person meeting.
             */
            case inPersonAddress_postalCode
            
            /* ############################################# */
            /**
             This the nation for the in-person meeting.
             */
            case inPersonAddress_country
            
            /* ############################################# */
            /**
             This is any additional text, describing the location.
             */
            case locationInfo
            
            /* ############################################# */
            /**
             This is a URL for a virtual meeting.
             */
            case virtualURL
            
            /* ############################################# */
            /**
             This is a phonr number for a virtual meeting.
             */
            case virtualPhoneNumber
            
            /* ############################################# */
            /**
             This is any additional text, describing the virtual meeting.
             */
            case virtualInfo
            
            /* ############################################# */
            /**
             This contains an array of formats that apply to the meeting.
             */
            case formats
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
            case na = "NA"
        }
        
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
         This provides the object as "tagged" data, but all values as String.
         */
        public var taggedStringData: [String: String] {
            var ret = [String: String]()
            
            taggedFlatData.forEach { key, value in
                ret[key] = "\(value)"
            }
            
            return ret
        }

        /* ################################################# */
        /**
         This provides the object as "tagged" data, with all values atomic (not nested).
         */
        public var taggedFlatData: [String: Encodable] {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            var ret: [String: Encodable] = [
                "id": id,
                "name": name,
                "organization": organization.rawValue,
                "meetingType": meetingType.rawValue,
                "weekday": weekday,
                "startTime": formatter.string(from: self.startTime),
                "duration": duration,
                "timezone": timeZone.identifier,
                "serverID": serverID,
                "localMeetingID": localMeetingID
            ]
            
            if let comments = comments,
               !comments.isEmpty {
                ret["comments"] = comments
            }
            
            if let locationInfo = locationInfo,
               !locationInfo.isEmpty {
                ret["locationInfo"] = locationInfo
            }
            
            if let virtualURL = virtualURL?.absoluteString,
               !virtualURL.isEmpty {
                ret["virtualURL"] = virtualURL
            }
            
            if let virtualPhoneNumber = virtualPhoneNumber,
               !virtualPhoneNumber.isEmpty {
                ret["virtualPhoneNumber"] = virtualPhoneNumber
            }
            
            if let virtualInfo = virtualInfo,
               !virtualInfo.isEmpty {
                ret["virtualInfo"] = virtualInfo
            }
            
            if let coords = coords,
               CLLocationCoordinate2DIsValid(coords) {
                ret["latitude"] = coords.latitude
                ret["longitude"] = coords.longitude
            }
            
            if !basicInPersonAddress.isEmpty {
                ret["inPersonAddress"] = basicInPersonAddress
            }
            
            if !formats.isEmpty {
                ret["formats"] = formats.map { $0.asString }.joined(separator: "\n")
            }
            
            return ret
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

        /* ################################################################## */
        /**
         This returns the next meeting start time, in the meeting's timezone.
         */
        public var nextStart: Date { getNextStartDate() }

        /* ################################################################## */
        /**
         This returns the next meeting start time, adjusted from the meeting's timezone, to ours.
         */
        public var nextLocalStart: Date { getNextStartDate(isAdjusted: true) }

        // MARK: Instance Methods
        
        /* ################################################################## */
        /**
         This is the start time of the next meeting, in the meeting's local timezone. By default, the date will have the meeting's timezone set, but it can adjust to our local timezone.
         
         - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
         - returns: The date of the next meeting.
         
         > NOTE: If the date is invalid, then the distant future will be returned.
         */
        public func getNextStartDate(isAdjusted inAdjust: Bool = false) -> Date {
            guard let dateComponents = dateComponents else { return .distantFuture }
            let nextStartDate = Calendar.current.nextDate(after: .now, matching: dateComponents, matchingPolicy: .nextTimePreservingSmallerComponents)
            
            if inAdjust {
                return nextStartDate?._convert(from: timeZone, to: .current) ?? Date.distantFuture
            } else {
                return nextStartDate ?? .distantFuture
            }
        }
        
        /* ################################################################## */
        /**
         This is the start time of the previous meeting, in the meeting's local timezone. By default, the date will have the meeting's timezone set, but it can adjust to our local timezone.
         
         - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
         - returns: The date of the last meeting.

         > NOTE: If the date is invalid, then the distant past will be returned.
         */
        public func getPreviousStartDate(isAdjusted inAdjust: Bool = false) -> Date {
            guard .distantFuture > getNextStartDate(isAdjusted: inAdjust) else { return .distantPast }
            return getNextStartDate().addingTimeInterval(-(60 * 60 * 24 * 7))
        }

        // MARK: Initializer
                
        /* ################################################# */
        /**
         This is a failable initializer, it parses an input dictionary.
         
         - parameter inDictionary: The semi-parsed JSON record for the meeting.
         */
        public init?(_ inDictionary: [String: Any]) {
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

            if let timezoneStr = inDictionary["time_zone"] as? String ?? TimeZone.current.localizedName(for: .standard, locale: .current) {
                self.timeZone = TimeZone(identifier: timezoneStr) ?? .current
            } else {
                self.timeZone = .current
            }

            if let duration = inDictionary["duration"] as? Int,
               (0..<86400).contains(duration) {
                self.duration = TimeInterval(duration)
            } else {
                self.duration = TimeInterval(3600)
            }

            self.formats = (inDictionary["formats"] as? [[String: Any]] ?? []).compactMap { Format($0) }

            self.name = (inDictionary["name"] as? String) ?? ""

            if let long = inDictionary["longitude"] as? Double,
               let lat = inDictionary["latitude"] as? Double,
               CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                self.coords = CLLocationCoordinate2D(latitude: lat, longitude: long)
            } else {
                self.coords = nil
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
                self.inPersonVenueName = physicalAddress["name"]
            } else {
                self.inPersonAddress = nil
                self.locationInfo = nil
                self.inPersonVenueName = nil
            }

            if let virtualMeetingInfo = inDictionary["virtual_information"] as? [String: String] {
                let urlStr = (virtualMeetingInfo["url"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
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
         Decodable initializer
         
         - parameter from: The decoder to use as a source of values.
         */
        public init(from inDecoder: Decoder) throws {
            let container: KeyedDecodingContainer<_CodingKeys> = try inDecoder.container(keyedBy: _CodingKeys.self)
            serverID = try container.decode(Int.self, forKey: .serverID)
            localMeetingID = try container.decode(Int.self, forKey: .localMeetingID)
            weekday = try container.decode(Int.self, forKey: .weekday)
            startTime = try container.decode(Date.self, forKey: .startTime)
            duration = try container.decode(TimeInterval.self, forKey: .duration)
            timeZone = try container.decode(TimeZone.self, forKey: .timezone)
            let org = try container.decode(String.self, forKey: .organization)
            organization = Organization(rawValue: org) ?? .none
            name = try container.decode(String.self, forKey: .name)
            
            let formatString = try container.decode(String.self, forKey: .formats)
            let splitFormats = [String](formatString.components(separatedBy: "\n"))
            let tempFormats = [Format](splitFormats.compactMap { singleFormatString in
                let splitFormats = [String](singleFormatString.components(separatedBy: "\t"))
                guard 4 == splitFormats.count else { return nil }
                return try? Format(key: splitFormats[0],
                                   name: splitFormats[1],
                                   description: splitFormats[2],
                                   language: splitFormats[3]
                )
            })
            formats = tempFormats
            
            comments = (try? container.decode(String.self, forKey: .comments))
            locationInfo = (try? container.decode(String.self, forKey: .locationInfo))
            
            if let tempURLString = (try? container.decode(String.self, forKey: .virtualURL)) {
                virtualURL = URL(string: tempURLString)
            } else {
                virtualURL = nil
            }
            
            virtualPhoneNumber = (try? container.decode(String.self, forKey: .virtualPhoneNumber))
            virtualInfo = (try? container.decode(String.self, forKey: .virtualInfo))
            
            if let latitude = try? container.decode(CLLocationDegrees.self, forKey: .coords_lat),
               let longitude = try? container.decode(CLLocationDegrees.self, forKey: .coords_lng) {
                let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                if CLLocationCoordinate2DIsValid(coords) {
                    self.coords = coords
                } else {
                    self.coords = nil
                }
            } else {
                coords = nil
            }
            
            if let venueName = try? container.decode(String.self, forKey: .inPersonVenueName) {
                inPersonVenueName = venueName
            } else {
                inPersonVenueName = nil
            }
            
            if let street = try? container.decode(String.self, forKey: .inPersonAddress_street),
               let subLocality = try? container.decode(String.self, forKey: .inPersonAddress_subLocality),
               let city = try? container.decode(String.self, forKey: .inPersonAddress_city),
               let state = try? container.decode(String.self, forKey: .inPersonAddress_state),
               let subAdministrativeArea = try? container.decode(String.self, forKey: .inPersonAddress_subAdministrativeArea),
               let postalCode = try? container.decode(String.self, forKey: .inPersonAddress_postalCode),
               let country = try? container.decode(String.self, forKey: .inPersonAddress_country) {
                let mutableGoPostal = CNMutablePostalAddress()
                mutableGoPostal.street = street
                mutableGoPostal.subLocality = subLocality
                mutableGoPostal.city = city
                mutableGoPostal.state = state
                mutableGoPostal.subAdministrativeArea = subAdministrativeArea
                mutableGoPostal.postalCode = postalCode
                mutableGoPostal.country = country
                inPersonAddress = mutableGoPostal
            } else {
                inPersonAddress = nil
            }
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
            var container = inEncoder.container(keyedBy: _CodingKeys.self)
            
            // These three must always be present.
            try container.encode(serverID, forKey: .serverID)
            try container.encode(localMeetingID, forKey: .localMeetingID)
            
            // These are included in the encoder, but we don't care about them, for the decoder.
            try container.encode(id, forKey: .id)
            let typeString = meetingType.rawValue
            if !typeString.isEmpty {
                try container.encode(typeString, forKey: .meetingType)
            }

            if 0 < weekday {
                try container.encode(weekday, forKey: .weekday)
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: startTime)
            if !timeString.isEmpty {
                try container.encode(timeString, forKey: .startTime)
            }
            
            if 0 < duration {
                try container.encode(duration, forKey: .duration)
            }
            
            let tzString = timeZone.identifier
            if !tzString.isEmpty {
                try container.encode(tzString, forKey: .timezone)
            }
            
            let orgString = organization.rawValue
            if !orgString.isEmpty {
                try container.encode(orgString, forKey: .organization)
            }
            
            if !name.isEmpty {
                try container.encode(name, forKey: .name)
            }
            
            let formatsString = formats.map { $0.asString }.joined(separator: "\n")
            if !formatsString.isEmpty {
                try container.encode(formatsString, forKey: .formats)
            }
            
            if let comments = comments,
               !comments.isEmpty {
                try? container.encode(comments, forKey: .comments)
            }
            if let locationInfo = locationInfo,
               !locationInfo.isEmpty {
                try? container.encode(locationInfo, forKey: .locationInfo)
            }
            if let virtualURL = virtualURL?.absoluteString,
               !virtualURL.isEmpty {
                try? container.encode(virtualURL, forKey: .virtualURL)
            }
            if let virtualPhoneNumber = virtualPhoneNumber,
               !virtualPhoneNumber.isEmpty {
                try? container.encode(virtualPhoneNumber, forKey: .virtualPhoneNumber)
            }
            if let virtualInfo = virtualInfo,
               !virtualInfo.isEmpty {
                try? container.encode(virtualInfo, forKey: .virtualInfo)
            }

            if let latitude = coords?.latitude,
               let longitude = coords?.longitude {
                try? container.encode(Double(round(1000000.0 * latitude) / 1000000.0), forKey: .coords_lat)
                try? container.encode(Double(round(1000000.0 * longitude) / 1000000.0), forKey: .coords_lng)
            }
            
            if let inPersonVenueName = inPersonVenueName,
               !inPersonVenueName.isEmpty {
                try? container.encode(inPersonVenueName, forKey: .inPersonVenueName)
            }
            if let string = inPersonAddress?.street,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_street)
            }
            if let string = inPersonAddress?.subLocality,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_subLocality)
            }
            if let string = inPersonAddress?.city,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_city)
            }
            if let string = inPersonAddress?.state,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_state)
            }
            if let string = inPersonAddress?.subAdministrativeArea,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_subAdministrativeArea)
            }
            if let string = inPersonAddress?.postalCode,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_postalCode)
            }
            if let string = inPersonAddress?.country,
               !string.isEmpty {
                try? container.encode(string, forKey: .inPersonAddress_country)
            }
        }

        /* ############################################# */
        /**
         CustomDebugStringConvertible Conformance
         */
        public var description: String {
            var ret = "Meeting:\n\t"
            ret += "id: \(id)\n\t"
            ret += "serverID: \(serverID)\n\t"
            ret += "serverID: \(localMeetingID)\n\t"
            ret += "weekday: \(weekday)\n\t"
            ret += "startTime: \(startTime.debugDescription)\n\t"
            ret += "duration: \(duration)\n\t"
            ret += "timeZone: \(timeZone.debugDescription)\n\t"
            ret += "organization: \(organization.rawValue)\n\t"
            ret += "name: \(name)\n\t"
            ret += "formats:\n\t\t\(formats.map { $0.debugDescription + "\n\t\t"})\n\t"
            
            if let coords = coords {
                ret += "coords: (latitude: \(coords.latitude), longitude: \(coords.longitude))\n\t"
            }
            
            if let comments = comments,
               !comments.isEmpty {
                ret += "comments: \(comments)\n\t"
            }

            if let locationInfo = locationInfo,
               !locationInfo.isEmpty {
                ret += "locationInfo: \(locationInfo)\n\t"
            }

            if let virtualURL = virtualURL?.absoluteString,
               !virtualURL.isEmpty {
                ret += "virtualURL: \(virtualURL)\n\t"
            }

            if let virtualPhoneNumber = virtualPhoneNumber,
               !virtualPhoneNumber.isEmpty {
                ret += "virtualPhoneNumber: \(virtualPhoneNumber)\n\t"
            }

            if let virtualInfo = virtualInfo,
               !virtualInfo.isEmpty {
                ret += "virtualInfo: \(virtualInfo)\n\t"
            }

            if let inPersonVenueName = inPersonVenueName,
               !inPersonVenueName.isEmpty {
                ret += "inPersonVenueName: \(inPersonVenueName)\n\t"
            }

            if nil != inPersonAddress,
               !basicInPersonAddress.isEmpty {
                ret += "inPersonAddress: \(basicInPersonAddress)\n\t"
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
        public static func == (lhs: MeetingJSONParser.Meeting, rhs: MeetingJSONParser.Meeting) -> Bool { lhs.id == rhs.id }
        
        /* ############################################# */
        /**
         Hashable Conformance
         
         - parameter into: (INOUT) -The hasher to be loaded.
         */
        public func hash(into inOutHasher: inout Hasher) {
            inOutHasher.combine(id)
            inOutHasher.combine(serverID)
            inOutHasher.combine(localMeetingID)
            inOutHasher.combine(weekday)
            inOutHasher.combine(startTime)
            inOutHasher.combine(duration)
            inOutHasher.combine(timeZone)
            inOutHasher.combine(organization)
            inOutHasher.combine(name)
            inOutHasher.combine(formats)
            inOutHasher.combine(coords?.latitude)
            inOutHasher.combine(coords?.longitude)
            inOutHasher.combine(comments)
            inOutHasher.combine(locationInfo)
            inOutHasher.combine(virtualURL)
            inOutHasher.combine(virtualPhoneNumber)
            inOutHasher.combine(virtualInfo)
            inOutHasher.combine(inPersonAddress)
            inOutHasher.combine(inPersonVenueName)
        }
    }
    
    // META: Private Static Functions
    
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
    
    // MARK: Public Constant Properties
    
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
}
