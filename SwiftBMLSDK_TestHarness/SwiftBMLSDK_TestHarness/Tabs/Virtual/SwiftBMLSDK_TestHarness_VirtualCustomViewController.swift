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

import UIKit
import RVS_Generic_Swift_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Server Virtual Search Custom View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustomViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var custom0Button: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var custom1Button: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var custom2Button: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var custom3Button: UIButton?
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustomViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-CUSTOM-TITLE".localizedVariant
        custom0Button?.setTitle(custom0Button?.title(for: .normal)?.localizedVariant, for: .normal)
        custom1Button?.setTitle(custom1Button?.title(for: .normal)?.localizedVariant, for: .normal)
        custom2Button?.setTitle(custom2Button?.title(for: .normal)?.localizedVariant, for: .normal)
        custom3Button?.setTitle(custom3Button?.title(for: .normal)?.localizedVariant, for: .normal)
    }
    
    /* ################################################################## */
    /**
     Called before we switch to the meeting inspector.
     
     - parameter for: The segue we are executing.
     - parameter sender: The meeting instance.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inMeeting: Any?) {
        if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_VirtualCustom0ViewController {
            destination.virtualService = virtualService
        } else if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_VirtualCustom1ViewController {
            destination.virtualService = virtualService
        } else if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_VirtualCustom2ViewController {
            destination.virtualService = virtualService
        } else if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_VirtualCustom3ViewController {
            destination.virtualService = virtualService
        }
    }
}
