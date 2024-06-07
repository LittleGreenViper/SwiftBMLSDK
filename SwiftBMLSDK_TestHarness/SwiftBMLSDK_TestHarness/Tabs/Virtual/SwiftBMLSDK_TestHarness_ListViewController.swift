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
class SwiftBMLSDK_TestHarness_ListViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################################################################################## */
    // MARK: Special Button Class
    /* ################################################################################################################################## */
    /**
     This adds a property to the standard button, to allow the button to be associated with one of the headers.
     */
    class HeaderButton: UIButton {
        /* ############################################################## */
        /**
         The index will be 0 (morning), 1 (afternoon), or 2 (evening). -1 is error.
         */
        var index: Int = -1
    }
    
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
     This handles the meeting collection for this.
     */
    var meetings: [MeetingInstance] = []
    
    /* ################################################################## */
    /**
     */
    var openSections = (morning: false, afternoon: false, evening: false)
    
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
extension SwiftBMLSDK_TestHarness_ListViewController {
    /* ################################################################## */
    /**
     Hides or shows the throbber.
     */
    var isThrobbing: Bool {
        get { !(throbberView?.isHidden ?? true) }
        set {
            throbberView?.isHidden = !newValue
            meetingsTableView?.isHidden = newValue
        }
    }
    
    /* ################################################################## */
    /**
     This segregates the meetings into times of day.
     */
    var tableFood: [(title: String, isOpen: Bool, meetings: [MeetingInstance])] {
        let morningMeetings = meetings.filter { $0.adjustedIntegerStartIme < 1200 }
        let afternoonMeetings = meetings.filter { (1200..<1800).contains($0.adjustedIntegerStartIme) }
        let eveningMeetings = meetings.filter { $0.adjustedIntegerStartIme >= 1800 }
    
        var ret = [(title: String, isOpen: Bool, meetings: [MeetingInstance])]()
        
        if !morningMeetings.isEmpty {
            ret.append((title: "SLUG-MORNING-SECTION-HEADER", isOpen: openSections.morning, meetings: morningMeetings))
        }
        
        if !afternoonMeetings.isEmpty {
            ret.append((title: "SLUG-AFTERNOON-SECTION-HEADER", isOpen: openSections.afternoon, meetings: afternoonMeetings))
        }
        
        if !eveningMeetings.isEmpty {
            ret.append((title: "SLUG-EVENING-SECTION-HEADER", isOpen: openSections.evening, meetings: eveningMeetings))
        }

        if 1 == ret.count {
            ret = [(title: "", isOpen: true, meetings: ret[0].meetings)]
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_ListViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = title
        throbberView?.backgroundColor = .systemBackground.withAlphaComponent(0.5)
        isThrobbing = false
        meetingsTableView?.sectionHeaderTopPadding = 0
        openSections = (morning: false, afternoon: false, evening: false)
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
extension SwiftBMLSDK_TestHarness_ListViewController {
    /* ################################################################## */
    /**
     Called to show a user page.
     
     - parameter inMeeting: The meeting instance.
     */
    func selectMeeting(_ inMeeting: MeetingInstance) {
        performSegue(withIdentifier: Self._showMeetingSegueID, sender: inMeeting)
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_ListViewController {
    /* ################################################################## */
    /**
     Called when the user taps on a section header.
     
     - parameter inHeaderInstance: The header button.
     */
    @objc func sectionHeaderHit(_ inHeaderInstance: HeaderButton) {
        switch inHeaderInstance.index {
        case 0:
            #if DEBUG
                print("MORNING")
            #endif
            openSections.morning = !openSections.morning
        case 1:
            #if DEBUG
                print("AFTERNOON")
            #endif
            openSections.afternoon = !openSections.afternoon
        case 2:
            #if DEBUG
                print("EVENING")
            #endif
            openSections.evening = !openSections.evening
        default:
            #if DEBUG
                print("ERROR")
            #endif
        }
        
        meetingsTableView?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_ListViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     - parameter in: The table view (ignored).
     
     - returns: 1-3
     */
    func numberOfSections(in: UITableView) -> Int { tableFood.count }
    
    /* ################################################################## */
    /**
     - parameter: The table view (ignored).
     - parameter numberOfRowsInSection: The 0-based section index.
     - returns: The number of meetings in the given section.
     */
    func tableView(_: UITableView, numberOfRowsInSection inSection: Int) -> Int { tableFood[inSection].isOpen ? tableFood[inSection].meetings.count : 0 }
    
    /* ################################################################## */
    /**
     - parameter: The table view
     - parameter cellForRowAt: The indexpath to the requested cell.
     - returns: A new (or reused) table cell.
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        let ret = inTableView.dequeueReusableCell(withIdentifier: "simple-table", for: inIndexPath)
        
        var meeting = tableFood[inIndexPath.section].meetings[inIndexPath.row]

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
extension SwiftBMLSDK_TestHarness_ListViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        let meeting = tableFood[inIndexPath.section].meetings[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard 1 < tableFood.count else { return 0 }
        
        return 30
    }
    
    /* ################################################################## */
    /**
     Returns the displayed header for the given section.
     
     - parameter: The table view (ignored)
     - parameter viewForHeaderInSection: The 0-based section index.
     - returns: The header view (a label).
     */
    func tableView(_: UITableView, viewForHeaderInSection inSection: Int) -> UIView? {
        guard 1 < tableFood.count else { return nil }
        let title = tableFood[inSection].title
        var index = -1
        var isOpen = false
        switch title {
        case "SLUG-MORNING-SECTION-HEADER":
            index = 0
            isOpen = openSections.morning
        case "SLUG-AFTERNOON-SECTION-HEADER":
            index = 1
            isOpen = openSections.afternoon
        case "SLUG-EVENING-SECTION-HEADER":
            index = 2
            isOpen = openSections.evening
        default:
            break
        }
        
        guard -1 < index,
               let image = UIImage(systemName: "arrowtriangle.\(isOpen ? "down" : "right").fill")
        else { return nil }
        
        let ret = HeaderButton()
        
        ret.index = index
        ret.setImage(image, for: .normal)
        ret.setTitle(title.localizedVariant + " (\(tableFood[inSection].meetings.count))", for: .normal)
        ret.titleLabel?.font = .boldSystemFont(ofSize: 20)
        ret.titleLabel?.textColor = .white
        ret.tintColor = .white
        ret.contentHorizontalAlignment = .left
        ret.backgroundColor = .black
        ret.addTarget(self, action: #selector(sectionHeaderHit), for: .touchUpInside)
        return ret
    }
}
