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
import SwiftBMLSDK

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
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var locationItemsStackView: UIStackView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var openMapButton: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var latitudeLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var latitudeTextField: UITextField?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var longitudeLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var longitudeTextField: UITextField?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var radiusLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var radiusTextField: UITextField?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var performSearchButton: UIButton?
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_SearchViewController {
    /* ################################################################## */
    /**
     */
    static func setFloatingPointTextField(_ inTextField: UITextField?, to inDouble: Double) {
        inTextField?.text = String(format: "%g", inDouble)
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_SearchViewController {
    /* ################################################################## */
    /**
     Called when the open map button is hit
     
     - parameter: The button (ignored).
     */
    @IBAction func openMapButtonHit(_: Any) {
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func performSearchButtonHit(_: Any) {
        prefs.clearSearchResults()
        myTabController?.updateEnablements()
        prefs.performSearch {
            guard let results = self.prefs.searchResults else { return }
            self.myTabController?.updateEnablements()
        }
    }

    /* ################################################################## */
    /**
     */
    @IBAction func textFieldTextChanged(_ inTextField: UITextField) {
        guard let latText = latitudeTextField?.text,
              let latitude = Double(latText),
              let lngText = longitudeTextField?.text,
              let longitude = Double(lngText),
              let radText = radiusTextField?.text
        else { return }
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        guard CLLocationCoordinate2DIsValid(center) else { return }
        
        let radius = Double(radText) ?? 0
        
        guard 0 < radius else { return }
        
        prefs.locationCenter = center
        prefs.locationRadius = radius
    }

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
                var center = prefs.locationCenter
                let radius = 0 < prefs.locationRadius ? prefs.locationRadius : Self._defaultRadiusInMeters
                
                if !CLLocationCoordinate2DIsValid(center) {
                    center = Self._defaultLocationCenter
                }
                
                Self.setFloatingPointTextField(latitudeTextField, to: center.latitude)
                Self.setFloatingPointTextField(longitudeTextField, to: center.longitude)
                Self.setFloatingPointTextField(radiusTextField, to: radius)
                
                prefs.locationRadius = radius
                prefs.locationCenter = center
                
                locationItemsStackView?.isHidden = false
            } else {
                prefs.locationRadius = 0
                locationItemsStackView?.isHidden = true
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
        locationToggleLabelButton?.setTitle(locationToggleLabelButton?.title(for: .normal)?.localizedVariant, for: .normal)
        openMapButton?.setTitle(openMapButton?.title(for: .normal)?.localizedVariant, for: .normal)
        locationToggleSwitch?.isOn = prefs.isLocationBasedSearch
        locationItemsStackView?.isHidden = !prefs.isLocationBasedSearch
        latitudeLabel?.text = latitudeLabel?.text?.localizedVariant
        latitudeTextField?.placeholder = latitudeTextField?.placeholder?.localizedVariant
        longitudeLabel?.text = longitudeLabel?.text?.localizedVariant
        longitudeTextField?.placeholder = longitudeTextField?.placeholder?.localizedVariant
        radiusLabel?.text = radiusLabel?.text?.localizedVariant
        radiusTextField?.placeholder = radiusTextField?.placeholder?.localizedVariant
        performSearchButton?.setTitle(performSearchButton?.title(for: .normal)?.localizedVariant, for: .normal)
    }
    
    /* ################################################################## */
    /**
     Called when the view is about to appear.
     
     - parameter inIsAnimated: True, if the appearance is to be animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        
        let center = prefs.locationCenter
        let radius = 0 < prefs.locationRadius ? prefs.locationRadius : Self._defaultRadiusInMeters
        
        Self.setFloatingPointTextField(latitudeTextField, to: center.latitude)
        Self.setFloatingPointTextField(longitudeTextField, to: center.longitude)
        Self.setFloatingPointTextField(radiusTextField, to: radius)
    }
}

/* ###################################################################################################################################### */
// MARK: UITextFieldDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_SearchViewController: UITextFieldDelegate {
    /* ################################################################## */
    /**
     */
    func textField(_ inTextField: UITextField, shouldChangeCharactersIn inRange: NSRange, replacementString inString: String) -> Bool {
        guard let testString = (inTextField.text as NSString?)?.replacingCharacters(in: inRange, with: inString),
              let decimalSeparator = Locale.current.decimalSeparator
        else { return false }

        var digits = CharacterSet.decimalDigits
        digits.insert(charactersIn: decimalSeparator)
        digits.insert(charactersIn: "-")
        let stringSet = CharacterSet(charactersIn: testString)

        return digits.isSuperset(of: stringSet)
    }
}

