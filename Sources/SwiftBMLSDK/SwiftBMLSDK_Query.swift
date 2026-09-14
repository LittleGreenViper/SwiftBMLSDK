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
import CoreLocation // For coordinates

/* ###################################################################################################################################### */
// MARK: - Meeting Search Query And Communication -
/* ###################################################################################################################################### */
/**
 This struct is for generating queries to instances of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and returning the parsed results.
 
 It is designed for minimal filtering. Most filter parameters are for paging the search, or filtering for specific meeting types. Most filtering should be performed on the results.
 
 This is the "working" part of the SwiftBMLSDK system. You instantiate an instance of this struct, and everything else comes from that.
 
 # Supported Systems
 
 Supports iOS/iPadOS 16+, macOS 13+, and watchOS 9+. tvOS is unsupported because the public meeting address uses the Contacts framework, which is unavailable there.
 
 Normal builds require Swift tools 5.9 or greater through PhoneNumberKit 5. The SDK uses Swift 5 language mode.

 # Usage
 
 Instantiate this struct with a [URL](https://developer.apple.com/documentation/foundation/url) to an [LGV_MeetingServer](https://github.com/LittleGreenViper/LGV_MeetingServer) implementation.
 
 For example:
 
    `SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://example.org/LGV_MeetingServer/entrypoint.php"))`
 
 creates a query. Replace the example URL with your aggregator's actual entrypoint.
 
 Once the struct is instantiated, it can then be queried. Responses to queries are a ``SwiftBMLSDK_Parser`` instance, which contains and interprets the found set.
 
 There are limited parameters to queries, as it is expected that most of the filtering and sorting will be performed on the found set of meeting instances.
 
 ## Querying the Server
 
 There are only three public query methods:
 
 - ``serverInfo(completion:)``
 This is a method that fetches the general information structure from the server, and presents it as a ``ServerInfo`` struct.
 
 - ``SwiftBMLSDK_Query/meetingSearch(specification:priority:completion:)``
 This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function.
 
 - ``SwiftBMLSDK_Query/meetingAutoRadiusSearch(minimumNumberOfResults:specification:priority:completion:)``
 This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function, but in this case, it does an auto-radius search, extending outwards from the search center (``SearchSpecification/locationCenter``), until the minimum number of meetings specified have been found. The ``SearchSpecification/locationRadius`` specification property is the maximum search radius (If the minimum amount have not been found, by the time the radius reaches this, the search stops, and the current results are returned).

 # Dependencies
 
 The query code uses Foundation and CoreLocation. The package also depends on PhoneNumberKit 5 for phone-number parsing.
 */
public struct SwiftBMLSDK_Query {
    /* ################################################# */
    /**
     This is the completion function for the server info query.
     
     > NOTE: The completion is called asynchronously on the main queue, including when the request cannot be started.
     
     - parameter result: The parsed server information, or nil on failure.
     - parameter error: The transport, HTTP, or decoding error, or nil on success.
     */
    public typealias ServerInfoResultCompletion = (_ result: ServerInfo?, _ error: Error?) -> Void

    /* ################################################# */
    /**
     This is the completion function for the meeting search query.
     
     > NOTE: The completion is called asynchronously on the main queue, including when the request cannot be started.
     
     - parameter result: The parsed response, or nil on failure. An empty meeting page is a successful response.
     - parameter error: The transport, HTTP, or decoding error, or nil on success.
     */
    public typealias QueryResultCompletion = (_ result: SwiftBMLSDK_Parser?, _ error: Error?) -> Void

    /* ################################################################################################################################## */
    // MARK: Server Info Struct
    /* ################################################################################################################################## */
    /**
     This is the response to the general server info query. It contains information about all the individual servers, represented by the aggregator server.
     */
    public struct ServerInfo {
        /* ############################################################################################################################## */
        // MARK: Service Info Struct
        /* ############################################################################################################################## */
        /**
         This breaks down the information for each type of service.
         
         Do not instantiate this. It is provided by the query instance.
         */
        public struct Service {
            /* ########################################################################################################################## */
            // MARK: Server Info Struct
            /* ########################################################################################################################## */
            /**
             This is the information for each server that provides the service.
             
             Do not instantiate this. It is provided by the query instance.
             */
           public struct Server {
               /* ##################################### */
               /**
                The ID of the server.
                */
               public let id: Int

