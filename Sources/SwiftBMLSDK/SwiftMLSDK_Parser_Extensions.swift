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

import Foundation

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
// MARK: - Meeting JSON Page Parser Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic filtering and conversion options to the parser.
 */
public extension SwiftMLSDK_Parser {
    /* ################################################# */
    /**
     This returns the entire meeting list as a simple, 2-dimensional, JSON Data instance. The data is a simple sequence of single-dimension dictionaries.
     
     This is different from the input JSON, as it has the organization and "cleaning" provided by the parser. It also keeps it at 2 dimensions, for easy integration into ML stuff.
     */
    var meetingJSONData: Data? { try? JSONEncoder().encode(meetings) }
    
    /* ################################################# */
    /**
     Returns meetings that have an in-person component.
     */
    var inPersonMeetings: [SwiftMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType || .inPerson == $0.meetingType ? $0 : nil }
    }
    
    /* ################################################# */
    /**
     Returns meetings that are only in-person.
     */
    var inPersonOnlyMeetings: [SwiftMLSDK_Parser.Meeting] {
        meetings.compactMap { .inPerson == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that have a virtual component.
     */
    var virtualMeetings: [SwiftMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType || .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only virtual.
     */
    var virtualOnlyMeetings: [SwiftMLSDK_Parser.Meeting] {
        meetings.compactMap { .virtual == $0.meetingType ? $0 : nil }
    }

    /* ################################################# */
    /**
     Returns meetings that are only hybrid.
     */
    var hybridMeetings: [SwiftMLSDK_Parser.Meeting] {
        meetings.compactMap { .hybrid == $0.meetingType ? $0 : nil }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic interpretation methods to the base class.
 */
extension SwiftMLSDK_Parser.Meeting {
    // MARK: Computed Properties
    
    /* ################################################################## */
    /**
     This returns the next meeting start time, in the meeting's timezone.
     */
    public var nextStart: Date { getNextStartDate() }

    /* ################################################################## */
    /**
     This returns the next meeting start time, adjusted from the meeting's timezone, to ours.
     */
    public var nextLocalStart: Date { getNextStartDate(isAdjusted: true) }
    
    /* ################################################################## */
    /**
     True, if the meeting has a virtual component.
     */
    public var hasVirtual: Bool { .virtual == meetingType || .hybrid == meetingType }
    
    /* ################################################################## */
    /**
     True, if the meeting has an in-person component.
     */
    public var hasInPerson: Bool { .inPerson == meetingType || .hybrid == meetingType }

    // MARK: Instance Methods
    
    /* ################################################################## */
    /**
     This is the start time of the next meeting, in the meeting's local timezone. By default, the date will have the meeting's timezone set, but it can adjust to our local timezone.
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the next meeting.
     
     > NOTE: If the date is invalid, then the distant future will be returned.
     */
    public func getNextStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        guard let dateComponents = dateComponents else { return .distantFuture }
        let nextStartDate = Calendar.current.nextDate(after: .now, matching: dateComponents, matchingPolicy: .nextTimePreservingSmallerComponents)
        
        if inAdjust {
            return nextStartDate?._convert(from: timeZone, to: .current) ?? Date.distantFuture
        } else {
            return nextStartDate ?? .distantFuture
        }
    }
    
    /* ################################################################## */
    /**
     This is the start time of the previous meeting, in the meeting's local timezone. By default, the date will have the meeting's timezone set, but it can adjust to our local timezone.
     
     - parameter isAdjusted: If true (default is false), then the date will be converted to our local timezone.
     - returns: The date of the last meeting.

     > NOTE: If the date is invalid, then the distant past will be returned.
     */
    public func getPreviousStartDate(isAdjusted inAdjust: Bool = false) -> Date {
        guard .distantFuture > getNextStartDate(isAdjusted: inAdjust) else { return .distantPast }
        return getNextStartDate().addingTimeInterval(-(60 * 60 * 24 * 7))
    }
}
