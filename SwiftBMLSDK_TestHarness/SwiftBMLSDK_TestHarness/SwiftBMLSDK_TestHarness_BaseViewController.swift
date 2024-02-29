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

/* ###################################################################################################################################### */
// MARK: - Base View Controller For All Screens -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_BaseViewController: UIViewController {
    /* ################################################################## */
    /**
     Allows access to the central model.
     */
    let prefs = SwiftBMLSDK_TestHarness_Prefs()
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     Quick accessor for the main Tab Bar Controller.
     */
    var myTabController: SwiftBMLSDK_TestHarness_TabBarController? { tabBarController as? SwiftBMLSDK_TestHarness_TabBarController }
    
    /* ################################################################## */
    /**
     This returns the appropriate navigation item. In the home context of each tab, the tab bar's nav item is actually the one we see.
     */
    var myNavItem: UINavigationItem? {
        guard 1 < (navigationController?.viewControllers.count ?? 0) else { return tabBarController?.navigationItem }
        return navigationItem
    }
    
    /* ################################################################## */
    /**
     Quick accessor for the shared application delegate instance.
     */
    var myAppDelegateInstance: SwiftBMLSDK_TestHarness_AppDelegate? { SwiftBMLSDK_TestHarness_AppDelegate.appDelegateInstance }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     Called when the view is about to appear.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        myNavItem?.title = navigationItem.title?.localizedVariant
    }
}

