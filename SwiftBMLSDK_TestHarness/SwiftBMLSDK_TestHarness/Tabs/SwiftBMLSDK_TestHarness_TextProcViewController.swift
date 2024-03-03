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
import CreateML

/* ###################################################################################################################################### */
// MARK: - Text Processor Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_TextProcViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     The data table for our training.
     */
    var dataTable: MLDataTable?
    
    /* ################################################################## */
    /**
     The "busy throbber" view.
     */
    @IBOutlet weak var throbberView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_TextProcViewController {
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_TextProcViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        throbberView?.isHidden = false
    }
    
    /* ################################################################## */
    /**
     Called when the view has appeared.
     
     - parameter inIsAnimated: True, if the appearance was animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        guard let resultJSON = prefs.searchResults?.meetingJSONData else { return }
        let url = URL.documentsDirectory.appending(path: "meetingsData.json")
        do {
            try resultJSON.write(to: url, options: [.atomic, .completeFileProtection])
            dataTable = try MLDataTable(contentsOf: url)
        } catch {
            print(error.localizedDescription)
        }
        throbberView?.isHidden = true
        print("We have MLDataTable!")
    }
}

