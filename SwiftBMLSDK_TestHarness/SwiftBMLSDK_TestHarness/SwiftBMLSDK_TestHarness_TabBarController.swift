/*
 © Copyright 2024 - 2025, Little Green Viper Software Development LLC
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

import UIKit
import RVS_Generic_Swift_Toolbox
import CoreLocation

/* ###################################################################################################################################### */
// MARK: - Main Tab Bar Controller Class -
/* ###################################################################################################################################### */
/**
 This is the main Tab Bar Controller for the app.
 */
class SwiftBMLSDK_TestHarness_TabBarController: UITabBarController {
    /* ################################################################## */
    /**
     This is used to find the user's location.
     */
    var locationManager = CLLocationManager()
    
    /* ################################################################## */
    /**
     Allows access to the central model.
     */
    let prefs = SwiftBMLSDK_TestHarness_Prefs()
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_TabBarController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        SwiftBMLSDK_TestHarness_Prefs.mainTabController = self
        locationManager.delegate = self
        tabBar.items?.forEach { $0.title = $0.title?.localizedVariant }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_TabBarController {
    /* ################################################################## */
    /**
     This simply starts looking for where the user is at.
     */
    func startLookingUpMyLocation() {
        SwiftBMLSDK_TestHarness_Prefs().currentUserLocation = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    /* ################################################################## */
    /**
     This updates the tab bar item enabled states, to match the current app state.
     */
    func updateEnablements() {
        guard let count = tabBar.items?.count,
              2 < count
        else { return }
        
        tabBar.items?[2].isEnabled = !(prefs.searchResults?.meetings ?? []).isEmpty
    }
}

/* ###################################################################################################################################### */
// MARK: CLLocationManagerDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_TabBarController: CLLocationManagerDelegate {
    /* ################################################################## */
    /**
     Callback to handle found locations.
     
     - parameter inManager: The Location Manager object that had the event.
     - parameter didUpdateLocations: an array of updated locations.
     */
    func locationManager(_ inManager: CLLocationManager, didUpdateLocations inLocations: [CLLocation]) {
        // Ignore cached locations. Wait for the real.
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.stopUpdatingLocation()
            for location in inLocations where 1.0 > location.timestamp.timeIntervalSinceNow && CLLocationCoordinate2DIsValid(location.coordinate) {
                SwiftBMLSDK_TestHarness_Prefs().currentUserLocation = location.coordinate
                break
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Base View Controller For Main Tab Screens -
/* ###################################################################################################################################### */
/**
 This is for the tab screens, which are slightly different from other screens.
 */
class SwiftBMLSDK_TestHarness_TabBaseViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     Called when the view is about to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        myNavItem?.title = tabBarItem?.title?.localizedVariant
        
        myTabController?.navigationItem.rightBarButtonItems = nil
        myTabController?.navigationItem.leftBarButtonItems = nil

        guard let rightItems = navigationItem.rightBarButtonItems,
              !rightItems.isEmpty
        else { return }
        
        myTabController?.navigationItem.setRightBarButtonItems(rightItems, animated: false)
        
        guard let leftItems = navigationItem.leftBarButtonItems,
              !leftItems.isEmpty
        else { return }
        
        myTabController?.navigationItem.setLeftBarButtonItems(leftItems, animated: false)
    }
}
