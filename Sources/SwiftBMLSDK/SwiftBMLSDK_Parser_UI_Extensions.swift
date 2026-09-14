/*
 © Copyright 2024 - 2026, Little Green Viper Software Development LLC
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

#if canImport(UIKit) && !os(watchOS)
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
        String(self).filter { $0.isASCII && $0.isNumber }
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
     An app-specific URL for a recognized meeting link, or nil.

     On iOS and iPadOS, access this property on the main thread. The SDK checks
     `UIApplication.canOpenURL`; the host app must allow the relevant schemes in
     `LSApplicationQueriesSchemes`: `zoomus`, `lmi-g2m`, `skype`, `gmeet`, `discord`,
     or `org.jitsi.meet`. On macOS and watchOS, the URL is generated without checking
     whether an application is installed. `SKIP_CANOPEN` bypasses the check for testing.
     A generated link does not guarantee that the service or installed app accepts it.
     */
    var directAppURI: URL? { get }
}

/* ###################################################################################################################################### */
// MARK: - Collection Class for Managing Virtual Meetings -
/* ###################################################################################################################################### */
/**
 This class can be used to manage meetings in the user's local timezone. It is especially useful for virtual meetings.
 
 Initialization fetches virtual and hybrid meetings once. Cached dates are absolute instants;
 format them in the user's timezone for display. The underlying meetings retain their original
 schedules and timezones. This mutable collection is intended for use on the main thread.
 
 This is a class, so we don't go making too many massive copies of the data. We can store this as a reference.
 */
public class SwiftBMLSDK_MeetingLocalTimezoneCollection {
    /* ################################################# */
    /**
     This clears the cache, and makes a new call, to get the meetings.
     
     - parameter query: A query instance, primed with the meeting server.
     - parameter completion: An escaping tail completion proc, with a single parameter (this instance). Called asynchronously on the main queue.
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
     Cached meetings from the initial virtual-and-hybrid fetch, in server order. Callers may replace this array; no automatic network refresh occurs.
     */
    private var _meetings = [CachedMeeting]()
    
    // MARK: Public SDK Properties and Methods
    
    /* ################################################# */
    /**
     The callback after the initial fetch, including failure. A failed fetch leaves an empty collection; use the query API directly if you need the error. Called asynchronously on the main queue.
     
     - parameter collection: The populated collection, or an empty collection on failure.
     */
    public typealias FetchCallback = (_ collection: SwiftBMLSDK_MeetingLocalTimezoneCollection) -> Void
    
    /* ################################################# */
    /**
     Each meeting is an instance, associated with the date of the next occurrence.
     When the cached start is reached or passed, the next access recalculates it. Replacing the meeting also refreshes the cached date.
     */
    public class CachedMeeting {
        /* ############################################# */
        /**
         This is the stored next date property.
         */
        private var _cachedNextDate: Date
        
        /* ############################################# */
        /**
         The underlying meeting. Assigning a replacement immediately recalculates ``nextDate``.
         */
        public var meeting: SwiftBMLSDK_Parser.Meeting {
            didSet { _cachedNextDate = meeting.nextOccurrenceDateFast() }
        }
        
        /* ############################################# */
        /**
         This is a smart accessor for the next date. If the cached date has passed,
         we fetch it again before returning it.
         */
        public var nextDate: Date {
            guard .now < _cachedNextDate else {
                _cachedNextDate = meeting.nextOccurrenceDateFast()
                return _cachedNextDate
            }
            
            return _cachedNextDate
        }

        /* ############################################# */
        /**
         This returns `true` if the meeting is currently in progress.
         */
        public var isInProgress: Bool { meeting.isMeetingInProgress() }
        
        /* ############################################# */
        /**
         Initializer. The meeting is immediately asked for the next date.
         
         - parameter inMeeting: The meeting instance to be stored here.
         */
        public init(meeting inMeeting: SwiftBMLSDK_Parser.Meeting) {
            meeting = inMeeting
            _cachedNextDate = meeting.nextOccurrenceDateFast()
        }
    }
    
    // MARK: Public Computed Properties
    
    /* ################################################# */
    /**
     Cached meetings from the initial virtual-and-hybrid fetch, in server order. Callers may replace this array; no automatic network refresh occurs.
     */
    public var meetings: [CachedMeeting] {
        get { _meetings }
        set { _meetings = newValue }
    }
    
