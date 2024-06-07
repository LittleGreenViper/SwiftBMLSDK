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
// MARK: - Server Virtual Search Custom View Controller (2) -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_VirtualCustom2ViewController: SwiftBMLSDK_TestHarness_ListViewController {
    /* ################################################################## */
    /**
     This handles the server data.
     */
    var virtualService: SwiftBMLSDK_MeetingLocalTimezoneCollection?

    /* ################################################################## */
    /**
     */
    @IBOutlet weak var weekdayHeaderSegmentedSwitch: UISegmentedControl?
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom2ViewController {
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
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom2ViewController {
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
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_VirtualCustom2ViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        title = "SLUG-CUSTOM-2-BUTTON".localizedVariant
        super.viewDidLoad()
        setUpWeekdayControl()
        weekdaySelected()
        meetingsTableView?.reloadData()
    }
}
