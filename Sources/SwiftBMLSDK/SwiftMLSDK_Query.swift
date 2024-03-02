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

/* ###################################################################################################################################### */
// MARK: - Meeting Search Query And Communication -
/* ###################################################################################################################################### */
/**
 This struct is about generating queries to instances of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and returning the parsed results.
 */
public struct SwiftMLSDK_Query {
    /* ################################################# */
    /**
     This is the completion function for the meeting search query.
     
     > NOTE: The completion may be called in any thread!
     
     - parameter: The resultant server response. Can be nil.
     - parameter: Any errors that occurred. Should usually be nil.
     */
    public typealias QueryResultCompletion = (_: SwiftMLSDK_Parser?, _: Error?) -> Void

    /* ################################################# */
    /**
     This is the completion function for the server info query.
     
     > NOTE: The completion may be called in any thread!
     
     - parameter: The resultant server response. Can be nil.
     - parameter: Any errors that occurred. Should usually be nil.
     */
    public typealias ServerInfoResultCompletion = (_: ServerInfo?, _: Error?) -> Void

    /* ################################################################################################################################## */
    // MARK: Server Info Struct
    /* ################################################################################################################################## */
    /**
     This is the response to the general info query. It contains information about all the servers that can be aggregated by the server.
     */
    public struct ServerInfo {
        /* ############################################################################################################################## */
        // MARK: Organization Info Struct
        /* ############################################################################################################################## */
        /**
         This breaks down all the organizations that can be fetched by the aggregator.
         */
        public struct Organizations {
            /* ######################################### */
            /**
             All of the meetings, in all of the organizations.
             */
            let totalMeetings: Int

            /* ######################################### */
            /**
             A breakdown of how many meetings per organization.
             The key is the organization key, and the value is how many meetings belong to that organization.
             */
            let perOrganization: [String: Int]
        }
        
        /* ############################################################################################################################## */
        // MARK: Service Info Struct
        /* ############################################################################################################################## */
        /**
         This breaks down the information for each type of service.
         */
        public struct Service {
            /* ########################################################################################################################## */
            // MARK: Server Info Struct
            /* ########################################################################################################################## */
            /**
             This is the information for each server that provides the service.
             */
           public struct Server {
               /* ##################################### */
               /**
                The ID of the server.
                */
               let id: Int

               /* ##################################### */
               /**
                The name of the server.
                */
               let name: String

               /* ##################################### */
               /**
                The URI of the server access entrypoint.
                */
               let entryPointURI: URL

               /* ##################################### */
               /**
                The number of meetings provided by this server.
                */
               let numberOfMeetings: Int

               /* ##################################### */
               /**
                The organization breakdown for this server.
                The key is the organization key, and the value is how many meetings belong to that organization.
                */
               let organizations: [String: Int]
            }

            /* ######################################### */
            /**
             The name of the service.
             */
            let name: String

            /* ######################################### */
            /**
             An array of servers that are provided by this service.
             */
            let servers: [Server]
        }
        
        /* ############################################# */
        /**
         The version of the aggregator server.
         */
        let server_version: String
        
        /* ############################################# */
        /**
         The last time the aggregator ran an update.
         */
        let lastUpdate: Date
        
        /* ############################################# */
        /**
         The services provided by the aggregator.
         */
        let services: [Service]
    }
    
    /* ################################################################################################################################## */
    // MARK: Search Specification Struct
    /* ################################################################################################################################## */
    /**
     This struct is what we use to prescribe the search spec.
     */
    public struct SearchSpecification {
        /* ############################################# */
        /**
         The number of results per page. If this is 0, then no results are returned, and only the meta is populated. If left out, or set to a negative number, then all results are returned in one page.
         */
        let pageSize: Int
        
        /* ############################################# */
        /**
         The page number (0-based). If `pageSize` is 0 or less, this is ignored. If over the maximum number of pages, an empty page is returned.
         */
        let pageNumber: Int
        
        /* ############################################# */
        /**
         The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search.
         */
        let locationRadius: Double

        /* ############################################# */
        /**
         The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search.
         */
        let locationCenter: CLLocationCoordinate2D
        
        /* ############################################# */
        /**
         This is the default initializer. All parameters are optional, with blank/none defaults.
         
         - parameters:
            - pageSize: The number of results per page. If this is 0, then no results are returned, and only the meta is populated. If left out, or set to a negative number, then all results are returned in one page.
            - page: The page number (0-based). If `pageSize` is 0 or less, this is ignored. If over the maximum number of pages, an empty page is returned.
            - locationRadius: The radius, in meters, of a location-based search. If this is 0 (or negative), then there will not be a location-based search.
            - locationCenter: The center of a location-based search. If `locationRadius` is 0, or less, then this is ignored. It also must be a valid long/lat, or there will not be a location-based search.
         */
        public init(pageSize inPageSize: Int = -1,
             page inPageNumber: Int = 0,
             locationRadius inLocationRadius: Double = 0,
             locationCenter inLocationCenter: CLLocationCoordinate2D = CLLocationCoordinate2D()
        ) {
            pageSize = inPageSize
            pageNumber = inPageNumber
            locationRadius = inLocationRadius
            locationCenter = inLocationCenter
        }
        
        /* ############################################# */
        /**
         This returns the query portion of the search (needs to be appended to the server base URI).
         */
        var urlQueryItems: [URLQueryItem] {
            var ret: [URLQueryItem] = [URLQueryItem(name: "query", value: nil)]
            
            if 0 <= pageSize {
                ret.append(URLQueryItem(name: "page_size", value: String(pageSize)))
                if 0 < pageSize,
                   0 < pageNumber {
                    ret.append(URLQueryItem(name: "page", value: String(pageNumber)))
                }
            }
            
            if CLLocationCoordinate2DIsValid(locationCenter),
               0 < locationRadius {
                ret.append(URLQueryItem(name: "geocenter_lng", value: String(locationCenter.longitude)))
                ret.append(URLQueryItem(name: "geocenter_lat", value: String(locationCenter.latitude)))
                ret.append(URLQueryItem(name: "geo_radius", value: String(locationRadius / 1000)))
            }
            
            return ret
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
extension SwiftMLSDK_Query {
    /* ################################################# */
    /**
     Accessor for the base URI.
     */
    public var serverBaseURI: URL? {
        get { _serverBaseURI }
        set { _serverBaseURI = newValue }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftMLSDK_Query {
    /* ################################################# */
    /**
     - parameter: completion: A tail completion proc.
     */
    public func serverInfo(completion inCompletion: @escaping ServerInfoResultCompletion) {
        
    }
    
    /* ################################################# */
    /**
     Perform a server-based search.
     
     - parameter specification: The search specification.
     - parameter: completion: A tail completion proc.
     */
    public func meetingSearch(specification inSpecification: SearchSpecification, completion inCompletion: @escaping QueryResultCompletion) {
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
                        #if DEBUG
                            print("Response Data: \(data.debugDescription)")
                        #endif
                        inCompletion(SwiftMLSDK_Parser(jsonData: data), nil)
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
}
