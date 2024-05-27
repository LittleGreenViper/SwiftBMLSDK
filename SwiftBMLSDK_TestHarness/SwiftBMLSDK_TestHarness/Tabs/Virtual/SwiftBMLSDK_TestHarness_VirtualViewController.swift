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
     */
    private var _cachedMeetings: SwiftBMLSDK_VirtualMeetingCollection? { didSet { if nil == _cachedMeetings { _cachedTableFood = nil } } }
    
    /* ################################################################## */
    /**
     */
    private var _cachedTableFood: (current: [SwiftBMLSDK_Parser.Meeting], upcoming: [SwiftBMLSDK_Parser.Meeting])?

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
    var tableFood: (current: [SwiftBMLSDK_Parser.Meeting], upcoming: [SwiftBMLSDK_Parser.Meeting]) {
        guard nil == _cachedTableFood else { return _cachedTableFood! }
        
        let tableFodder = tableFodder
        
        let newTableFood = (current: tableFodder.current.map { $0.meeting }, upcoming: tableFodder.upcoming.map { $0.meeting })
        
        _cachedTableFood = newTableFood
        
        return newTableFood
    }
    
    /* ################################################################## */
    /**
     The meetings from the last search.
     */
    var tableFodder: (current: [SwiftBMLSDK_VirtualMeetingCollection.CachedMeeting], upcoming: [SwiftBMLSDK_VirtualMeetingCollection.CachedMeeting]) {
        guard nil == _cachedMeetings
        else {
            let current = _cachedMeetings?.meetings.compactMap { $0.isInProgress ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate } ?? []
            let upcoming = _cachedMeetings?.meetings.compactMap { !$0.isInProgress ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate } ?? []
            return (current: current, upcoming: upcoming)
        }
        
        guard let meetings = virtualService?.meetings.sorted (by: { a, b in a.nextDate < b.nextDate }) else { return (current: [], upcoming: []) }
        _cachedMeetings = virtualService
        
        var current = [SwiftBMLSDK_VirtualMeetingCollection.CachedMeeting]()
        var upcoming = [SwiftBMLSDK_VirtualMeetingCollection.CachedMeeting]()

        switch typeSegmentedSwitch?.selectedSegmentIndex ?? -1 {
        case 0:
            current = meetings.compactMap { $0.isInProgress ? $0 : nil }
            upcoming = meetings.compactMap { !$0.isInProgress ? $0 : nil }

        case 1:
            current = meetings.compactMap { .hybrid == $0.meeting.meetingType && $0.isInProgress ? $0 : nil }
            upcoming = meetings.compactMap { .hybrid == $0.meeting.meetingType && !$0.isInProgress ? $0 : nil }

        case 2:
            current = meetings.compactMap { .virtual == $0.meeting.meetingType && $0.isInProgress ? $0 : nil }
            upcoming = meetings.compactMap { .virtual == $0.meeting.meetingType && !$0.isInProgress ? $0 : nil }

        default:
            break
        }
        
        return (current: current, upcoming: upcoming)
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
        _refreshControl?.addTarget(self, action: #selector(reloadMeetings), for: .valueChanged)
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
            reloadMeetings()
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
    @IBAction func reloadMeetings(_: Any! = nil) {
        throbberView?.isHidden = false
        findMeetings { DispatchQueue.main.async { self.reloadData() } }
    }

    /* ################################################################## */
    /**
     Refreshes the user data.
     
     - parameter: ignored (and can be omitted).
     */
    @IBAction func reloadData(_: Any! = nil) {
        throbberView?.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(20)) {
            self._cachedMeetings = nil
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
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    /* ################################################################## */
    /**
     */
    func tableView(_: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        0 == inSection ? tableFood.current.count : tableFood.upcoming.count
    }
    
    /* ################################################################## */
    /**
     */
    func tableView(_: UITableView, titleForHeaderInSection inSection: Int) -> String? {
        "SLUG-SECTION-\(inSection)-HEADER".localizedVariant
    }
    
    /* ################################################################## */
    /**
     */
    func tableView(_ tableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        let ret = UITableViewCell()
        ret.backgroundColor = .clear
        var meeting = 0 == inIndexPath.section ? tableFood.current[inIndexPath.row] : tableFood.upcoming[inIndexPath.row]
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
        let meeting = 0 == inIndexPath.section ? tableFood.current[inIndexPath.row] : tableFood.upcoming[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
}
