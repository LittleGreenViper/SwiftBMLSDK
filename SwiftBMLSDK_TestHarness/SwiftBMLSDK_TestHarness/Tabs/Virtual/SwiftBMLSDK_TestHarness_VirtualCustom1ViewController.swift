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
import RVS_CalendarInput

/* ###################################################################################################################################### */
// MARK: - Server Virtual Search Custom View Controller (1) -
/* ###################################################################################################################################### */
/**
 Page showing a calendar input.
 */
class SwiftBMLSDK_TestHarness_VirtualCustom1ViewController: SwiftBMLSDK_TestHarness_BaseViewController, VirtualServiceControllerProtocol {
    /* ################################################################################################################################## */
    // MARK: Typealias for the data to be sent to the list.
    /* ################################################################################################################################## */
    /**
     - parameter meetingList: The list of meetings
     - parameter title: The page title for the list.
     */
    typealias MeetingRecord = (meetingList: [MeetingInstance], title: String)
    
    /* ################################################################################################################################## */
    // MARK: Date Item Class (One element of the `data` array)
    /* ################################################################################################################################## */
    /**
     This is one element of the data that is provided to, and read from, the view.
     */
    private struct _DateItem: RVS_CalendarInputDateItemProtocol {
        // MARK: Required Stored Properties
        /* ############################################################## */
        /**
         The year, as an integer. REQUIRED
         */
        public var year: Int
        
        /* ############################################################## */
        /**
         The month, as an integer (1 -> 12). REQUIRED
         */
        public var month: Int
        
        /* ############################################################## */
        /**
         The day of the month (1 -> [28|29|30|31]), as an integer. REQUIRED
         */
        public var day: Int
        
        // MARK: Optional Stored Properties
        /* ############################################################## */
        /**
         True, if the item is enabled for selection. Default is false. OPTIONAL
         */
        public var isEnabled: Bool
        
        /* ############################################################## */
        /**
         True, if the item is currently selected. Default is false. OPTIONAL
         */
        public var isSelected: Bool

        /* ############################################################## */
        /**
         Reference context. This is how we attach arbitrary data to the item. OPTIONAL
         */
        public var refCon: Any?
        
        // MARK: Default Initializer
        /* ############################################################## */
        /**
         Default Initializer. The calendar used, will be the current one.
         
         - parameter day: The day of the month (1 -> [28|29|30|31]), as an integer. REQUIRED
         - parameter month: The month, as an integer (1 -> 12). REQUIRED
         - parameter year: The year, as an integer. REQUIRED
         - parameter isEnabled: True, if the item is enabled for selection. Default is false. OPTIONAL
         - parameter isSelected: True, if the item is currently selected. Default is false. OPTIONAL
         - parameter refCon: Reference context. This is how we attach arbitrary data to the item. OPTIONAL
         */
        public init(day inDay: Int,
                    month inMonth: Int,
                    year inYear: Int,
                    isEnabled inIsEnabled: Bool = false,
                    isSelected inIsSelected: Bool = false,
                    refCon inRefCon: Any? = nil
        ) {
            day = inDay
            month = inMonth
            year = inYear
            isEnabled = inIsEnabled
            isSelected = inIsSelected
            refCon = inRefCon
        }
    }

    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     The segue ID to the list display.
     */
    private static let _showListSegueID = "show-list"
    
    /* ################################################################## */
    /**
     This is the actual widget, in our layout.
     */
    @IBOutlet weak var calendarView: RVS_CalendarInput?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom1ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "SLUG-CUSTOM-1-BUTTON".localizedVariant
        calendarView?.delegate = self
        setUpWidgetFromDates()
    }
    
    /* ################################################################## */
    /**
     Called just before a segue is executed to switch to another screen.
     
     - parameter for: The segue instance
     - parameter sender: Our meeting list data (cast to Any?).
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
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom1ViewController {
    /* ################################################################## */
    /**
     This creates a new array of date items, and sets them to the widget.
     */
    func setUpWidgetFromDates() {
        let startDate = Date.now
        let endDate = startDate.addingTimeInterval(86400 * 90)
        var seedData = [_DateItem]()

        // Determine a start day, and an end day. Remember that we work in "whole month" increments.
        if let today = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: Date())) {
            // What we do here, is strip out the days. We are only interested in the month and year of each end.
            let startComponents = Calendar.current.dateComponents([.year, .month], from: startDate)
            let endComponents = Calendar.current.dateComponents([.year, .month], from: endDate)
            
            guard let startYear = startComponents.year,
                  let endYear = endComponents.year,
                  var startMonth = startComponents.month,
                  let endMonth = endComponents.month
            else { return }
            
            // Now, a fairly simple nested loop is used to poulate our data.
            for year in startYear...endYear {
                for month in startMonth...12 where year < endYear || month <= endMonth {
                    if let calcDate = Calendar.current.date(from: DateComponents(year: year, month: month)),
                       let numberOfDaysInThisMonth = Calendar.current.range(of: .day, in: .month, for: calcDate)?.count {
                        for day in 1...numberOfDaysInThisMonth {
                            var dateItemForThisDay = _DateItem(day: day, month: month, year: year)
                            
                            if let date = dateItemForThisDay.date {
                                dateItemForThisDay.isEnabled = today <= endDate && (today...endDate).contains(date)
                                dateItemForThisDay.isSelected = date <= today
                            }
                            seedData.append(dateItemForThisDay)
                        }
                    }
                }
                
                startMonth = 1
            }
            
            calendarView?.setupData = seedData
            calendarView?.disabledAlpha = (.dark == traitCollection.userInterfaceStyle) ? 0.5 : 0.3   // More transparent, when light.
        }
    }
}

/* ###################################################################################################################################### */
// MARK: RVS_CalendarInputDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom1ViewController: RVS_CalendarInputDelegate {
    /* ################################################################## */
    /**
     This is called when the user selects an enabled calendar date.
     Currently, only a console message is sent.
     - parameter inCalendarInput: The calendar input widget instance. It is ignored in this handler.
     - parameter dateItemChanged: The date item that was changed.
     - parameter dateButton: The date item button that was actuated.
     */
    func calendarInput(_ inCalendarInput: RVS_CalendarInput, dateItemChanged inDateItem: RVS_CalendarInputDateItemProtocol, dateButton inDateButton: RVS_CalendarInput.DayButton?) {
        #if DEBUG
            print("The date \(String(describing: inDateItem.date)) was selected by the user.")
        #endif

        guard let virtualService = virtualService,
              let dateTemp = inDateItem.date
        else { return }
        let currentDay = Calendar.current.component(.weekday, from: dateTemp)
        let weekdayStuff = SwiftBMLSDK_TestHarness_VirtualCustom0ViewController.mapWeekday(currentDay)

        let current = virtualService.meetings.compactMap { Calendar.current.component(.weekday, from: $0.nextDate) == currentDay ? $0 : nil }.sorted { a, b in a.nextDate < b.nextDate }.map { $0.meeting }
        let meetingRecord = MeetingRecord(meetingList: current, title: weekdayStuff.string)
        
        performSegue(withIdentifier: Self._showListSegueID, sender: meetingRecord)
    }
}

