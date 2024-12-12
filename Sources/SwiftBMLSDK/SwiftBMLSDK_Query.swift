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

/* ###################################################################################################################################### */
// MARK: - Meeting Search Query And Communication -
/* ###################################################################################################################################### */
/**
 This struct is for generating queries to instances of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and returning the parsed results.
 
 It is designed for minimal filtering. Most filter parameters are for paging the search, or filtering for specific meeting types. Most filtering should be performed on the results.
 
 This is the "working" part of the SwiftBMLSDK system. You instantiate an instance of this struct, and everything else comes from that.
 
 # Supported Systems
 
 This will support iOS 16 (and greater), iPadOS 16 (and greater), tvOS 16 (and greater), macOS 13 (and greater), and watchOS 9 (and greater)
 
 This requires Swift 5 or greater.

 # Usage
 
 Instantiate this struct with a [URL](https://developer.apple.com/documentation/foundation/url) to an [LGV_MeetingServer](https://github.com/LittleGreenViper/LGV_MeetingServer) implementation.
 
 For example:
 
    `SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))`
 
 creates an instance, based on the LGV test server.
 
 Once the struct is instantiated, it can then be queried. Responses to queries are a ``SwiftBMLSDK_Parser`` instance, which contains and interprets the found set.
 
 There are limited parameters to queries, as it is expected that most of the filtering and sorting will be performed on the found set of meeting instances.
 
 ## Querying the Server
 
 There are only three public query methods:
 
 - ``serverInfo(completion:)``
 This is a method that fetches the general information structure from the server, and presents it as a ``ServerInfo`` struct.
 
 - ``meetingSearch(specification:completion:)``
 This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function.
 
 - ``meetingAutoRadiusSearch(minimumNumberOfResults:specification:completion:)``
 This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function, but in this case, it does an auto-radius search, extending outwards from the search center (``SearchSpecification.locationCenter``), until the minimum number of meetings specified have been found. The ``SearchSpecification.locationRadius`` specification property is the maximum search radius (If the minimum amount have not been found, by the time the radius reaches this, the search stops, and the current results are returned).

 # Dependencies
 
 This type has no dependencies, other than the Foundation and CoreLocation SDKs, provided by Apple.
 */
public struct SwiftBMLSDK_Query {
    /* ################################################# */
    /**
     This is the completion function for the server info query.
     
     > NOTE: The completion may be called in any thread!
     
     - parameter: The resultant server response. Can be nil.
     - parameter: Any errors that occurred. Should usually be nil.
     */
    public typealias ServerInfoResultCompletion = (_: ServerInfo?, _: Error?) -> Void

