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

/* ###################################################################################################################################### */
// MARK: - Base View Controller For All Screens -
/* ###################################################################################################################################### */
/**
 This is a base class for all our view controllers.
 */
class SwiftBMLSDK_TestHarness_BaseViewController: UIViewController {
    /* ################################################################## */
    /**
     Allows access to the central model.
     */
    let prefs = SwiftBMLSDK_TestHarness_Prefs()
    
    /* ################################################################## */
    /**
     The background gradient image view
     */
    var backgroundImageView: UIImageView?
    
    /* ################################################################## */
    /**
     The background "watermark" image view
     */
    var watermarkImageView: UIImageView?
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
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let backgroundImage = UIImage(named: "BackgroundGradient"),
              let logoImage = UIImage(named: "Logo"),
              let view = view
        else { return }
        overrideUserInterfaceStyle = .dark
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        view.overrideUserInterfaceStyle = .dark
        let backgroundView = UIImageView(image: backgroundImage)
        backgroundView.contentMode = .scaleToFill
        view.insertSubview(backgroundView, at: 0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        let logoView = UIImageView(image: logoImage)
        logoView.contentMode = .scaleAspectFit
        logoView.layer.opacity = 0.05
        logoView.tintColor = .white
        view.insertSubview(logoView, at: 1)
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.widthAnchor.constraint(equalTo: logoView.heightAnchor).isActive = true
        logoView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.6).isActive = true
        logoView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.6).isActive = true
        logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        backgroundImageView = backgroundView
        watermarkImageView = logoView
    }

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

