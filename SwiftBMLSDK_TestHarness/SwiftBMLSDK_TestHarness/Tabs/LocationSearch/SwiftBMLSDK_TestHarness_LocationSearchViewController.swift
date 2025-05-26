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
class SwiftBMLSDK_TestHarness_LocationSearchViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
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
     This will hold our location manager.
     */
    private var _locationManager: CLLocationManager?
    
    /* ################################################################## */
    /**
     This allows us to try one more time, in case of location error.
     */
    private var _tryAgain: Bool = true

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
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var autoRadiusLabelButton: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var autoRadiusSwitch: UISwitch?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var manualRadiusContainer: UIView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var autoRadiusContainer: UIView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var autoRadiusTextFieldLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var autoRadiusTextField: UITextField?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var throbberView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_LocationSearchViewController {
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
extension SwiftBMLSDK_TestHarness_LocationSearchViewController {
    /* ################################################################## */
    /**
     Called when the new search button is hit.
     
     - parameter: The button (ignored).
     */
    @IBAction func performSearchButtonHit(_: Any) {
        prefs.clearSearchResults()
        myTabController?.updateEnablements()
        throbberView?.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.prefs.performSearch {
                self.throbberView?.isHidden = true
                self.myTabController?.updateEnablements()
                if !(self.prefs.searchResults?.meetings ?? []).isEmpty {
                    self.myTabController?.selectedIndex = 2
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called when text changes in one of the search text fields.
     
     - parameter inTextField: The text field that changed.
     */
    @IBAction func textFieldTextChanged(_ inTextField: UITextField) {
        guard let latText = latitudeTextField?.text,
              let latitude = Double(latText),
              let lngText = longitudeTextField?.text,
              let longitude = Double(lngText),
              let radText = radiusTextField?.text
        else { return }
        
        prefs.clearSearchResults()

        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        guard CLLocationCoordinate2DIsValid(center) else { return }
        
        let radius = Double(radText) ?? 0
        
        guard 0 < radius else { return }
        
        prefs.locationCenter = center
        prefs.locationRadius = radius
        myTabController?.updateEnablements()
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
            prefs.clearSearchResults()
            if toggle.isOn {
                var center = prefs.locationCenter
                let radius = 0 < prefs.locationRadius ? prefs.locationRadius : Self._defaultRadiusInMeters
                
                if !CLLocationCoordinate2DIsValid(center) {
                    center = Self._defaultLocationCenter
                }
                
                Self.setFloatingPointTextField(latitudeTextField, to: center.latitude)
                Self.setFloatingPointTextField(longitudeTextField, to: center.longitude)
                radiusTextField?.text = String(format: "%d", Int(radius))

                prefs.locationRadius = radius
                prefs.locationCenter = center
                
                locationItemsStackView?.isHidden = false
            } else {
                prefs.locationRadius = 0
                locationItemsStackView?.isHidden = true
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called when the Auto-Radius switch or label was hit.
     
     - parameter inControl: The control that was selected.
     */
    @IBAction func autoRadiusSwitchHit(_ inControl: UIControl) {
        if let control = inControl as? UISwitch {
            prefs.clearSearchResults()
            autoRadiusContainer?.isHidden = !control.isOn
            prefs.isAutoRadius = control.isOn
        } else {
            autoRadiusSwitch?.setOn(!(autoRadiusSwitch?.isOn ?? true), animated: true)
            autoRadiusSwitch?.sendActions(for: .valueChanged)
        }
    }
    
    /* ################################################################## */
    /**
     Called when text in the auto-radius field is changed.
     
     - parameter inTextField: The text field that changed.
     */
    @IBAction func autoRadiusTextChanged(_ inTextField: UITextField) {
        prefs.clearSearchResults()
        let min = Int(inTextField.text ?? "0") ?? 0
        inTextField.text = String(format: "%d", min)
        prefs.minimumAutoRadiusMeetings = min
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_LocationSearchViewController {
    /* ################################################################## */
    /**
     This simply starts looking for where the user is at.
     */
    func startLookingUpMyLocation() {
        _locationManager = CLLocationManager()
        _locationManager?.delegate = self
        _locationManager?.requestWhenInUseAuthorization()
        _locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager?.startUpdatingLocation()
    }
    
    /* ################################################################## */
    /**
     This stops the location manager lookups.
     */
    func stopLookingUpMyLocation() {
        if let locationManager = _locationManager {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
        }
        
        _locationManager = nil
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_LocationSearchViewController {
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
        autoRadiusLabelButton?.setTitle(autoRadiusLabelButton?.title(for: .normal)?.localizedVariant, for: .normal)
        autoRadiusTextField?.placeholder = autoRadiusTextField?.placeholder?.localizedVariant
        performSearchButton?.setTitle(performSearchButton?.title(for: .normal)?.localizedVariant, for: .normal)
        autoRadiusTextFieldLabel?.text = autoRadiusTextFieldLabel?.text?.localizedVariant
        throbberView?.backgroundColor = .systemBackground.withAlphaComponent(0.5)
        autoRadiusSwitch?.isOn = prefs.isAutoRadius
        autoRadiusContainer?.isHidden = !prefs.isAutoRadius
        autoRadiusTextField?.text = String(format: "%d", prefs.minimumAutoRadiusMeetings)

        if nil == prefs.locationRegion {
            throbberView?.isHidden = false
            prefs.locationRadius = 0 < prefs.locationRadius ? prefs.locationRadius : Self._defaultRadiusInMeters
            startLookingUpMyLocation()
        } else {
            throbberView?.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     Called when the view is about to appear.
     
     - parameter inIsAnimated: True, if the appearance is to be animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        myTabController?.updateEnablements()
        let center = prefs.locationCenter
        let radius = 0 < prefs.locationRadius ? prefs.locationRadius : Self._defaultRadiusInMeters
        
        Self.setFloatingPointTextField(latitudeTextField, to: center.latitude)
        Self.setFloatingPointTextField(longitudeTextField, to: center.longitude)
        radiusTextField?.text = String(format: "%d", Int(radius))

        prefs.isDirty = false
    }
}

/* ###################################################################################################################################### */
// MARK: UITextFieldDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_LocationSearchViewController: UITextFieldDelegate {
    /* ################################################################## */
    /**
     Called when the user enters text. We use this to filter for only numbers and whatnot
     
     - parameter inTextField: The text field getting the characters.
     - parameter shouldChangeCharactersIn: The range of characters in the existing text, being replaced.
     - parameter replacementString: The string that we want to replace them with.
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

/* ###################################################################################################################################### */
// MARK: CLLocationManagerDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_LocationSearchViewController: CLLocationManagerDelegate {
    /* ################################################################## */
    /**
     Callback to handle errors. We simply turn off autolocation, and proceed.
     
     - parameter inManager: The Location Manager object that had the error.
     - parameter didFailWithError: the error
     */
    func locationManager(_ inManager: CLLocationManager, didFailWithError inError: Error) {
        guard !_tryAgain else {
            _tryAgain = false
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.throbberView?.isHidden = true
            self?.stopLookingUpMyLocation()
            self?.locationToggleSwitch?.setOn(false, animated: true)
            self?.locationToggleSwitch?.sendActions(for: .valueChanged)
        }
    }
    
    /* ################################################################## */
    /**
     Callback to handle found locations.
     
     - parameter inManager: The Location Manager object that had the event.
     - parameter didUpdateLocations: an array of updated locations.
     */
    func locationManager(_ inManager: CLLocationManager, didUpdateLocations inLocations: [CLLocation]) {
        // Ignore cached locations. Wait for the real.
        for location in inLocations where 1.0 > location.timestamp.timeIntervalSinceNow {
            DispatchQueue.main.async { [weak self] in
                self?.throbberView?.isHidden = true
                self?.stopLookingUpMyLocation()
                self?.prefs.locationCenter = location.coordinate
                self?.locationToggleSwitch?.setOn(true, animated: true)
                self?.locationToggleSwitch?.sendActions(for: .valueChanged)
            }
        }
    }
}
