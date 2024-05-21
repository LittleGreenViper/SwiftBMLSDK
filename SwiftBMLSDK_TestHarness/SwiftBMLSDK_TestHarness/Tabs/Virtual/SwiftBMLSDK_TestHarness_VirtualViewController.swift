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
     The ID for the segue to display a single meeting
     */
    private static let _showMeetingSegueID = "show-meeting"
    
    /* ################################################################## */
    /**
     The background transparency, for alternating rows.
     */
    static private let _alternateRowOpacity = CGFloat(0.05)

    /* ################################################################## */
    /**
     This is our query instance.
     */
    static private var _queryInstance = SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://littlegreenviper.com/LGV_MeetingServer/Tests/entrypoint.php"))

    /* ################################################################## */
    /**
     Once a meeting search has been done, we cache, here.
     */
    private var _cachedMeetings: SwiftBMLSDK_Parser?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var typeSegmentedSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var meetingsTableView: UITableView?
    
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
    var meetings: SwiftBMLSDK_Parser? { _cachedMeetings }
    
    /* ################################################################## */
    /**
     The meetings from the last search.
     */
    var tableFood: [SwiftBMLSDK_Parser.Meeting] {
        guard let selected = typeSegmentedSwitch?.selectedSegmentIndex else { return [] }
        
        switch selected {
        case 0:
            return _cachedMeetings?.meetings ?? []
            
        case 1:
            return _cachedMeetings?.hybridMeetings ?? []

        case 2:
            return _cachedMeetings?.virtualOnlyMeetings ?? []

        default:
            break
        }
        
        return []
    }
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
        guard let switchMan = typeSegmentedSwitch else { return }
        
        for index in 0..<switchMan.numberOfSegments {
            switchMan.setTitle(switchMan.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
        }
    }
    
    /* ################################################################## */
    /**
     Called just before the view is displayed.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        _cachedMeetings = nil
        prefs.clearSearchResults()
        myTabController?.updateEnablements()
        throbberView?.isHidden = false
        findMeetings() { _ in
            DispatchQueue.main.async {
                self.throbberView?.isHidden = true
                self.meetingsTableView?.reloadData()
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called before we switch to the meeting inspector.
     
     - parameter for: The segue we are executing.
     - parameter sender: The meeting instance.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inMeeting: Any?) {
        guard let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_MeetingViewController,
              let meetingInstance = inMeeting as? SwiftBMLSDK_Parser.Meeting
        else { return }
        
        destination.meeting = meetingInstance
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     */
    @IBAction func typeSegmentedSwitchChanged(_ inSwitch: UISegmentedControl) {
        meetingsTableView?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     Called to show a user page.
     
     - parameter inMeeting: The meeting instance.
     */
    func selectMeeting(_ inMeeting: SwiftBMLSDK_Parser.Meeting) {
        performSegue(withIdentifier: Self._showMeetingSegueID, sender: inMeeting)
    }
    
    /* ################################################################## */
    /**
     */
    func findMeetings(onlyVirtual inOnlyVirtual: Bool = false, completion inCompletion: ((_: SwiftBMLSDK_Parser?) -> Void)?) {
        _cachedMeetings = nil
        Self._queryInstance.meetingSearch(specification: SwiftBMLSDK_Query.SearchSpecification(type: .virtual(isExclusive: inOnlyVirtual))){ inSearchResults, inError in
            guard nil == inError else {
                inCompletion?(nil)
                return
            }
            
            self._cachedMeetings = inSearchResults
            
            inCompletion?(self._cachedMeetings)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     */
    func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int {
        tableFood.count
    }
    
    /* ################################################################## */
    /**
     */
    func tableView(_ tableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        let ret = UITableViewCell()
        ret.backgroundColor = .clear
        guard (0..<tableFood.count).contains(inIndexPath.row) else { return ret }
        let meeting = tableFood[inIndexPath.row]
        ret.textLabel?.text = meeting.name
        ret.textLabel?.adjustsFontSizeToFitWidth = true
        ret.textLabel?.minimumScaleFactor = 0.5
        ret.textLabel?.lineBreakMode = .byTruncatingTail
        ret.backgroundColor = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : UIColor.clear
        return ret
    }
}


/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        if (0..<tableFood.count).contains(inIndexPath.row) {
            selectMeeting(tableFood[inIndexPath.row])
        }
        return nil
    }
}
