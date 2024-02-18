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

import SwiftUI
import CoreLocation

/* ###################################################################################################################################### */
// MARK: - This Just Gives Us A Quick Starting Point -
/* ###################################################################################################################################### */
extension CLLocationCoordinate2D {
    /* ################################################# */
    /**
     We create a static constant for the position of NA World Services, in Chatsworth, CA
     */
    static let naws = CLLocationCoordinate2D(latitude: 34.235920, longitude: -118.563660)
}

/* ###################################################################################################################################### */
// MARK: - Main App -
/* ###################################################################################################################################### */
/**
 */
@main
struct SwiftBMLSDKTestHarnessApp: App {
    /* ################################################################################################################################## */
    // MARK: Search Specification
    /* ################################################################################################################################## */
    /**
     This will maintain the search specification state.
     */
    class SearchCriteria: ObservableObject {
        /* ############################################# */
        /**
         If a location-based search has been specified, this will have the location.
         */
        var locationPosition: CLLocationCoordinate2D
        
        /* ############################################# */
        /**
         If a location-based search has been specified, this will have the search radius, in meters, around the location center. It must be greater than 0.
         */
        var locationSearchRadiusInMeters: CLLocationDistance
        
        /* ############################################# */
        /**
         The default initializer.
         
         - parameters:
            - locationPosition: The coordinates of the search center.
            - locationSearchRadiusInMeters: The radius, around the center, in meters. This must be greater than 0.
         */
        init(locationPosition inLocationPosition: CLLocationCoordinate2D = .naws,
             locationSearchRadiusInMeters inLocationSearchRadiusInMeters: CLLocationDistance = 1000) {
            locationPosition = inLocationPosition
            locationSearchRadiusInMeters = inLocationSearchRadiusInMeters
        }
    }
    
    /* ################################################# */
    /**
     Our main observable search criteria state object.
     */
    @StateObject var gSearchCriteria = SearchCriteria()
    
    /* ################################################# */
    /**
     We just create a tab view.
     */
    var body: some Scene {
        WindowGroup {
            SwiftMLSDK_MainTabView()
        }
        .environmentObject(gSearchCriteria)
    }
}
