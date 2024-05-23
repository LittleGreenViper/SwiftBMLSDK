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
// MARK: - Date Extension for Localized Strings -
/* ###################################################################################################################################### */
fileprivate extension Date {
    /* ################################################################## */
    /**
     Localizes the time (not the date).
     */
    var localizedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none

        var ret = ""
        
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)

        if let am = dateFormatter.amSymbol {
            if 0 == hour {
                if 0 == minute {
                    ret = "SLUG-MIDNIGHT-TIME".localizedVariant
                } else {
                    ret = String(format: "12:%02d %@", minute, am)
                }
            } else if 12 == hour,
                      0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else {
                ret = dateFormatter.string(from: self)
            }
        } else {
            if 12 == hour,
               0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else if 0 == hour,
                      0 == minute {
                ret = "SLUG-MIDNIGHT-TIME".localizedVariant
            } else {
                ret = String(format: "%d:%02d", hour, minute)
            }
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Server Single Meeting Inspector View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_MeetingViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     The ID for the segue to display a single meeting
     */
    private static let _showMeetingSegueID = "show-meeting"
    
    /* ################################################################## */
    /**
     The amount of time before we are no longer interested in the meeting.
     */
    private static let _meetingStartPaddingInSeconds = TimeInterval(15 * 60)
    
    /* ################################################################## */
    /**
     */
    var meeting: SwiftBMLSDK_Parser.Meeting?
    
    /* ################################################################## */
    /**
     */
    var isNormalizedTime: Bool = false
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var timeDayLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var timeZoneLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var meetsNextLabel: UILabel?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let meeting = meeting else { return }
        myNavItem?.title = meeting.name
    }
    
    /* ################################################################## */
    /**
     Called just before the view is displayed.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        setTimeAndDay()
        setMeetingTimeZone()
        setMeetsNext()
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
    /* ################################################################## */
    /**
     Set the time and day label.
     */
    func setTimeAndDay() {
        guard var meeting = meeting else { return }
        
        let nextStart = meeting.getNextStartDate(isAdjusted: isNormalizedTime)
        var nextEnd: Date?
        var displayString: String = ""
        
        if 0 < meeting.duration {
            nextEnd = nextStart.addingTimeInterval(TimeInterval(meeting.duration))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
        let weekday = dateFormatter.string(from: nextStart)

        if let nextEnd = nextEnd {
            let startTime = nextStart.localizedTime
            let endTime = nextEnd.localizedTime
            displayString = String(format: "SLUG-MEETING-DAY-AND-TIME-RANGE-LABEL-FORMAT".localizedVariant, weekday, startTime, endTime)
        } else {
            let startTime = nextStart.localizedTime
            displayString = String(format: "SLUG-MEETING-DAY-AND-TIME-LABEL-FORMAT".localizedVariant, weekday, startTime)
        }
        
        if !displayString.isEmpty {
            timeDayLabel?.text = displayString
        } else {
            timeDayLabel?.isHidden = true
        }
    }

    /* ################################################################## */
    /**
     Set the next meeting label.
     */
    func setMeetsNext() {
        guard var meeting = meeting else { return }

        var newText = ""
        
        let nextStart = Int(meeting.meetingStartsIn(isAdjusted: isNormalizedTime, paddingInSeconds: Self._meetingStartPaddingInSeconds) / 60)
        switch nextStart {
        case -Int(Self._meetingStartPaddingInSeconds / 60)..<(-1):
            newText = String(format: "SLUG-STARTED-MINUTES-FORMAT".localizedVariant, abs(nextStart))

        case -1:
            newText = "SLUG-STARTED-MINUTE".localizedVariant

        case 0:
            newText = "SLUG-STARTING-NOW".localizedVariant

        case 1:
            newText = "SLUG-STARTS-IN-ONE-MINUTE".localizedVariant

        case 2..<60:
            newText = String(format: "SLUG-STARTS-IN-MINUTES-FORMAT".localizedVariant, nextStart)

        case 60:
            newText = "SLUG-STARTS-IN-ONE-HOUR".localizedVariant

        case 61:
            newText = "SLUG-STARTS-IN-ONE-HOUR-ONE-MINUTE".localizedVariant

        case 61..<120:
            let hours = Int(nextStart / 60)
            let minutes = Int(nextStart) - (hours * 60)
            newText = String(format: "SLUG-STARTS-IN-ONE-HOUR-MINUTES-FORMAT".localizedVariant, minutes)

        case 120..<1440:
            let hours = Int(nextStart / 60)
            let minutes = Int(nextStart) - (hours * 60)
            if 0 == minutes {
                newText = String(format: "SLUG-STARTS-IN-HOURS-FORMAT".localizedVariant, hours)
            } else {
                newText = String(format: "SLUG-STARTS-IN-HOURS-MINUTES-FORMAT".localizedVariant, hours, minutes)
            }

        default:
            break
        }
        
        if newText.isEmpty {
            meetsNextLabel?.isHidden = true
        } else {
            meetsNextLabel?.isHidden = false
            meetsNextLabel?.text = newText
        }
    }

    /* ################################################################## */
    /**
     */
    func setMeetingTimeZone() {
        guard var meetingInstance = meeting else { return }
        let nativeTime = meetingInstance.getNextStartDate(isAdjusted: false)
        
        if let myCurrentTimezoneName = TimeZone.current.localizedName(for: .standard, locale: .current),
           let zoneName = meetingInstance.timeZone.localizedName(for: .standard, locale: .current),
           !zoneName.isEmpty,
           myCurrentTimezoneName != zoneName {
            timeZoneLabel?.isHidden = false
            if isNormalizedTime {
                timeZoneLabel?.text = String(format: "SLUG-TIMEZONE-FORMAT".localizedVariant, zoneName, nativeTime.localizedTime)
            } else {
                timeZoneLabel?.text = String(format: "SLUG-TIMEZONE-NO-TIME-FORMAT".localizedVariant, zoneName)
            }
        } else {
            timeZoneLabel?.isHidden = true
        }
    }
}
