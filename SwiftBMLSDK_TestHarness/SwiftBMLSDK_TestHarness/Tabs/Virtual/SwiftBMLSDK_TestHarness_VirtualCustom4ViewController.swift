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
     This is an array of the time-mapped meeting data.
     */
    var mappedDataset = [MappedSet]()
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
        guard let dayTimePicker = dayTimePicker,
              let virtualService = virtualService
        else { return }

        var meetings = [MeetingInstance]()
        
        if 0 == dayTimePicker.selectedRow(inComponent: 1),
           0 == dayTimePicker.selectedRow(inComponent: 0) {
            meetings = virtualService.meetings.compactMap { $0.isInProgress ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
        } else if 0 == dayTimePicker.selectedRow(inComponent: 1) {
            meetings = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate > .now && $0.nextDate.isOnTheSameDayAs(.now) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
        } else {
            let theDayDate = Date.now.addingTimeInterval(86400 * TimeInterval(dayTimePicker.selectedRow(inComponent: 0) + 1))
            meetings = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
        }
        
        var times = Set<Int>()
        
        meetings.forEach { times.insert($0.adjustedIntegerStartIme) }
        
        let timeAr = Array(times).sorted()
        
        mappedDataset = []
        
        for timeInst in timeAr.enumerated() {
            let meetings = meetings.filter { $0.adjustedIntegerStartIme == timeInst.element }
            if !meetings.isEmpty {
                mappedDataset.append(MappedSet(time: meetings[0].timeString, meetings: meetings))
            }
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
    }
    
    /* ################################################################## */
    /**
     Called after the view appears.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        dayTimePicker?.selectRow(0, inComponent: 1, animated: false)
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
     - returns: 2 (always)
     */
    func numberOfComponents(in: UIPickerView) -> Int { 2 }
    
    /* ################################################################## */
    /**
     Returns the number of rows to display in the given component.
     
     - parameter inPickerView: The picker view
     - parameter numberOfRowsInComponent: The 0-based component index.
     - returns: the number of rows to display in the component.
     */
    func pickerView(_ inPickerView: UIPickerView, numberOfRowsInComponent inComponent: Int) -> Int {
        switch inComponent {
        case 1:
            return 8
            
        default:
            var ret = 1 < inPickerView.numberOfComponents && 0 == inPickerView.selectedRow(inComponent: 1) ? 1 : 0
            ret += mappedDataset.count
            return ret
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
        let pickerWidth = inPickerView.frame.size.width
        
        switch inComponent {
        case 1:
            return 100
            
        default:
            return pickerWidth - 100
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
        case 1:
            if 0 == inRow {
                let currentDay = Calendar.current.component(.weekday, from: .now)
                let mapped = Self.mapWeekday(currentDay)
                ret.text = String(format: "SLUG-TODAY-FORMAT".localizedVariant, mapped.short)
            } else {
                let currentDay = Calendar.current.component(.weekday, from: .now.addingTimeInterval(86400 * TimeInterval(inRow)))
                let mapped = Self.mapWeekday(currentDay)
                ret.text = mapped.string
            }
            
        default:
            if 0 == inPickerView.selectedRow(inComponent: 1),
               0 == inRow {
                ret.text = "SLUG-IN-PROGRESS-PICKER".localizedVariant
            } else {
                let theRow = 0 == inPickerView.selectedRow(inComponent: 1) ? inRow - 1 : inRow
                ret.text = mappedDataset[theRow].time
            }
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
        switch inComponent {
        case 1:
            mapData()
            inPickerView.reloadComponent(0)
            if !mappedDataset.isEmpty {
                inPickerView.selectRow(0, inComponent: 0, animated: true)
            }
        default:
            break
        }
    }
}
