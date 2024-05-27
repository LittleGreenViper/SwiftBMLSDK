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
// MARK: - File Private Date Extension -
/* ###################################################################################################################################### */
/**
 This extension allows us to convert a date to a certain time zone.
 */
fileprivate extension Date {
    /* ################################################################## */
    /**
     Convert a date between two timezones.
     
     Inspired by [this SO answer](https://stackoverflow.com/a/54064820/879365)
     
     - parameter from: The source timezone.
     - paremeter to: The destination timezone.
     
     - returns: The converted date
     */
    func _convert(from inFromTimeZone: TimeZone, to inToTimeZone: TimeZone) -> Date {
        addingTimeInterval(TimeInterval(inToTimeZone.secondsFromGMT(for: self) - inFromTimeZone.secondsFromGMT(for: self)))
    }
}

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
    private static let _alternateRowOpacity = CGFloat(0.05)
    
    /* ################################################################## */
    /**
     The "pull to refresh" control.
     */
    private var _refreshControl: UIRefreshControl?

    /* ################################################################## */
    /**
     This handles transactions with the server.
     */
    private var virtualService: SwiftBMLSDK_VirtualMeetingCollection?

    /* ################################################################## */
    /**
     This prevents a reload, when coming back from a meeting inspector.
     */
    private var _dontReload: Bool = false
    
    /* ################################################################## */
    /**
     The meetings from the last search, but cached, to speed up the table (pre-sorted).
     */
    private var _cachedTableFood: [SwiftBMLSDK_Parser.Meeting] = []

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
    var tableFood: [SwiftBMLSDK_Parser.Meeting] {
        guard _cachedTableFood.isEmpty else { return _cachedTableFood }
        
        guard let selected = typeSegmentedSwitch?.selectedSegmentIndex else { return [] }
        
        switch selected {
        case 0:
            _cachedTableFood = virtualService?.meetings.map { $0.meeting }.sorted { a, b in a.nextMeetingIn < b.nextMeetingIn } ?? []
            
        case 1:
            _cachedTableFood = virtualService?.meetings.filter { .hybrid == $0.meeting.meetingType }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting } ?? []

        case 2:
            _cachedTableFood = virtualService?.meetings.filter { .virtual == $0.meeting.meetingType }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting } ?? []

        default:
            break
        }
        
        return _cachedTableFood
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
        throbberView?.backgroundColor = .systemBackground.withAlphaComponent(0.5)
        throbberView?.isHidden = true
        _refreshControl = UIRefreshControl()
        _refreshControl?.addTarget(self, action: #selector(reloadData), for: .valueChanged)
        meetingsTableView?.refreshControl = _refreshControl
        for index in 0..<(typeSegmentedSwitch?.numberOfSegments ?? 0) {
            let title = "SLUG-VIRTUAL-SWITCH-\(index)".localizedVariant
            typeSegmentedSwitch?.setTitle(title, forSegmentAt: index)
        }
    }
    
    /* ################################################################## */
    /**
     Called just before the view is displayed.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        if !_dontReload {
            prefs.clearSearchResults()
            myTabController?.updateEnablements()
            throbberView?.isHidden = false
            findMeetings() {
                DispatchQueue.main.async {
                    self._cachedTableFood = []
                    self.throbberView?.isHidden = true
                    self.meetingsTableView?.reloadData()
                }
            }
        }
        _dontReload = false
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
        _dontReload = true
        destination.isNormalizedTime = true
        destination.meeting = meetingInstance
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualViewController {
    /* ################################################################## */
    /**
     Refreshes the user data.
     
     - parameter: ignored (and can be omitted).
     */
    @IBAction func reloadData(_: Any! = nil) {
        throbberView?.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(20)) {
            self._cachedTableFood = []
            self._refreshControl?.endRefreshing()
            self.meetingsTableView?.reloadData()
            self.throbberView?.isHidden = true
        }
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
    func findMeetings(completion inCompletion: (() -> Void)?) {
        virtualService = SwiftBMLSDK_VirtualMeetingCollection(query: prefs.queryInstance) { inCollection in
            DispatchQueue.main.async {
                guard let switchMan = self.typeSegmentedSwitch else { return }
                
                for index in 0..<switchMan.numberOfSegments {
                    var count = 0
                    
                    switch index {
                    case 0:
                        count = inCollection.meetings.count
                    case 1:
                        count = inCollection.hybridMeetings.count
                    case 2:
                        count = inCollection.virtualMeetings.count
                    default:
                        break
                    }
                    let countSuffix = 0 < count ? " (\(count))" : ""
                    let title = "SLUG-VIRTUAL-SWITCH-\(index)".localizedVariant + countSuffix
                    switchMan.setTitle(title, forSegmentAt: index)
                }
            }
            
            inCompletion?()
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
        var meeting = tableFood[inIndexPath.row]
        let nextDate = meeting.getNextStartDate(isAdjusted: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: nextDate)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: nextDate)
        let dayTime = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, time)
        ret.textLabel?.text = meeting.name + "\n" + dayTime
        ret.textLabel?.numberOfLines = 0
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
