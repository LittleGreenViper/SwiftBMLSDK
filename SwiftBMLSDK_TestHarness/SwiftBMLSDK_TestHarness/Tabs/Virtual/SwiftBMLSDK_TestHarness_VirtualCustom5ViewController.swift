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
// MARK: - Server Virtual Search Custom View Controller (4) -
/* ###################################################################################################################################### */
/**
 This has a pickerview, but shows each meeting, in-place, so it uses a second pickerview.
 */
class SwiftBMLSDK_TestHarness_VirtualCustom5ViewController: SwiftBMLSDK_TestHarness_BaseViewController, VirtualServiceControllerProtocol {
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
     The meeting display view controller.
     */
    var embededMeetingController: SwiftBMLSDK_TestHarness_MeetingViewController?

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
     The picker for individual meetings.
     */
    @IBOutlet weak var meetingPicker: UIPickerView?
    
    /* ################################################################## */
    /**
     The "busy throbber" mask.
     */
    @IBOutlet weak var throbberView: UIView?
    
    /* ################################################################## */
    /**
     This holds individual meetings.
     */
    @IBOutlet weak var meetingContainerView: UIView?

    /* ################################################################## */
    /**
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset = [[MappedSet]]()
    
    /* ################################################################## */
    /**
     The 0-based day index.
     */
    var currentDayIndex = 0 {
        didSet {
            dayTimePicker?.reloadComponent(Self._timeComponentIndex)
            currentTimeIndex = 0
            dayTimePicker?.selectRow(0, inComponent: Self._timeComponentIndex, animated: true)
        }
    }
    
    /* ################################################################## */
    /**
     The 0-based time index.
     */
    var currentTimeIndex = 0 {
        didSet {
            meetingPicker?.reloadComponent(0)
            meetingPicker?.selectRow(0, inComponent: 0, animated: true)
        }
    }
    
    /* ################################################################## */
    /**
     The sorted and filtered table data.
     */
    var tableFood: [MeetingInstance] {
        guard let dayTimePicker = dayTimePicker,
              2 < dayTimePicker.numberOfComponents,
              (0..<mappedDataset.count).contains(currentDayIndex),
              (0..<mappedDataset[currentDayIndex].count).contains(currentTimeIndex)
        else { return [] }
        return mappedDataset[currentDayIndex][currentTimeIndex].meetings
    }
}

/* ###################################################################################################################################### */
// MARK: Static Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController {
    /* ################################################################## */
    /**
     This maps weekdays to the user's local layout.
     - parameter inWeekdayIndex: The 1-based (1 == Sunday) day index.
     - returns: A tuple, containing the converted index (also 1-based), and the weekday name (localized).
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
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController {
    /* ################################################################## */
    /**
     This maps the times for the selected day.
     */
    func mapData() {
        mappedDataset = []
        
        guard let virtualService = virtualService else { return }

        var date = Calendar.current.startOfDay(for: .now)
        
        var daySet = [MappedSet]()
        
        var meetings = [MeetingInstance]()
        
        let inProgressMeetings = virtualService.meetings.compactMap { $0.isInProgress ? $0 : nil }.map { $0.meeting }

        for day in 0..<8 {
            meetings = virtualService.meetings.compactMap {
                let nextDate = $0.nextDate
                return nextDate.isOnTheSameDayAs(date) && (nextDate >= .now || (0 < day || !$0.isInProgress)) ? $0.meeting : nil
            }
            
            var times = [Int: [MeetingInstance]]()
            
            meetings.forEach {
                let time = $0.adjustedIntegerStartTime
                if nil == times[time] {
                    times[time] = [$0]
                } else {
                    times[time]?.append($0)
                }
            }
            
            daySet = []
            
            if 0 == day,
               !inProgressMeetings.isEmpty {
                daySet = [MappedSet(time: "SLUG-IN-PROGRESS-PICKER".localizedVariant, meetings: inProgressMeetings)]
            }
            
            for timeInst in times.keys.sorted() {
                let meetings = meetings.filter { $0.adjustedIntegerStartTime == timeInst }
                daySet.append(MappedSet(time: meetings[0].timeString, meetings: meetings))
            }
            
            mappedDataset.append(daySet)
            
            date = date.addingTimeInterval(86400)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        title = "SLUG-CUSTOM-5-BUTTON".localizedVariant
        super.viewDidLoad()
        dayTimePicker?.isHidden = true
        meetingPicker?.isHidden = true
        meetingContainerView?.isHidden = true
        throbberView?.isHidden = false
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
            dayTimePicker?.selectRow(0, inComponent: Self._dayComponentIndex, animated: false)
            dayTimePicker?.selectRow(0, inComponent: Self._timeComponentIndex, animated: false)
            meetingPicker?.reloadComponent(0)
            setCurrentMeeting()
        }
        dontRefresh = false
        throbberView?.isHidden = true
        dayTimePicker?.isHidden = false
        meetingPicker?.isHidden = false
        meetingContainerView?.isHidden = false
    }
    
    /* ################################################################## */
    /**
     Called before we switch to the meeting inspector.
     
     - parameter for: The segue we are executing.
     - parameter sender: The meeting instance.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inMeeting: Any?) {
        if let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_MeetingViewController {
            embededMeetingController = destination
            destination.isNormalizedTime = true
            destination.hideBackgound = true
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController {
    /* ################################################################## */
    /**
     Called to show a meeting details page.
     
     - parameter inMeeting: The meeting instance.
     */
    func selectMeeting(_ inMeeting: MeetingInstance) {
        performSegue(withIdentifier: Self._showMeetingSegueID, sender: inMeeting)
    }
    
    /* ################################################################## */
    /**
     This sets the embedded controller to the current meeting.
     */
    func setCurrentMeeting() {
        guard let selectedRow = meetingPicker?.selectedRow(inComponent: 0),
              (0..<tableFood.count).contains(selectedRow)
        else { return }
        embededMeetingController?.meeting = tableFood[selectedRow]
    }
}

