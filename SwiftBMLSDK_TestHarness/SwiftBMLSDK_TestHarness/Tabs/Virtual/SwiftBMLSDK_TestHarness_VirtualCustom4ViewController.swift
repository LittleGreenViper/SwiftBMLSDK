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
class SwiftBMLSDK_TestHarness_VirtualCustom4ViewController_TableCell: UITableViewCell {
    /* ################################################################## */
    /**
     The ID for reuse
     */
    static let reuseID = "SwiftBMLSDK_TestHarness_VirtualCustom4ViewController_TableCell"
    
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
// MARK: - Additional Function for Meetings -
/* ###################################################################################################################################### */
extension MeetingInstance {
    /* ################################################################## */
    /**
     This allows us to return a string for the meeting time.
     */
    var timeString: String {
        var mutableSelf = self
        let nextDate = mutableSelf.getNextStartDate(isAdjusted: true)
        let formatter = DateFormatter()
        formatter.dateFormat = .none
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: nextDate)
    }
}

/* ###################################################################################################################################### */
// MARK: - Server Virtual Search Custom View Controller (4) -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustom4ViewController: SwiftBMLSDK_TestHarness_BaseViewController, VirtualServiceControllerProtocol {
    /* ################################################################## */
    /**
     This is an alias for the tuple type we use for time-mapped meeting data.
     */
    typealias MappedSet = (time: String, meetings: [MeetingInstance])
    
    /* ################################################################## */
    /**
     The index of the component that will handle the day. 2 is right side, 0 is left side.
     */
    private static let _dayComponentIndex = 0
    
    /* ################################################################## */
    /**
     The index of the component that will handle the times.
     */
    private static let _timeComponentIndex = 0 == _dayComponentIndex ? 2 : 0
    
    /* ################################################################## */
    /**
     The width of the component that will handle the day.
     */
    private static let _dayComponentWidthInDisplayUnits = CGFloat(100)
    
    /* ################################################################## */
    /**
     The width of the component that will handle the time.
     */
    private static let _timeComponentWidthInDisplayUnits = CGFloat(100)
    
    /* ################################################################## */
    /**
     The width of the component that separates the other two components.
     */
    private static let _separatorComponentWidthInDisplayUnits = CGFloat(8)

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
     We use this to prevent re-mapping the data, when returning from viewing a meeting.
     */
    var dontRefresh = false
    
    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     The picker for the day and time.
     */
    @IBOutlet weak var dayTimePicker: UIPickerView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var meetingsTableView: UITableView?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var throbberView: UIView?

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset = [[MappedSet]]()
    
    /* ################################################################## */
    /**
     */
    var tableFood: [MeetingInstance] {
        guard let dayTimePicker = dayTimePicker,
              2 < dayTimePicker.numberOfComponents,
              (0..<mappedDataset.count).contains(dayTimePicker.selectedRow(inComponent: Self._dayComponentIndex)),
              (0..<mappedDataset[dayTimePicker.selectedRow(inComponent: Self._dayComponentIndex)].count).contains(dayTimePicker.selectedRow(inComponent: Self._timeComponentIndex))
        else { return [] }
        return mappedDataset[dayTimePicker.selectedRow(inComponent: Self._dayComponentIndex)][dayTimePicker.selectedRow(inComponent: Self._timeComponentIndex)].meetings
    }
}

