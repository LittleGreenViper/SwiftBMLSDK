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
    /* ################################################################################################################################## */
    // MARK: Search Specification
    /* ################################################################################################################################## */
    /**
     This struct is what we use to prescribe the search spec.
     */
    struct SearchSpecification {
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
        init(pageSize inPageSize: Int = -1,
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
        var urlQueryString: String {
            var ret: [String] = []
            
            if 0 <= pageSize {
                ret.append("page_size=\(pageSize)")
                if 0 < pageSize,
                   0 < pageNumber {
                    ret.append("page=\(pageNumber)")
                }
            }
            
            if CLLocationCoordinate2DIsValid(locationCenter),
               0 < locationRadius {
                ret.append("geocenter_lng=\(locationCenter.longitude)")
                ret.append("geocenter_lat=\(locationCenter.latitude)")
                ret.append("geo_radius=\(locationRadius / 1000)")
            }
            
            return ret.joined(separator: "&")
        }
    }
    
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
    init(serverBaseURI inServerBaseURI: URL? = nil) {
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
}