/* ###################################################################################################################################### */
// MARK: UIPickerViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController: UIPickerViewDataSource {
    /* ################################################################## */
    /**
     Returns the number of components for the picker view.
     
     - parameter in: The picker view
     - returns: 3 (always)
     */
    func numberOfComponents(in inPickerView: UIPickerView) -> Int { dayTimePicker == inPickerView ? 3 : 1 }
    
    /* ################################################################## */
    /**
     Returns the number of rows to display in the given component.
     
     - parameter inPickerView: The picker view
     - parameter numberOfRowsInComponent: The 0-based component index.
     - returns: the number of rows to display in the component.
     */
    func pickerView(_ inPickerView: UIPickerView, numberOfRowsInComponent inComponent: Int) -> Int {
        if dayTimePicker == inPickerView {
            switch inComponent {
            case Self._dayComponentIndex:
                return mappedDataset.count
                
            case Self._timeComponentIndex:
                if 1 < inPickerView.numberOfComponents {
                    let day = inPickerView.selectedRow(inComponent: Self._dayComponentIndex)
                    return mappedDataset[day].count
                } else {
                    break
                }
                
            default:
                break
            }
        } else {
            return tableFood.count
        }
        
        return 0
    }
}

/* ###################################################################################################################################### */
// MARK: UIPickerViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom5ViewController: UIPickerViewDelegate {
    /* ################################################################## */
    /**
     The picker for the day and time number of components.
     
     - parameter inPickerView: The picker view
     - parameter numberOfRowsInComponent: The 0-based component index.
     - returns: the number of rows to display in the component.
     */
    func pickerView(_ inPickerView: UIPickerView, widthForComponent inComponent: Int) -> CGFloat {
        if dayTimePicker == inPickerView {
            switch inComponent {
            case Self._dayComponentIndex:
                return Self._dayComponentWidthInDisplayUnits
                
            case Self._timeComponentIndex:
                return Self._timeComponentWidthInDisplayUnits
                
            default:
                return Self._separatorComponentWidthInDisplayUnits
            }
        }
        
        return inPickerView.frame.size.width
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
        ret.numberOfLines = 0
        ret.lineBreakMode = .byWordWrapping
        
        if dayTimePicker == inPickerView {
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
        } else {
            ret.text = tableFood[inRow].name
            ret.textAlignment = .center
        }
        
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
        if dayTimePicker == inPickerView {
            switch inComponent {
            case Self._dayComponentIndex:
                currentDayIndex = inRow
                
            default:
                currentTimeIndex = inRow
            }
        }
        setCurrentMeeting()
    }
}
