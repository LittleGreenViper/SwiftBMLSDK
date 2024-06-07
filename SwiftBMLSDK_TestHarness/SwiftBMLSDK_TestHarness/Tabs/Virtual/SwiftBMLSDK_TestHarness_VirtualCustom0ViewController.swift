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
// MARK: - Server Virtual Search Custom View Controller (0) -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustom0ViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################################################################################## */
    // MARK: Typealias for the data to be sent to the list.
    /* ################################################################################################################################## */
    /**
     - parameter meetingList: The list of meetings
     - parameter title: The page title for the list.
     */
    typealias MeetingRecord = (meetingList: [MeetingInstance], title: String)
    
    /* ################################################################################################################################## */
    // MARK: Enums for the Selected Button
    /* ################################################################################################################################## */
    /**
     */
    enum ButtonWeekday: Int {
        /* ############################################################## */
        /**
         */
        case inProgress = 0
        
        /* ############################################################## */
        /**
         */
        case sunday
        
        /* ############################################################## */
        /**
         */
        case monday
        
        /* ############################################################## */
        /**
         */
        case tuesday
        
        /* ############################################################## */
        /**
         */
        case wednesday
        
        /* ############################################################## */
        /**
         */
        case thursday
        
        /* ############################################################## */
        /**
         */
        case friday
        
        /* ############################################################## */
        /**
         */
        case saturday
    }
    
    /* ################################################################## */
    /**
     The segue ID to the list display.
     */
    private static let _showListSegueID = "show-list"

    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button0: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button1: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button2: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button3: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button4: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button5: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button6: UIButton?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var button7: UIButton?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom0ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-CUSTOM-0-BUTTON".localizedVariant
        
        button0?.setTitle("SLUG-CUSTOM-0-0-BUTTON".localizedVariant, for: .normal)
        button1?.setTitle("SLUG-CUSTOM-0-1-BUTTON".localizedVariant, for: .normal)
        
        var currentDay = Calendar.current.component(.weekday, from: .now) + 1
        
        var weekdayStuff = Self.mapWeekday(currentDay)
        button2?.setTitle(String(format: "SLUG-CUSTOM-0-2-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
        currentDay += 1
        weekdayStuff = Self.mapWeekday(currentDay)
        button3?.setTitle(String(format: "SLUG-CUSTOM-0-X-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
        currentDay += 1
        weekdayStuff = Self.mapWeekday(currentDay)
        button4?.setTitle(String(format: "SLUG-CUSTOM-0-X-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
        currentDay += 1
        weekdayStuff = Self.mapWeekday(currentDay)
        button5?.setTitle(String(format: "SLUG-CUSTOM-0-X-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
        currentDay += 1
        weekdayStuff = Self.mapWeekday(currentDay)
        button6?.setTitle(String(format: "SLUG-CUSTOM-0-X-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
        currentDay += 1
        weekdayStuff = Self.mapWeekday(currentDay)
        button7?.setTitle(String(format: "SLUG-CUSTOM-0-X-BUTTON-FORMAT".localizedVariant, weekdayStuff.string), for: .normal)
    }
    
    /* ################################################################## */
    /**
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inListData: Any?) {
        guard let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_ListViewController,
              let meetingRecord = inListData as? MeetingRecord
        else { return }
        destination.title = meetingRecord.title
        destination.meetings = meetingRecord.meetingList
    }
}

/* ###################################################################################################################################### */
// MARK: Static Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom0ViewController {
    /* ################################################################## */
    /**
     */
    static func mapWeekday(_ inWeekdayIndex: Int) -> (weekdayIndex: Int, string: String) {
        var currentDay = inWeekdayIndex
        
        if 7 < currentDay {
            currentDay -= 7
        }
        
        var weekdayIndex = (currentDay - Calendar.current.firstWeekday)
        
        if 0 > weekdayIndex {
            weekdayIndex += 7
        }
        
        let weekdaySymbols = Calendar.current.weekdaySymbols
        let weekdayName = weekdaySymbols[weekdayIndex]
        return (weekdayIndex: weekdayIndex + 1, string: weekdayName)
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom0ViewController {
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom0ViewController {
    /* ################################################################## */
    /**
     */
    @IBAction func buttonHit(_ inButton: UIButton) {
        guard let virtualService = virtualService else { return }
        
        var meetingRecord: MeetingRecord?
        
        var weekdayIndex = (Calendar.current.component(.weekday, from: .now) - Calendar.current.firstWeekday)
        if 0 > weekdayIndex {
            weekdayIndex += 7
        }
        
        let currentDay = Calendar.current.component(.weekday, from: .now)
        
        switch inButton {
        case button0:
            let current = virtualService.meetings.compactMap { $0.isInProgress ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: "SLUG-MEETING-DISPLAY-0".localizedVariant)
        case button1:
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate > .now && $0.nextDate.isOnTheSameDayAs(.now) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: "SLUG-MEETING-DISPLAY-1".localizedVariant)
        case button2:
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(.now.addingTimeInterval(86400)) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: "SLUG-MEETING-DISPLAY-2".localizedVariant)
        case button3:
            let weekdayStuff = Self.mapWeekday(currentDay + 2)
            let theDayDate = Date.now.addingTimeInterval(86400 * 2)
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        case button4:
            let weekdayStuff = Self.mapWeekday(currentDay + 3)
            let theDayDate = Date.now.addingTimeInterval(86400 * 3)
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        case button5:
            let weekdayStuff = Self.mapWeekday(currentDay + 4)
            let theDayDate = Date.now.addingTimeInterval(86400 * 4)
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        case button6:
            let weekdayStuff = Self.mapWeekday(currentDay + 5)
            let theDayDate = Date.now.addingTimeInterval(86400 * 5)
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        case button7:
            let weekdayStuff = Self.mapWeekday(currentDay + 6)
            let theDayDate = Date.now.addingTimeInterval(86400 * 6)
            let current = virtualService.meetings.compactMap { !$0.isInProgress && $0.nextDate.isOnTheSameDayAs(theDayDate) ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
            meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        default:
            break
        }
        
        guard let meetingRecord = meetingRecord else { return }
        
        performSegue(withIdentifier: Self._showListSegueID, sender: meetingRecord)
    }
}
