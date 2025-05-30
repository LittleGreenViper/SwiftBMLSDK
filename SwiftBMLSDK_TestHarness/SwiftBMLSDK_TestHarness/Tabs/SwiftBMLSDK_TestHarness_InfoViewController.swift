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
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Server Info Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_InfoViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     This has the organization[s] information. It is programmatically populated.
     */
    var organizationContainer: [UIStackView] = []
    
    /* ################################################################## */
    /**
     This has most of the screen in it.
     */
    @IBOutlet weak var mainContainerView: UIStackView?
    
    /* ################################################################## */
    /**
     The prompt for the number of meetings.
     */
    @IBOutlet weak var numberOfMeetingsPromptLabel: UILabel?
    
    /* ################################################################## */
    /**
     The number of meetings.
     */
    @IBOutlet weak var numberOfMeetingsLabel: UILabel?
    
    /* ################################################################## */
    /**
     The prompt for the number of servers.
     */
    @IBOutlet weak var numberOfServersPromptLabel: UILabel?
    
    /* ################################################################## */
    /**
     The number of servers.
     */
    @IBOutlet weak var numberOfServersLabel: UILabel?
    
    /* ################################################################## */
    /**
     The prompt for the list of organizations.
     */
    @IBOutlet weak var organizationListPromptLabel: UILabel?
    
    /* ################################################################## */
    /**
     The main "busy throbber" view.
     */
    @IBOutlet weak var throbberView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_InfoViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        throbberView?.backgroundColor = .systemBackground.withAlphaComponent(0.5)
        throbberView?.isHidden = true
        mainContainerView?.isHidden = false
        numberOfMeetingsPromptLabel?.text = numberOfMeetingsPromptLabel?.text?.localizedVariant
        numberOfServersPromptLabel?.text = numberOfServersPromptLabel?.text?.localizedVariant
        organizationListPromptLabel?.text = organizationListPromptLabel?.text?.localizedVariant
    }
    
    /* ################################################################## */
    /**
     Called before the view appears.
     
      -parameter inIsAnimated: True, if the appearance is animated.
     */
   override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        getServerInfo()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_InfoViewController {
    /* ################################################################## */
    /**
     This fetches the server information from the server, and populates the screen.
     */
    func getServerInfo() {
        prefs.clearSearchResults()
        myTabController?.updateEnablements()
        throbberView?.isHidden = false
        mainContainerView?.isHidden = true
        organizationContainer.forEach { $0.removeFromSuperview() }
        organizationContainer = []
        prefs.getServerInfo {
            self.throbberView?.isHidden = true
            self.numberOfMeetingsLabel?.text = String(self.prefs.serverInfo?.totalMeetings ?? 0)
            self.numberOfServersLabel?.text = String(self.prefs.serverInfo?.totalServers ?? 0)
            self.prefs.serverInfo?.organizationTotals.forEach {
                let container = UIStackView()
                container.axis = .horizontal
                container.distribution = .fillEqually
                container.spacing = 8
                let key = UILabel()
                key.textAlignment = .right
                key.font = .systemFont(ofSize: 17, weight: .bold)
                key.text = "\($0.key):"
                container.addArrangedSubview(key)
                let value = UILabel()
                value.text = String($0.value)
                container.addArrangedSubview(value)
                self.organizationContainer.append(container)
                self.mainContainerView?.addArrangedSubview(container)
            }
            self.mainContainerView?.isHidden = false
        }
    }
}

