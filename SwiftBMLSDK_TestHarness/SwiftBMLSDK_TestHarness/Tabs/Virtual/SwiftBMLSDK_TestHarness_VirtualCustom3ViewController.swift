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
// MARK: - Special Table Cell Class -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustom3ViewController_TableCell: UITableViewCell {
    /* ################################################################## */
    /**
     The ID for reuse
     */
    static let reuseID = "SwiftBMLSDK_TestHarness_VirtualCustom3ViewController_TableCell"
    
    /* ################################################################## */
    /**
     The label that displays the meeting start time
     */
    @IBOutlet weak var timeLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label that displays the meeting name
     */
    @IBOutlet weak var meetingNameLabel: UILabel?
    
    /* ################################################################## */
    /**
     The meeting instance associated with this row.
     */
    var meetingInstance: MeetingInstance?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController_TableCell {
    /* ################################################################## */
    /**
     Called when the views are being laid out.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        meetingNameLabel?.text = meetingInstance?.name
        guard var meeting = meetingInstance else { return }

        let nextDate = meeting.getNextStartDate(isAdjusted: true)
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.dateFormat = "h:mm a"
        timeLabel?.text = formatter.string(from: nextDate)
    }
}

/* ###################################################################################################################################### */
// MARK: - Server Virtual Search Custom View Controller (3) -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustom3ViewController: SwiftBMLSDK_TestHarness_BaseViewController, VirtualServiceControllerProtocol {
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
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?
    
    /* ################################################################## */
    /**
     This handles the meeting collection for this.
     */
    var meetings: [MeetingInstance] = []

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var weekdayHeaderSegmentedSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var meetingsTableView: UITableView?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController {
    /* ################################################################## */
    /**
     */
    @IBAction func weekdaySelected(_ inSwitch: UISegmentedControl! = nil) {
        let selectedSegment = inSwitch?.selectedSegmentIndex ?? 0
        
        var currentDay = selectedSegment + Calendar.current.firstWeekday
        
        if 7 < currentDay {
            currentDay -= 7
        }
        
        let current = virtualService?.meetings.compactMap { Calendar.current.component(.weekday, from: $0.nextDate) == currentDay ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
        
        guard let current = current else { return }
        
        meetings = current
        
        meetingsTableView?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        title = "SLUG-CUSTOM-3-BUTTON".localizedVariant
        super.viewDidLoad()
        setUpWeekdayControl()
    }
    
    /* ################################################################## */
    /**
     Called when the subviews have all been resolved.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        weekdaySelected()
    }
    
    /* ################################################################## */
    /**
     Called before we switch to the meeting inspector.
     
     - parameter for: The segue we are executing.
     - parameter sender: The meeting instance.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inMeeting: Any?) {
        if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_MeetingViewController,
           let meetingInstance = inMeeting as? MeetingInstance {
            destination.isNormalizedTime = true
            destination.meeting = meetingInstance
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController {
    /* ################################################################## */
    /**
     */
    func setUpWeekdayControl() {
        for index in 0..<7 {
            var currentDay = index + Calendar.current.firstWeekday
            
            if 7 < currentDay {
                currentDay -= 7
            }
            
            let weekdaySymbols = Calendar.current.shortWeekdaySymbols
            let weekdayName = weekdaySymbols[currentDay - 1]

            weekdayHeaderSegmentedSwitch?.setTitle(weekdayName, forSegmentAt: index)
        }
    }
    
    /* ################################################################## */
    /**
     Called to show a meeting details page.
     
     - parameter inMeeting: The meeting instance.
     */
    func selectMeeting(_ inMeeting: MeetingInstance) {
        performSegue(withIdentifier: Self._showMeetingSegueID, sender: inMeeting)
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     - parameter: The table view (ignored)
     - parameter numberOfRowsInSection: The 0-based section index (also ignored).
     - returns: The number of meetings to display.
     */
    func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int { meetings.count }
    
    /* ################################################################## */
    /**
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        guard let ret = inTableView.dequeueReusableCell(withIdentifier: SwiftBMLSDK_TestHarness_VirtualCustom3ViewController_TableCell.reuseID, for: inIndexPath) as? SwiftBMLSDK_TestHarness_VirtualCustom3ViewController_TableCell else { return UITableViewCell() }
        
        let meeting = meetings[inIndexPath.row]

        ret.meetingInstance = meeting
        
        ret.backgroundColor = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : UIColor.clear

        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom3ViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        let meeting = meetings[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
}
