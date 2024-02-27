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

import CoreLocation
import UIKit
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Search Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 This manages the Search Tab.
 */
class SwiftBMLSDK_TestHarness_SearchViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     */
    private static let _defaultRadiusInMeters: CLLocationDistance = 10000
    
    /* ################################################################## */
    /**
     */
    private static let _defaultLocationCenter = CLLocationCoordinate2D(latitude: 34.2355342, longitude: -118.563597)
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var locationToggleLabelButton: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var locationToggleSwitch: UISwitch?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_SearchViewController {
    /* ################################################################## */
    /**
     Called when either the label or toggle for the location search row is selected.
     
     - parameter inControl: The control that was selected.
     */
    @IBAction func locationToggleChanged(_ inControl: UIControl) {
        if inControl is UIButton {
            locationToggleSwitch?.setOn(!(locationToggleSwitch?.isOn ?? false), animated: true)
            locationToggleSwitch?.sendActions(for: .valueChanged)
        } else if let toggle = inControl as? UISwitch {
            if toggle.isOn {
                SwiftBMLSDK_TestHarness_Prefs().locationRadius = Self._defaultRadiusInMeters
                SwiftBMLSDK_TestHarness_Prefs().locationCenter = SwiftBMLSDK_TestHarness_Prefs().currentUserLocation ?? Self._defaultLocationCenter
            } else {
                SwiftBMLSDK_TestHarness_Prefs().locationRadius = 0
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_SearchViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        locationToggleLabelButton?.setTitle("SLUG-LOCATION-SEARCH-TOGGLE".localizedVariant, for: .normal)
        locationToggleSwitch?.isOn = SwiftBMLSDK_TestHarness_Prefs().isLocationBasedSearch
    }
}