               /* ##################################### */
               /**
                The name of the server.
                */
               public let name: String

               /* ##################################### */
               /**
                The URI of the server access entrypoint.
                */
               public let entryPointURI: URL

               /* ##################################### */
               /**
                The number of meetings provided by this server.
                */
               public let numberOfMeetings: Int

               /* ##################################### */
               /**
                The organization breakdown for this server.
                The key is the organization key, and the value is how many meetings belong to that organization.
                */
               public let organizations: [String: Int]
            }

            /* ######################################### */
            /**
             The name of the service.
             */
            public let name: String

            /* ######################################### */
            /**
             An array of servers that are provided by this service.
             */
            public let servers: [Server]
        }
        
        /* ############################################# */
        /**
         The version of the aggregator server.
         */
        public let server_version: String
        
        /* ############################################# */
        /**
         The last time the aggregator ran an update.
         */
        public let lastUpdate: Date
        
        /* ############################################# */
        /**
         The services provided by the aggregator.
         */
        public let services: [Service]
        
        /* ############################################# */
        /**
         The aggregate organization breakdown.
         */
        public let organizationTotals: [String: Int]
        
        /* ############################################# */
        /**
         The sum of meeting counts in the parsed service/server entries.
         */
        public var totalMeetings: Int {
            services.reduce(0) { current, next in
                current + next.servers.reduce(0) { cur, nxt in
                    return cur + nxt.numberOfMeetings
                }
            }
        }
        