    /* ################################################# */
    /**
     This is the completion function for the meeting search query.
     
     > NOTE: The completion may be called in any thread!
     
     - parameter: The resultant server response. Can be nil.
     - parameter: Any errors that occurred. Should usually be nil.
     */
    public typealias QueryResultCompletion = (_: SwiftBMLSDK_Parser?, _: Error?) -> Void

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
         The total number of meetings in the server.
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
         The total number of servers reached by the server.
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
                    let serverID = Int($0 >> 44)
                    let meetingID = Int($0 & 0x00000FFFFFFFFFFF)
                    
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
                   0 < locationRadius {
                    ret.append(URLQueryItem(name: "geocenter_lng", value: String(locationCenter.longitude)))
                    ret.append(URLQueryItem(name: "geocenter_lat", value: String(locationCenter.latitude)))
                    ret.append(URLQueryItem(name: "geo_radius", value: String(locationRadius / 1000)))
                }
            }
            
            return ret
        }

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
         The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search. Ignored if the type is exclusive virtual.
         */
        public let locationRadius: Double

        /* ############################################# */
        /**
         The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search. Ignored if the type is exclusive virtual.
         */
        public let locationCenter: CLLocationCoordinate2D
        
        /* ############################################# */
        /**
         This returns only meetings that have specific IDs. If this is not empty, then all the other specification parameters are ignored.
         */
        public let meetingIDs: [UInt64]
        
        /* ############################################# */
        /**
         This is the default initializer. All parameters are optional, with blank/none defaults.
         
         - parameters:
            - type: The meeting type. Default is any type.
            - locationCenter: The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search. Ignored if the type is exclusive virtual.
            - locationRadius: The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search. Ignored if the type is exclusive virtual.
            - meetingIDs: If this is not empty, then ``type``, ``locationCenter``, and ``locationRadius`` are all ignored, and the search will be for specific meetings by the IDs passed in. Optional. Default is empty.
            - pageSize: The number of results per page. If this is 0, then no results are returned, and only the meta is populated. If left out, or set to a negative number, then all results are returned in one page.
            - page: The page number (0-based). If `pageSize` is 0 or less, this is ignored. If over the maximum number of pages, an empty page is returned.
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
    private let _session = URLSession(configuration: .default)
    
    /* ################################################# */
    /**
     This is the main directory ("base") URI for the target [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) instance.
     */
    private var _serverBaseURI: URL?
    
    /* ################################################# */
    /**
     Default initializer.
     
     - parameter serverBaseURI: The URL to the "base (main directory) of an instance of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer). Optional. Can be omitted.
     */
    public init(serverBaseURI inServerBaseURI: URL? = nil) {
        _serverBaseURI = inServerBaseURI
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
     Fetches the server info.
     
     - parameter completion: A tail completion proc (may be called in any thread).
     */
    func serverInfo(completion inCompletion: @escaping ServerInfoResultCompletion) {
        guard let baseURLString = serverBaseURI?.absoluteString,
              let url = URL(string: "\(baseURLString)?info")
        else {
            inCompletion(nil, nil)
            return
        }
        
        let urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        
        #if DEBUG
            print("URL Request: \(urlRequest.url?.absoluteString ?? "ERROR")")
        #endif
        _session.dataTask(with: urlRequest) { inData, inResponse, inError in
            guard let response = inResponse as? HTTPURLResponse,
                  nil == inError
            else {
                inCompletion(nil, nil)
                return
            }
            
            if nil == inError {
                switch response.statusCode {
                case 200..<300:
                    if let data = inData,
                       "application/json" == response.mimeType {
                        #if DEBUG
                            print("Response Data: \(data.debugDescription)")
                        #endif
                        if let data = inData,
                           "application/json" == response.mimeType {
                            #if DEBUG
                                print("Response Data: \(data.debugDescription)")
                            #endif
                            guard let simpleJSON = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? NSDictionary,
                                  let version = simpleJSON["server_version"] as? String,
                                  let lastUpdate = simpleJSON["last_update_timestamp"] as? Int,
                                  let servicesWrapper = simpleJSON["services"] as? NSDictionary,
                                  let servicesKeys = servicesWrapper.allKeys as? [String],
                                  let organizationTemp = simpleJSON["organizations"] as? NSDictionary,
                                  var organizationsSrc = organizationTemp as? [String: Int]
                            else {
                                inCompletion(nil, nil)
                                return
                            }
                            
                            organizationsSrc.removeValue(forKey: "total_meetings")
 
                            let services: [ServerInfo.Service] = servicesKeys.sorted().compactMap { inName in
                                guard let object = servicesWrapper[inName] as? NSDictionary,
                                      let service = object as? [String: Any],
                                      let name = service["service_name"] as? String,
                                      !name.isEmpty,
                                      let serversTemp = service["servers"] as? NSDictionary
                                else { return nil }
                                
                                let keys = (serversTemp.allKeys as? [String] ?? []).compactMap({ Int($0) }).sorted()

                                let servers = keys.compactMap { inIntServerKey in
                                    let strID = "\(inIntServerKey)"
                                    if let server = serversTemp[strID] as? NSDictionary,
                                       let name = server["name"] as? String,
                                       let numMeetings = server["num_meetings"] as? Int,
                                       let uriString = server["url"] as? String,
                                       let uri = URL(string: uriString),
                                       let orgs = server["organizations"] as? NSDictionary,
                                       let organizations = orgs as? [String: Int],
                                       !organizations.isEmpty {
                                        return ServerInfo.Service.Server(id: inIntServerKey, name: name, entryPointURI: uri, numberOfMeetings: numMeetings, organizations: organizations)
                                    }
                                    return nil
                                }
                                
                                return ServerInfo.Service(name: name, servers: servers)
                            }
                            
                            let serverInfo = ServerInfo(server_version: version, lastUpdate: Date(timeIntervalSince1970: TimeInterval(lastUpdate)), services: services, organizationTotals: organizationsSrc)
                            inCompletion(serverInfo, nil)
                        } else {
                            fallthrough
                        }
                    } else {
                        fallthrough
                    }
                
                default:
                    inCompletion(nil, nil)
                }
            } else {
                inCompletion(nil, inError)
            }
        }.resume()
    }
    
    /* ################################################# */
    /**
     This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function.

     - parameter specification: The search specification.
     - parameter completion: A tail completion proc (may be called in any thread).
     */
    func meetingSearch(specification inSpecification: SearchSpecification, completion inCompletion: @escaping QueryResultCompletion) {
        guard let url = serverBaseURI?.appending(queryItems: inSpecification.urlQueryItems) else {
            inCompletion(nil, nil)
            
            return
        }
        
        let urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        
        #if DEBUG
            print("URL Request: \(urlRequest.url?.absoluteString ?? "ERROR")")
        #endif

        _session.dataTask(with: urlRequest) { inData, inResponse, inError in
            guard let response = inResponse as? HTTPURLResponse,
                  nil == inError
            else {
                inCompletion(nil, nil)
                return
            }
            
            if nil == inError {
                switch response.statusCode {
                case 200..<300:
                    if let data = inData,
                       "application/json" == response.mimeType {
                        inCompletion(SwiftBMLSDK_Parser(jsonData: data, specification: inSpecification), nil)
                    } else {
                        fallthrough
                    }
                
                default:
                    inCompletion(nil, nil)
                }
            } else {
                inCompletion(nil, inError)
            }
        }.resume()
    }

    /* ################################################# */
    /**
     This actually queries the server for a set of meetings, based on a ``SearchSpecification`` instance, and provides an instance of ``SwiftBMLSDK_Parser`` to a completion function, but in this case, it does an auto-radius search, extending outwards from the search center (``SearchSpecification.locationCenter``), until the minimum number of meetings specified have been found. The ``SearchSpecification.locationRadius`` specification property is the maximum search radius (If the minimum amount have not been found, by the time the radius reaches this, the search stops, and the current results are returned).

     - parameter minimumNumberOfResults: The minimum number of results. At least this many results must be returned (or the search can give up, if it reaches the maximum radius).
     - parameter specification: The search specification.
     - parameter completion: A tail completion proc (may be called in any thread).
     */
    func meetingAutoRadiusSearch(minimumNumberOfResults inMinNumber: Int, specification inSpecification: SearchSpecification, completion inCompletion: @escaping QueryResultCompletion) {
        if case .virtual(let isExclusive) = inSpecification.type,
           isExclusive {
            inCompletion(nil, nil)
        } else if CLLocationCoordinate2DIsValid(inSpecification.locationCenter),
                  0 < inMinNumber {
            let maxRadius = 0 < inSpecification.locationRadius ? inSpecification.locationRadius : 100000
            
            var searchRadius = CLLocationDistance(1)
            var searchInProgress = false
            var abort = false
            var lastParser: SwiftBMLSDK_Parser?
            
            while searchRadius <= maxRadius && !abort {
                if !searchInProgress {
                    searchInProgress = true
                    let specification = SearchSpecification(type: inSpecification.type, locationCenter: inSpecification.locationCenter, locationRadius: searchRadius)
                    meetingSearch(specification: specification) { inParser, inError in
                        defer { searchInProgress = false }

                        if nil == inError,
                           let parser = inParser,
                           !parser.meetings.isEmpty {
                            lastParser = parser
                            if inMinNumber <= parser.meetings.count {
                                abort = true
                            }
                        }
                        
                        searchRadius *= 1.1
                    }
                }
            }
            
            inCompletion(lastParser, nil)
        } else {
            inCompletion(nil, nil)
        }
    }
}
