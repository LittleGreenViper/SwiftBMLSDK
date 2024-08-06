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
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Main Application Delegate Class -
/* ###################################################################################################################################### */
/**
 This is the main app delegate. It doesn't do much, as we are running the app as a scene app.
 */
@main
class SwiftBMLSDK_TestHarness_AppDelegate: UIResponder { }

/* ###################################################################################################################################### */
// MARK: UIApplicationDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_AppDelegate: UIApplicationDelegate {
    /* ################################################################## */
    /**
     Called when the application initially launches, and has set up everything.
     
     - parameter: The application (ignored).
     - parameter didFinishLaunchingWithOptions: The launch options (also ignored).
     - returns: True (always)
     */
    func application(_: UIApplication, didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }

    /* ################################################################## */
    /**
     Called when the app is being asked for the scene configuration.
     
     - parameter: The application (ignored).
     - parameter configurationForConnecting: The configuration that we need.
     - parameter options: The connection options (also ignored).
     - returns: The default configuration.
     */
    func application(_: UIApplication, configurationForConnecting inConnectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: inConnectingSceneSession.role)
    }
}