    /* ################################################# */
    /**
     These are meetings that have both a virtual component, and an in-person (physical location) component.
     */
    public var hybridMeetings: [CachedMeeting] { meetings.filter { .hybrid == $0.meeting.meetingType } }
    
    /* ################################################# */
    /**
     These are virtual-only meetings (no physical location).
     */
    public var virtualMeetings: [CachedMeeting] { meetings.filter { .virtual == $0.meeting.meetingType } }
    
    // MARK: Public Initializers
    
    /* ################################################# */
    /**
     initializer, with a URL to the server.
     
     Instantiating this class executes an immediate fetch.
     
     - parameter inServerURL: The URL to the meeting server.
     - parameter inCompletion: An escaping tail completion proc, with a single parameter (this instance). Called asynchronously on the main queue.
     */
    public init(serverURL inServerURL: URL, completion inCompletion: @escaping FetchCallback) {
        _fetchMeetings(query: SwiftBMLSDK_Query(serverBaseURI: inServerURL), completion: inCompletion)
    }
    
    /* ################################################# */
    /**
     initializer, with a prepared query.
     
     Instantiating this class executes an immediate fetch.
     
     - parameter inQuery: A "primed" query instance (an instance that has a server URL).
     - parameter inCompletion: An escaping tail completion proc, with a single parameter (this instance). Called asynchronously on the main queue.
     */
    public init(query inQuery: SwiftBMLSDK_Query, completion inCompletion: @escaping FetchCallback) {
        _fetchMeetings(query: inQuery, completion: inCompletion)
    }
}

/* ###################################################################################################################################### */
// MARK: Public Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_MeetingLocalTimezoneCollection {
    /* ################################################# */
    /**
     Rebuilds the occurrence caches for the currently stored meetings. This does not fetch new data from the server. Call on the main thread; the optional completion is dispatched asynchronously to the main queue.
     
     - parameter inCompletion: An optional, simple, one-parameter (This instance) tail completion proc. Always called in the main thread.
     */
    public func refreshCaches(completion inCompletion: ((_: SwiftBMLSDK_MeetingLocalTimezoneCollection) -> Void)? = nil) {
        meetings = meetings.map { CachedMeeting(meeting: $0.meeting) }
        DispatchQueue.main.async { inCompletion?(self) }
    }
}

/* ###################################################################################################################################### */
// MARK: - UIKit Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension uses UIKit to determine the proper app for app-specific URIs.
 */
extension SwiftBMLSDK_Parser.Meeting: SwiftBMLSDK_MeetingProtocol {
    // MARK: Public API
    
    /* ################################################################################################################################## */
    // MARK: Public Enum For Virtual Direct URLs
    /* ################################################################################################################################## */
    /**
     Identifies the SDK's app-link converters. Each case can hold a source web URL; a case without a URL is a service descriptor and does not produce a link.
     */
    public enum DirectVirtual: CaseIterable {
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
         Jitsi
         */
        case jitsi(_: URL? = nil)

        /* ############################################# */
        /**
         CaseIterable Conformance
         */
        public static var allCases: [SwiftBMLSDK_Parser.Meeting.DirectVirtual] { [.zoom(nil), .gotomeeting(nil), .skype(nil), .meet(nil), .discord(nil), .jitsi(nil)] }
        
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

