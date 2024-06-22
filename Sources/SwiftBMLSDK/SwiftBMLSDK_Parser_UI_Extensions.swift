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
import CoreLocation

#if canImport(UIKit)
    import UIKit
#endif

/* ###################################################################################################################################### */
// MARK: - Utility String Extension -
/* ###################################################################################################################################### */
fileprivate extension StringProtocol {
    /* ################################################################## */
    /**
     This simply strips out all non-decimal characters in the string, leaving only valid decimal digits.
     */
    var _decimalOnly: String {
        let decimalDigits = CharacterSet(charactersIn: "0123456789")
        return String(self).filter {
            // The higher-order function stuff will convert each character into an aggregate integer, which then becomes a Unicode scalar. Very primitive, but shouldn't be a problem for us, as we only need a very limited ASCII set.
            guard let cha = UnicodeScalar($0.unicodeScalars.map { $0.value }.reduce(0, +)) else { return false }
            
            return decimalDigits.contains(cha)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Protocol For Special Computed Properties -
/* ###################################################################################################################################### */
/**
 We have special properties that apply only to specific runtime environments.
 */
public protocol SwiftBMLSDK_MeetingProtocol {
    /* ################################################# */
    /**
     If the URL for the virtual meeting is one that can open an app on the user's device, a direct URL scheme version of the URL is returned.
     */
    var directAppURI: URL? { get }
}

/* ###################################################################################################################################### */
// MARK: - Collection Class for Managing Virtual Meetings -
/* ###################################################################################################################################### */
/**
 This class can be used to manage meetings in the user's local timezone. It is especially useful for virtual meetings.
 
 Virtual meetings are always considered in local (to the user) timezone. We collect all of the meetings at once, and store them here, so they are easier and faster to manage.
 
 This is a class, so we don't go making too many massive copies of the data. We can store this as a reference.
 */
public class SwiftBMLSDK_MeetingLocalTimezoneCollection {
    /* ################################################# */
    /**
     This clears the cache, and makes a new call, to get the meetings.
     
     - parameter query: A query instance, primed with the meeting server.
     - parameter completion: An escaping tail completion proc, with a single parameter (this instance).
     */
    private func _fetchMeetings(query inQuery: SwiftBMLSDK_Query, completion inCompletion: @escaping FetchCallback) {
        meetings = []
        inQuery.meetingSearch(specification: SwiftBMLSDK_Query.SearchSpecification(type: .virtual(isExclusive: false))){ inSearchResults, inError in
            guard nil == inError,
                  let inSearchResults = inSearchResults
            else {
                inCompletion(self)
                return
            }
            
            self.meetings = inSearchResults.meetings.map { CachedMeeting(meeting: $0) }
            
            inCompletion(self)
        }
    }

    /* ################################################# */
    /**
     The callback from the meeting fetch.
     
     - parameter: This collection.
     */
    public typealias FetchCallback = (_: SwiftBMLSDK_MeetingLocalTimezoneCollection) -> Void
    
    /* ################################################# */
    /**
     Each meeting is an instance, associated with the date of the next occurrence.
     If the date is nil, or after now, the meeting is queried for the next ocurrence, and that is cached.
     */
    public class CachedMeeting {
        /* ############################################# */
        /**
         This is the stored next date property.
         */
        private var _cachedNextDate: Date

        /* ############################################# */
        /**
         The meeting is a simple stored property. It needs to be a var, in order to allow date caching (getNextStartDate is mutating).
         */
        public var meeting: SwiftBMLSDK_Parser.Meeting

        /* ############################################# */
        /**
         This is a smart accessor for the next date. If the date has passed, we fetch it again, before returning it.
         */
        public var nextDate: Date {
            guard .now <= _cachedNextDate else { return _cachedNextDate }
            _cachedNextDate = meeting.getNextStartDate(isAdjusted: true)
            return _cachedNextDate
        }

        /* ############################################# */
        /**
         This returns true, if the meeting is currently in progress.
         */
        public var isInProgress: Bool {
            let prevDate = meeting.getPreviousStartDate(isAdjusted: true)
            let lastDate = prevDate.addingTimeInterval(meeting.duration)
            return (prevDate..<lastDate).contains(.now)
        }

        /* ############################################# */
        /**
         Initializer. The meeting is immediately asked for the next date.
         
         - parameter meeting: The meeting instance to be stored here.
         */
        public init(meeting inMeeting: SwiftBMLSDK_Parser.Meeting) {
            meeting = inMeeting
            _cachedNextDate = meeting.getNextStartDate(isAdjusted: true)
        }
    }
    
    /* ################################################# */
    /**
     This is the complete response to the last query. We ask for all of the virtual and hybrid meetings at once from the server, and store them in the order received.
     */
    public var meetings = [CachedMeeting]()

    /* ################################################# */
    /**
     */
    public var hybridMeetings: [CachedMeeting] { meetings.filter { .hybrid == $0.meeting.meetingType } }

    /* ################################################# */
    /**
     */
    public var virtualMeetings: [CachedMeeting] { meetings.filter { .virtual == $0.meeting.meetingType } }

    /* ################################################# */
    /**
     initializer, with a URL to the server.
     
     - parameter serverURL: The URL to the meeting server.
     - parameter completion: An escaping tail completion proc, with a single parameter (this instance).
     */
    public init(serverURL inServerURL: URL, completion inCompletion: @escaping FetchCallback) {
        _fetchMeetings(query: SwiftBMLSDK_Query(serverBaseURI: inServerURL), completion: inCompletion)
    }

    /* ################################################# */
    /**
     initializer, with a prepared query.
     
     - parameter query: A "primed" query instance.
     - parameter completion: An escaping tail completion proc, with a single parameter (this instance).
     */
    public init(query inQuery: SwiftBMLSDK_Query, completion inCompletion: @escaping FetchCallback) {
        _fetchMeetings(query: inQuery, completion: inCompletion)
    }
}

/* ###################################################################################################################################### */
// MARK: - UIKit Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension uses UIKit to determine the proper app for app-specific URIs.
 */
extension SwiftBMLSDK_Parser.Meeting: SwiftBMLSDK_MeetingProtocol {
    /* ################################################################################################################################## */
    // MARK: Private Enum For Virtual Direct URLs
    /* ################################################################################################################################## */
    /**
     This enum helps us to create direct (as in opening the app directly) URLs, for various services.
     */
    private enum _DirectVirtual: CaseIterable {
        /* ############################################# */
        /**
         The Zoom app.
         */
        case zoom(_: URL? = nil)
        
        /* ############################################# */
        /**
         GoToMeeting
         */
        case gotomeeting(_: URL? = nil)
        
        /* ############################################# */
        /**
         Microsoft Skype
         */
        case skype(_: URL? = nil)
        
        /* ############################################# */
        /**
         Google Meet
         */
        case meet(_: URL? = nil)
        
        /* ############################################# */
        /**
         Discord
         */
        case discord(_: URL? = nil)

        /* ############################################# */
        /**
         CaseIterable Conformance
         */
        static var allCases: [SwiftBMLSDK_Parser.Meeting._DirectVirtual] { [.zoom(nil), .gotomeeting(nil), .skype(nil), .meet(nil), .discord(nil)] }
        
        /* ############################################# */
        /**
         This returns the bundle ID (for Mac apps) for the given service.
         */
        private var _appBundleID: String {
            switch self {
            case .zoom:
                return "zoomus"
                
            case .gotomeeting:
                return "lmi-g2m"

            case .skype:
                return "skype"

            case .meet:
                return "gmeet"

            case .discord:
                return "discord"
            }
        }
        
        /* ############################################# */
        /**
         This returns the protocol for the given service.
         */
        private var _serviceProtocol: String {
            switch self {
            case .zoom:
                return "zoomus"

            case .gotomeeting:
                return "lmi-g2m"

            case .skype:
                return "skype"

            case .meet:
                return "gmeet"

            case .discord:
                return "discord"
            }
        }

        /* ############################################# */
        /**
         This returns the host for the given service.
         */
        private var _serviceURLHost: String {
            switch self {
            case .zoom:
                return "zoom.us"

            case .gotomeeting:
                return "gotomeeting.com"

            case .skype:
                return "skype.com"

            case .meet:
                return "meet.google.com"

            case .discord:
                return "discordapp.com"
            }
        }

        /* ############################################# */
        /**
         This returns a localization token for the app name.
         */
        var appName: String {
            switch self {
            case .zoom:
                return "SLUG-DIRECT-URI-ZOOM"

            case .gotomeeting:
                return "SLUG-DIRECT-URI-GOTOMEETING"

            case .skype:
                return "SLUG-DIRECT-URI-SKYPE"

            case .meet:
                return "SLUG-DIRECT-URI-MEET"

            case .discord:
                return "SLUG-DIRECT-URI-DISCORD"
            }
        }

        /* ############################################# */
        /**
         This returns a URL to open the relevant app for the URI.
         
         If the app is not installed on the phone, then nil is returned.
         */
        var directURL: URL? {
            var ret: URL?
            var confNum: String = ""
            
            switch self {
            case .zoom(let inURL):
                guard let query = inURL?.query,
                      !query.isEmpty else { return nil }
                
                let pwd = query.split(separator: "&").reduce("") { (current, next) in
                    if current.isEmpty,
                       next.starts(with: "pwd=") {
                        return String(next[next.index(next.startIndex, offsetBy: 4)...])
                    }
                    
                    return ""
                }
                
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                // Primitive, but it will work. It gets an element that has a run of more than eight positive numeric characters, and assumes that is the conference code.
                // The conference code should come before the password (which might also be a string of numbers).
                // This cleans out query strings.
                let numStringArray: [String] = comp.compactMap {
                    let str = String($0._decimalOnly)
                    
                    return str.isEmpty ? nil : str
                }
                
                for elem in numStringArray where 8 < elem.count {
                    confNum = elem
                    break
                }

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/join?confno=\(confNum)" + (!pwd.isEmpty ? "&pwd=\(pwd)" : "")

                ret = URL(string: retString)

            case .gotomeeting(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                let numStringArray: [String] = comp.compactMap {
                    let str = String($0._decimalOnly)
                    
                    return str.isEmpty ? nil : str
                }
                
                for elem in numStringArray where 8 < elem.count {
                    confNum = elem
                    break
                }

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/join/\(confNum)"

                ret = URL(string: retString)

            case .skype(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                confNum = comp[0]

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/\(confNum)"

                ret = URL(string: retString)

            case .meet(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                confNum = comp[0]

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/\(confNum)"

                ret = URL(string: retString)

            case .discord(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                let guild = comp[1]
                
                if 1 < comp.count {
                    let channel = comp[2]
                    
                    let retString = "\(_serviceProtocol)://channels/\(guild)/\(channel)"
                    
                    ret = URL(string: retString)
                } else {
                    let retString = "\(_serviceProtocol)://channels/\(guild)"
                    
                    ret = URL(string: retString)
                }
            }
            
            #if canImport(UIKit)
                guard let ret = ret,
                      UIApplication.shared.canOpenURL(ret)
                else { return nil }
            #endif
            
            return ret
        }
        
        /* ############################################# */
        /**
         This is a factory function that returns the appropriate enum case. It returns nil, if none are available.
         
         - parameter url: The URL to check.
         - returns: The enum case ( or nil, if none).
         */
        static func factory(url inURL: URL) -> _DirectVirtual? {
            var ret: _DirectVirtual?
            
            if inURL.host?.contains(_DirectVirtual.zoom(nil)._serviceURLHost) ?? false {
                ret = _DirectVirtual.zoom(inURL)
            } else if inURL.host?.contains(_DirectVirtual.gotomeeting(nil)._serviceURLHost) ?? false {
                ret = _DirectVirtual.gotomeeting(inURL)
            } else if inURL.host?.contains(_DirectVirtual.skype(nil)._serviceURLHost) ?? false {
                ret = _DirectVirtual.skype(inURL)
            }
            
            return nil != ret?.directURL ? ret : nil
        }
    }
    
    // MARK: Public API
    
    /* ################################################# */
    /**
     If the URL for the virtual meeting is one that can open an app on the user's device, a direct URL scheme version of the URL is returned.
     */
    public var directAppURI: URL? {
        guard let virtualURL = virtualURL,
              "https" == virtualURL.scheme?.lowercased()
        else { return nil }
        
        return _DirectVirtual.factory(url: virtualURL)?.directURL
    }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension, for Arrays of meetings -
/* ###################################################################################################################################### */
public extension Array where Element==SwiftBMLSDK_Parser.Meeting {
    /* ################################################# */
    /**
     This returns all of the in-person meeting coordinates in an array.
     */
    var allCoords: [CLLocationCoordinate2D] { compactMap { $0.coords } }
}