        /* ############################################# */
        /**
         The number of parsed server entries across all services.
         */
        public var totalServers: Int {
            services.reduce(0) { current, next in
                current + next.servers.count
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: Search Specification Struct
    /* ################################################################################################################################## */
    /**
     This struct is what we use to prescribe the search spec.
     
     Search specifications are quite simple. We only have the meeting type, location/radius (for in-person meetings), and paging options (to break up large found sets).
     */
    public struct SearchSpecification {
        /* ############################################# */
        /**
         This returns the query portion of the search (needs to be appended to the server base URI).
         */
        internal var urlQueryItems: [URLQueryItem] {
            var ret: [URLQueryItem] = [URLQueryItem(name: "query", value: nil)]
            
            if 0 <= pageSize {
                ret.append(URLQueryItem(name: "page_size", value: String(pageSize)))
                if 0 < pageSize,
                   0 < pageNumber {
                    ret.append(URLQueryItem(name: "page", value: String(pageNumber)))
                }
            }
            
            if !meetingIDs.isEmpty {
                let ids = meetingIDs.map {
                    let serverID = $0 >> 44
                    let meetingID = $0 & 0x00000FFFFFFFFFFF
                    
                    return "(\(serverID),\(meetingID))"
                }.joined(separator: ",")
                
                ret.append(URLQueryItem(name: "ids", value: ids))
            } else {
                switch type {
                case .any:
                    break
                    
                case .inPerson(let isExclusive):
                    ret.append(URLQueryItem(name: "type", value: String(isExclusive ? 2 : 1)))
                    
                case .virtual(let isExclusive):
                    ret.append(URLQueryItem(name: "type", value: String(isExclusive ? -2 : -1)))
                    if isExclusive {
                        return ret
                    }
                    
                case .hybrid:
                    ret.append(URLQueryItem(name: "type", value: String(3)))
                }
                
                if CLLocationCoordinate2DIsValid(locationCenter),
                   locationRadius.isFinite,
                   0 < locationRadius {
                    ret.append(URLQueryItem(name: "geocenter_lng", value: String(locationCenter.longitude)))
                    ret.append(URLQueryItem(name: "geocenter_lat", value: String(locationCenter.latitude)))
                    ret.append(URLQueryItem(name: "geo_radius", value: String(locationRadius / 1000)))
                }
            }
            
            return ret
        }

        /* ############################################################################################################################## */
        // MARK: Search Specification Type Enum
        /* ############################################################################################################################## */
        /**
         Determines which meeting types we want.
         */
        public enum SearchForMeetingType {
            /* ############################################# */
            /**
             This does not discriminate on any type of meeting. All available meetings are returned.
             */
            case any
            
            /* ############################################# */
            /**
             This returns only meetings that have a physical address.
             - parameter isExclusive: If true, then hybrid meetings are not included. Default is false.
             */
            case inPerson(isExclusive: Bool = false)
            
            /* ############################################# */
            /**
             This returns only meetings that have a virtual component.
             - parameter isExclusive: If true, then hybrid meetings are not included. Default is false.
             */
            case virtual(isExclusive: Bool = false)
            
            /* ############################################# */
            /**
             This returns only meetings that have both a physical and a virtual component.
             */
            case hybrid
        }
        
        /* ############################################# */
        /**
         The number of results per page. If this is 0, then no results are returned, and only the meta is populated. If left out, or set to a negative number, then all results are returned in one page.
         */
        public let pageSize: Int
        
        /* ############################################# */
        /**
         The page number (0-based). If `pageSize` is 0 or less, this is ignored. If over the maximum number of pages, an empty page is returned.
         */
        public let pageNumber: Int
        
        /* ############################################# */
        /**
         The type of meeting.
         */
        public let type: SearchForMeetingType
        
        /* ############################################# */
        /**
         The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search. Nonfinite radii are also ignored. Ignored if the type is exclusive virtual or meeting IDs are supplied.
         */
        public let locationRadius: Double

        /* ############################################# */
        /**
         The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search. Ignored if the type is exclusive virtual.
         */
        public let locationCenter: CLLocationCoordinate2D
        
        /* ############################################# */
        /**
         The composite meeting IDs to fetch. When nonempty, meeting type and location are ignored; paging still applies.
         */
        public let meetingIDs: [UInt64]
        
        /* ############################################# */
        /**
         This is the default initializer. All parameters are optional, with blank/none defaults.
         
         - parameters:
            - inType: The meeting type. Default is any type.
            - inLocationCenter: The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search. Ignored if the type is exclusive virtual.
            - inLocationRadius: The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search. Nonfinite radii are also ignored. Ignored if the type is exclusive virtual or meeting IDs are supplied.
            - inMeetingIDs: If this is not empty, then ``type``, ``locationCenter``, and ``locationRadius`` are all ignored, and the search will be for specific meetings by the IDs passed in. Optional. Default is empty.
            - inPageSize: The number of results per page. If this is 0, then no results are returned, and only the meta is populated. If left out, or set to a negative number, then all results are returned in one page.
            - inPageNumber: The page number (0-based). If `pageSize` is 0 or less, this is ignored. If over the maximum number of pages, an empty page is returned.
         */
        public init(type inType: SearchForMeetingType = .any,
                    locationCenter inLocationCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(),
                    locationRadius inLocationRadius: Double = 0,
                    meetingIDs inMeetingIDs: [UInt64] = [],
                    pageSize inPageSize: Int = -1,
                    page inPageNumber: Int = 0
        ) {
            pageSize = inPageSize
            pageNumber = inPageNumber
            type = inType
            locationRadius = inLocationRadius
            locationCenter = inLocationCenter
            meetingIDs = inMeetingIDs
        }
    }
    
    /* ################################################# */
    /**
     The session that is used to manage interactions with the server.
     */
    private let _session: URLSession
    
    /* ################################################# */
    /**
     This is the entrypoint URL for the target [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) instance.
     */
    private var _serverBaseURI: URL?
    
    /* ################################################# */
    /**
     Default initializer.
     
     - parameter inServerBaseURI: The complete HTTP or HTTPS entrypoint URL of an instance of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer). Optional. Can be omitted.
     */
    public init(serverBaseURI inServerBaseURI: URL? = nil) {
        _serverBaseURI = inServerBaseURI
        let config = URLSessionConfiguration.default
        // This is for working in the simulator. Sometimes, it borks QUIC
        config.httpAdditionalHeaders = ["Alt-Svc": "clear"]
        _session = URLSession(configuration: config)
    }

    /* ################################################# */
    /**
     Initializes a query with an injected session for deterministic request testing.
     */
    internal init(serverBaseURI inServerBaseURI: URL?, session inSession: URLSession) {
        _serverBaseURI = inServerBaseURI
        _session = inSession
    }

    /* ################################################# */
    /**
     Executes a JSON request. The caller delivers its parsed result on the main queue.
     */
    private func _request(queryItems inQueryItems: [URLQueryItem],
                          priority inPriority: Float = URLSessionTask.defaultPriority,
                          completion inCompletion: @escaping (Data?, Error?) -> Void) {
        guard let baseURL = serverBaseURI,
              let scheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = baseURL.host, !host.isEmpty,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            inCompletion(nil, URLError(.badURL))
            return
        }
        components.queryItems = (components.queryItems ?? []) + inQueryItems
        components.fragment = nil
        guard let url = components.url else {
            inCompletion(nil, URLError(.badURL))
            return
        }

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        let task = _session.dataTask(with: request) { data, response, error in
            if let error = error {
                inCompletion(nil, error)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                inCompletion(nil, URLError(.badServerResponse))
                return
            }
            guard (200..<300).contains(response.statusCode) else {
                inCompletion(nil, URLError(.badServerResponse, userInfo: [
                    "HTTPStatusCode": response.statusCode,
                    NSURLErrorFailingURLErrorKey: url
                ]))
                return
            }
            let mimeType = response.mimeType?.lowercased() ?? ""
            guard mimeType == "application/json" || (mimeType.hasPrefix("application/") && mimeType.hasSuffix("+json")),
                  let data = data, !data.isEmpty else {
                inCompletion(nil, URLError(.cannotDecodeContentData))
                return
            }
            inCompletion(data, nil)
        }
        task.priority = inPriority.isFinite ? min(1, max(0, inPriority)) : URLSessionTask.defaultPriority
        task.resume()
    }
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
public extension SwiftBMLSDK_Query {
    /* ################################################# */
    /**
     Accessor for the base URI.
     */
    var serverBaseURI: URL? {
        get { _serverBaseURI }
        set { _serverBaseURI = newValue }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
public extension SwiftBMLSDK_Query {
    /* ################################################# */
    /**
     Fetches the aggregator's version, last update, services, and organization totals.

     Existing query items in ``serverBaseURI`` are preserved. Requests made through
     the same query instance run independently. Malformed individual service or server entries
     are omitted from the parsed lists.

     - parameter inCompletion: Called once, asynchronously on the main queue. The first
       argument contains the response on success; the second contains an error on failure.
       HTTP failures use `URLError.badServerResponse`, with `HTTPStatusCode` in the error's
       `userInfo`. Invalid response data uses `URLError.cannotDecodeContentData`.
     */
    func serverInfo(completion inCompletion: @escaping ServerInfoResultCompletion) {
        _request(queryItems: [URLQueryItem(name: "info", value: nil)]) { data, error in
            guard let data = data else {
                DispatchQueue.main.async { inCompletion(nil, error) }
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let version = json["server_version"] as? String,
                  let lastUpdate = json["last_update_timestamp"] as? TimeInterval,
                  let servicesJSON = json["services"] as? [String: Any],
                  var organizations = json["organizations"] as? [String: Int] else {
                DispatchQueue.main.async { inCompletion(nil, URLError(.cannotDecodeContentData)) }
                return
            }
            organizations.removeValue(forKey: "total_meetings")
            let services = servicesJSON.keys.sorted().compactMap { key -> ServerInfo.Service? in
                guard let service = servicesJSON[key] as? [String: Any],
                      let name = service["service_name"] as? String, !name.isEmpty,
                      let serversJSON = service["servers"] as? [String: Any] else { return nil }
                let servers = serversJSON.keys.compactMap { key -> ServerInfo.Service.Server? in
                    guard let id = Int(key),
                          let server = serversJSON[key] as? [String: Any],
                          let name = server["name"] as? String,
                          let count = server["num_meetings"] as? Int,
                          let urlString = server["url"] as? String,
                          let url = URL(string: urlString),
                          let organizations = server["organizations"] as? [String: Int] else { return nil }
                    return ServerInfo.Service.Server(id: id, name: name, entryPointURI: url,
                                                     numberOfMeetings: count, organizations: organizations)
                }.sorted { $0.id < $1.id }
                return ServerInfo.Service(name: name, servers: servers)
            }
            let info = ServerInfo(server_version: version,
                                  lastUpdate: Date(timeIntervalSince1970: lastUpdate),
                                  services: services, organizationTotals: organizations)
            DispatchQueue.main.async { inCompletion(info, nil) }
        }
    }

    /* ################################################# */
    /**
     Searches for one page of meetings matching a specification.

     Empty and count-only responses return a parser with an empty ``SwiftBMLSDK_Parser/meetings``
     array. Malformed meeting records are skipped, so the parsed count can be less than
     the server's ``SwiftBMLSDK_Parser/PageMeta/actualSize``. Requests run independently;
     starting a search does not cancel another request.

     - parameter inSpecification: Meeting type, IDs, location in meters, and paging options.
     - parameter inPriority: URL session task priority, clamped to 0...1. Default is 0.5;
       nonfinite values also use the default.
     - parameter inCompletion: Called once, asynchronously on the main queue, with either
       a parser or an error. Transport errors are preserved. HTTP failures use
       `URLError.badServerResponse` (`HTTPStatusCode` in `userInfo`); malformed JSON or
       an invalid response schema uses `URLError.cannotDecodeContentData`.
     */
    func meetingSearch(specification inSpecification: SearchSpecification,
                       priority inPriority: Float = URLSessionTask.defaultPriority,
                       completion inCompletion: @escaping QueryResultCompletion) {
        _request(queryItems: inSpecification.urlQueryItems, priority: inPriority) { data, error in
            guard let data = data else {
                DispatchQueue.main.async { inCompletion(nil, error) }
                return
            }
            let parser = SwiftBMLSDK_Parser(jsonData: data, specification: inSpecification)
            DispatchQueue.main.async {
                inCompletion(parser, parser == nil ? URLError(.cannotDecodeContentData) : nil)
            }
        }
    }

    /* ################################################# */
    /**
     Expands a geographic search until enough parsed meetings are found or the maximum
     radius is reached. The final response can contain fewer meetings than requested.

     All distances are in meters. The first radius is the smaller of 100 meters and the
     maximum; each subsequent radius doubles, with a final request at the exact maximum.
     A nonpositive maximum uses 100,000 meters (100 km). Paging is ignored so the target
     count is compared against the complete parsed result. On failure, the search stops
     and returns the error. For ID searches or exclusively virtual searches, location is
     irrelevant and a single ordinary search uses the original specification.

     - parameter inMinNumber: Target number of parsed meetings, clamped to at least one.
     - parameter inSpecification: Search type, center, and maximum radius. A geographic
       search requires valid coordinates and a finite radius; otherwise `.badURL` is returned.
     - parameter inPriority: URL session task priority, clamped to 0...1. Default is 0.5.
     - parameter inCompletion: Called once, asynchronously on the main queue, with the
       successful result (possibly empty) or an error.
     */
    func meetingAutoRadiusSearch(minimumNumberOfResults inMinNumber: Int,
                                 specification inSpecification: SearchSpecification,
                                 priority inPriority: Float = URLSessionTask.defaultPriority,
                                 completion inCompletion: @escaping QueryResultCompletion) {
        if !inSpecification.meetingIDs.isEmpty {
            meetingSearch(specification: inSpecification, priority: inPriority, completion: inCompletion)
            return
        }
        if case .virtual(isExclusive: true) = inSpecification.type {
            meetingSearch(specification: inSpecification, priority: inPriority, completion: inCompletion)
            return
        }
        guard CLLocationCoordinate2DIsValid(inSpecification.locationCenter),
              inSpecification.locationRadius.isFinite else {
            DispatchQueue.main.async { inCompletion(nil, URLError(.badURL)) }
            return
        }
        let targetCount = max(1, inMinNumber)
        let maxRadius = inSpecification.locationRadius > 0 ? inSpecification.locationRadius : 100_000

        func search(at radius: CLLocationDistance) {
            let specification = SearchSpecification(type: inSpecification.type,
                                                    locationCenter: inSpecification.locationCenter,
                                                    locationRadius: radius)
            meetingSearch(specification: specification, priority: inPriority) { parser, error in
                guard let parser = parser, error == nil else {
                    inCompletion(nil, error)
                    return
                }
                if parser.meetings.count >= targetCount || radius >= maxRadius {
                    inCompletion(parser, nil)
                } else {
                    search(at: min(maxRadius, radius * 2))
                }
            }
        }
        search(at: min(100, maxRadius))
    }
}