            case .jitsi:
                return "org.jitsi.meet"
            }
        }

        /* ############################################# */
        /**
         This returns a URL to open the relevant app for the URI.
         
         If the app is not installed on the phone, then nil is returned.
         */
        internal var directURL: URL? {
            let ret: URL?
            switch self {
            case .zoom(let url):
                guard let url = url,
                      let conference = url.pathComponents.map({ $0._decimalOnly }).first(where: { $0.count > 8 }) else { return nil }
                var components = URLComponents()
                components.scheme = _serviceProtocol
                components.host = "zoom.us"
                components.path = "/join"
                components.queryItems = [URLQueryItem(name: "confno", value: conference)]
                if let password = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "pwd" })?.value {
                    components.queryItems?.append(URLQueryItem(name: "pwd", value: password))
                }
                ret = components.url

            case .gotomeeting(let url):
                guard let conference = url?.pathComponents.map({ $0._decimalOnly }).first(where: { $0.count > 8 }) else { return nil }
                ret = URL(string: "\(_serviceProtocol)://gotomeeting.com/join/\(conference)")

            case .skype(let url), .meet(let url), .jitsi(let url):
                guard let url = url,
                      var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      components.path.split(separator: "/").count > 0,
                      !(components.host ?? "").isEmpty else { return nil }
                components.scheme = _serviceProtocol
                ret = components.url

            case .discord(let url):
                guard let url = url else { return nil }
                var path = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
                if path.first == "channels" { path.removeFirst() }
                guard !path.isEmpty else { return nil }
                var components = URLComponents()
                components.scheme = _serviceProtocol
                components.host = "channels"
                components.path = "/" + path.joined(separator: "/")
                ret = components.url
            }

            #if canImport(UIKit) && !os(watchOS)
                guard let ret = ret,
                      nil == getenv("SKIP_CANOPEN"),
                      UIApplication.shared.canOpenURL(ret)
                else { return nil != getenv("SKIP_CANOPEN") ? ret : nil }
            #endif
            
            return ret
        }
        
        /* ############################################# */
        /**
         This is a factory function that returns the appropriate enum case. It returns nil, if none are available.
         
         - parameter url: The URL to check.
         - returns: The enum case ( or nil, if none).
         */
        internal static func factory(url inURL: URL) -> DirectVirtual? {
            guard let host = inURL.host?.lowercased(),
                  ["https", "http"].contains(inURL.scheme?.lowercased() ?? "") else { return nil }
            func matches(_ domain: String) -> Bool { host == domain || host.hasSuffix("." + domain) }
            let result: DirectVirtual?
            if matches("zoom.us") || matches("zoomgov.com") {
                result = .zoom(inURL)
            } else if matches("gotomeeting.com") {
                result = .gotomeeting(inURL)
            } else if matches("skype.com") {
                result = .skype(inURL)
            } else if host == "meet.google.com" {
                result = .meet(inURL)
            } else if matches("discordapp.com") || matches("discord.com") {
                result = .discord(inURL)
            } else if host == "meet.jit.si" || host == "jitsi.meet" {
                result = .jitsi(inURL)
            } else {
                result = nil
            }
            return result?.directURL == nil ? nil : result
        }

        // MARK: Public Computed Properties
        
        /* ############################################# */
        /**
         A localization key, such as `SLUG-DIRECT-URI-ZOOM`. The host application supplies the translated app name; the SDK does not localize this string.
         */
        public var appName: String {
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

            case .jitsi:
                return "SLUG-DIRECT-URI-JITSI"
            }
        }
    }

    /* ################################################# */
    /**
     The recognized app-link service for ``virtualURL``, or nil if its HTTPS URL is unsupported, malformed, or unavailable according to the platform check.
     */
    public var directApp: DirectVirtual? {
        guard let virtualURL = virtualURL,
              "https" == virtualURL.scheme?.lowercased()
        else { return nil }
        
        return DirectVirtual.factory(url: virtualURL)
    }

    /* ################################################# */
    /**
     An app-specific URL for a recognized meeting link, or nil.

     On iOS and iPadOS, access this property on the main thread. The SDK checks
     `UIApplication.canOpenURL`; the host app must allow the relevant schemes in
     `LSApplicationQueriesSchemes`: `zoomus`, `lmi-g2m`, `skype`, `gmeet`, `discord`,
     or `org.jitsi.meet`. On macOS and watchOS, the URL is generated without checking
     whether an application is installed. `SKIP_CANOPEN` bypasses the check for testing.
     A generated link does not guarantee that the service or installed app accepts it.
     */
    public var directAppURI: URL? { directApp?.directURL }

    /* ################################################# */
    /**
     A best-effort `tel:` URL from ``virtualPhoneNumber``, normalized with PhoneNumberKit.

     Unprefixed numbers use the US region. International numbers should include `+` and
     a country code. Explicit pauses and numeric meeting IDs or PINs are retained; `#`
     is percent-encoded so it remains dial data. Ambiguous strings containing multiple
     distinct numbers return nil. This does not check whether the device can place calls.
     Documentation-only builds without PhoneNumberKit return nil.
     */
    public var directPhoneURI: URL? { virtualPhoneURL }

}

/* ###################################################################################################################################### */
// MARK: - Array Extension, for Arrays of meetings -
/* ###################################################################################################################################### */
public extension Array where Element == SwiftBMLSDK_Parser.Meeting {
    /* ################################################# */
    /**
     This returns all of the location coordinates in an array of meeting instances.
     */
    var allCoords: [CLLocationCoordinate2D] { compactMap { $0.coords } }
}
