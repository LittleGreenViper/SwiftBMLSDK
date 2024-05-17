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
// MARK: - Server Virtual Search Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     This is our query instance.
     */
    private static var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))

    /* ################################################################## */
    /**
     Once a meeting search has been done, we cache, here.
     */
    private var _cachedMeetings: [SwiftBMLSDK_Parser.Meeting] = []
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var throbberView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     The meetings from the last search.
     */
    var meetings: [SwiftBMLSDK_Parser.Meeting] { _cachedMeetings }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        throbberView?.isHidden = false
        findMeetings() { inResults in
            DispatchQueue.main.async {
                self.throbberView?.isHidden = true
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     */
    func findMeetings(onlyVirtual inOnlyVirtual: Bool = false, completion inCompletion: ((_: [SwiftBMLSDK_Parser.Meeting]) -> Void)?) {
        _cachedMeetings = []
        Self._queryInstance.meetingSearch(specification: SwiftBMLSDK_Query.SearchSpecification(type: .virtual(isExclusive: inOnlyVirtual))){ inSearchResults, inError in
            guard nil == inError else {
                inCompletion?([])
                return
            }
            
            self._cachedMeetings = inSearchResults?.meetings ?? []
            
            inCompletion?(self._cachedMeetings)
        }
    }
}