/* ###################################################################################################################################### */
// MARK: Static Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController {
    /* ################################################################## */
    /**
     */
    static func mapWeekday(_ inWeekdayIndex: Int) -> (weekdayIndex: Int, string: String, short: String) {
        var currentDay = inWeekdayIndex
        
        if 7 < currentDay {
            currentDay -= 7
        }
        
        var weekdayIndex = (currentDay - Calendar.current.firstWeekday)
        
        if 0 > weekdayIndex {
            weekdayIndex += 7
        }
        
        let weekdayName = Calendar.current.weekdaySymbols[weekdayIndex]
        let weekdayShortName = Calendar.current.shortWeekdaySymbols[weekdayIndex]
        return (weekdayIndex: weekdayIndex + 1, string: weekdayName, short: weekdayShortName)
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController {
    /* ################################################################## */
    /**
     This maps the times for the selected day.
     */
    func mapData() {
        mappedDataset = []
        
        guard let virtualService = virtualService else { return }


        for day in 0..<8 {
            var daySet = [MappedSet]()
            
            var meetings = [MeetingInstance]()
            
            let date = Calendar.current.startOfDay(for: .now).addingTimeInterval(86400 * TimeInterval(day))
            meetings = virtualService.meetings.compactMap {
                !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(date) && $0.nextDate >= .now ? $0 : nil
            }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            
            var times = Set<Int>()
            
            meetings.forEach { times.insert($0.adjustedIntegerStartIme) }
            
            let timeAr = Array(times).sorted()
            
            if 0 == day {
                let inProgressMeetings = virtualService.meetings.compactMap { $0.isInProgress ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
                daySet.append(MappedSet(time: "SLUG-IN-PROGRESS-PICKER".localizedVariant, meetings: inProgressMeetings))
            }
            
            for timeInst in timeAr.enumerated() {
                let meetings = meetings.filter { $0.adjustedIntegerStartIme == timeInst.element }
                if !meetings.isEmpty {
                    daySet.append(MappedSet(time: meetings[0].timeString, meetings: meetings))
                }
            }
            
            mappedDataset.append(daySet)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        title = "SLUG-CUSTOM-4-BUTTON".localizedVariant
        super.viewDidLoad()
        dayTimePicker?.isHidden = true
        throbberView?.isHidden = false
        meetingsTableView?.isHidden = true
    }
    
    /* ################################################################## */
    /**
     Called after the view appears.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        if !dontRefresh {
            mapData()
            dayTimePicker?.delegate = self
            dayTimePicker?.dataSource = self
            meetingsTableView?.reloadData()
            dayTimePicker?.selectRow(0, inComponent: Self._dayComponentIndex, animated: false)
            dayTimePicker?.selectRow(0, inComponent: Self._timeComponentIndex, animated: false)
        }
        dontRefresh = false
        throbberView?.isHidden = true
        dayTimePicker?.isHidden = false
        meetingsTableView?.isHidden = false
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
            dontRefresh = true
            destination.isNormalizedTime = true
            destination.meeting = meetingInstance
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController {
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
// MARK: UIPickerViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController: UIPickerViewDataSource {
    /* ################################################################## */
    /**
     Returns the number of components for the picker view.
     
     - parameter in: The picker view (ignored)
     - returns: 3 (always)
     */
    func numberOfComponents(in: UIPickerView) -> Int { 3 }
    
    /* ################################################################## */
    /**
     Returns the number of rows to display in the given component.
     
     - parameter inPickerView: The picker view
     - parameter numberOfRowsInComponent: The 0-based component index.
     - returns: the number of rows to display in the component.
     */
    func pickerView(_ inPickerView: UIPickerView, numberOfRowsInComponent inComponent: Int) -> Int {
        switch inComponent {
        case Self._dayComponentIndex:
            return mappedDataset.count
            
        case Self._timeComponentIndex:
            if 1 < inPickerView.numberOfComponents {
                let day = inPickerView.selectedRow(inComponent: Self._dayComponentIndex)
                return mappedDataset[day].count
            } else {
                return 0
            }
            
        default:
            return 0
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UIPickerViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController: UIPickerViewDelegate {
    /* ################################################################## */
    /**
     The picker for the day and time number of components.
     
     - parameter inPickerView: The picker view
     - parameter numberOfRowsInComponent: The 0-based component index.
     - returns: the number of rows to display in the component.
     */
    func pickerView(_ inPickerView: UIPickerView, widthForComponent inComponent: Int) -> CGFloat {
        switch inComponent {
        case Self._dayComponentIndex:
            return Self._dayComponentWidthInDisplayUnits
            
        case Self._timeComponentIndex:
            return Self._timeComponentWidthInDisplayUnits

        default:
            return Self._separatorComponentWidthInDisplayUnits
        }
    }
    
    /* ################################################################## */
    /**
     Returns the string to display in the given picker row.
     
     - parameter inPickerView: The picker view
     - parameter viewForRow: The 0-based row.
     - parameter forComponent: The 0-based component.
     - parameter reusing: A view to repopulate.
     - returns: the string to be displayed.
     */
    func pickerView(_ inPickerView: UIPickerView, viewForRow inRow: Int, forComponent inComponent: Int, reusing inReusingView: UIView?) -> UIView {
        let ret = inReusingView as? UILabel ?? UILabel()
        
        ret.adjustsFontSizeToFitWidth = true
        ret.minimumScaleFactor = 0.5
        
        switch inComponent {
        case Self._dayComponentIndex:
            if 0 == inRow {
                let currentDay = Calendar.current.component(.weekday, from: .now)
                let mapped = Self.mapWeekday(currentDay)
                ret.text = String(format: "SLUG-TODAY-FORMAT".localizedVariant, mapped.short)
            } else {
                let date = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400 * TimeInterval(inRow)))
                let currentDay = Calendar.current.component(.weekday, from: date)
                let mapped = Self.mapWeekday(currentDay)
                ret.text = mapped.string
            }
            
        case Self._timeComponentIndex:
            let day = inPickerView.selectedRow(inComponent: Self._dayComponentIndex)
            guard (0..<mappedDataset.count).contains(day),
                  (0..<mappedDataset[day].count).contains(inRow)
            else { return UIView() }
            ret.text = mappedDataset[day][inRow].time
        default:
            return UIView()
        }
        
        ret.textAlignment = 0 == inComponent ? .right : .left
        
        return ret
    }
    
    /* ################################################################## */
    /**
     Responds to a selection change in the picker.
     
     - parameter inPickerView: The picker view
     - parameter didSelectRow: The 0-based row.
     - parameter inComponent: The 0-based component.
     */
    func pickerView(_ inPickerView: UIPickerView, didSelectRow inRow: Int, inComponent: Int) {
        switch inComponent {
        case Self._dayComponentIndex:
            inPickerView.reloadComponent(Self._timeComponentIndex)
            if !mappedDataset.isEmpty {
                inPickerView.selectRow(0, inComponent: Self._timeComponentIndex, animated: true)
            }
        
        case Self._timeComponentIndex:
            meetingsTableView?.reloadData()
            
        default:
            break
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     - parameter: The table view (ignored).
     - parameter numberOfRowsInSection: The 0-based section index.
     - returns: The number of meetings in the given section.
     */
    func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int { tableFood.count }
    
    /* ################################################################## */
    /**
     - parameter: The table view
     - parameter cellForRowAt: The indexpath to the requested cell.
     - returns: A new (or reused) table cell.
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        guard let ret = inTableView.dequeueReusableCell(withIdentifier: SwiftBMLSDK_TestHarness_VirtualCustom4ViewController_TableCell.reuseID, for: inIndexPath) as? SwiftBMLSDK_TestHarness_VirtualCustom4ViewController_TableCell else { return UITableViewCell() }
        
        ret.meetingInstance = tableFood[inIndexPath.row]
        ret.meetingNameLabel?.text = ret.meetingInstance?.name
        
        ret.backgroundColor = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : UIColor.clear
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom4ViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        let meeting = tableFood[inIndexPath.row]
        selectMeeting(meeting)
        return nil
    }
}
