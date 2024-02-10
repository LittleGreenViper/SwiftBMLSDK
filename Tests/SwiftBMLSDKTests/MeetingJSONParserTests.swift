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

import XCTest
@testable import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Bundle Access Extension -
/* ###################################################################################################################################### */
extension XCTestCase {
    /* ################################################################## */
    /**
     This returns the bundle for this test.
     */
    var testBundle: Bundle { Bundle(for: type(of: self)) }
}

/* ###################################################################################################################################### */
// MARK: - Main Parser Test Class -
/* ###################################################################################################################################### */
final class MeetingJSONParserTests: XCTestCase {
    /* ################################################################## */
    /**
     This is how many meetings we expect to be in the dump.
     */
    static let numberOfMeetingsInDump = 34358
    
    /* ################################################################## */
    /**
     This is how many in-person (or hybrid) meetings we expect to be in the dump.
     */
    static let numberOfInPersonMeetings = 30010

    /* ################################################################## */
    /**
     This is how many in-person (no hybrid) meetings we expect to be in the dump.
     */
    static let numberOfInPersonOnlyMeetings = 28690
    
    /* ################################################################## */
    /**
     This is how many virtual (or hybrid) meetings we expect to be in the dump.
     */
    static let numberOfVirtualMeetings = 5668

    /* ################################################################## */
    /**
     This is how many virtual (no hybrid) meetings we expect to be in the dump.
     */
    static let numberOfVirtualOnlyMeetings = 4348

    /* ################################################################## */
    /**
     This is how many hybrid meetings we expect to be in the dump.
     */
    static let numberOfHybridMeetings = 1320
    
    /* ################################################################## */
    /**
     The 0-based index, within our test dump, of a virtual meeting.
     */
    static let virtualMeetingIndex = 104

    /* ################################################################## */
    /**
     The 0-based index, within our test dump, of a hybrid meeting.
     */
    static let hybridMeetingIndex = 8600

    /* ################################################################## */
    /**
     The 0-based index, within our test dump, of an in-person meeting (also, the last one).
     */
    static let inPersonMeetingIndex = numberOfMeetingsInDump - 1

    /* ################################################################## */
    /**
     This will cache our parser, so we don't have to keep reloading it.
     */
    static var parser: SwiftMLSDK_Parser?

    /* ################################################################## */
    /**
     This sets up the parser, so I guess it's actually our first test.
     */
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard nil == Self.parser else { return }
        guard let meetingDumpURL = testBundle.url(forResource: "MeetingDump", withExtension: "json") else { fatalError() }
        let jsonData = try Data(contentsOf: meetingDumpURL)
        Self.parser = SwiftMLSDK_Parser(jsonData: jsonData)
    }
    
    /* ################################################################## */
    /**
     Just a basic sanity test, and we look at meta, here.
     */
    func testBasicMeetingMetrics() {
        XCTAssertNotNil(Self.parser)
        XCTAssertGreaterThan(Self.parser?.meetings.count ?? 0, 0)
        // Test Meta
        XCTAssertEqual(Self.parser?.meta.actualSize, Self.numberOfMeetingsInDump)
        XCTAssertEqual(Self.parser?.meta.startingIndex, 0)
        XCTAssertEqual(Self.parser?.meta.total, Self.parser?.meta.actualSize ?? -1)
        XCTAssertEqual(Self.parser?.meta.totalPages, 1)
        XCTAssertEqual(Self.parser?.meta.page, 0)
        XCTAssertGreaterThan(Self.parser?.meta.searchTime ?? 0, 0)
        XCTAssertEqual(Self.parser?.meta.actualSize ?? 0, Self.parser?.meetings.count ?? -1)
    }
    
    /* ################################################################## */
    /**
     This tests the Array extension that we have for meetings.
     
     This test takes a while, and hogs memory, because we load up a whole bunch of data and comparison data.
     */
    func testMeetingArrayExtension() {
        XCTAssertNotNil(Self.parser)
        XCTAssertGreaterThan(Self.parser?.meetings.count ?? 0, 0)
        // Test Meetings
        guard let inPersonMeetings = Self.parser?.inPersonMeetings
        else {
            XCTFail("No In-Person Meetings!")
            return
        }
        XCTAssertEqual(inPersonMeetings.count, Self.numberOfInPersonMeetings)
        inPersonMeetings.forEach {
            XCTAssertTrue(.inPerson == $0.meetingType || .hybrid == $0.meetingType)
            XCTAssertTrue($0.hasInPerson)
        }
        guard let inPersonOnlyMeetings = Self.parser?.inPersonOnlyMeetings
        else {
            XCTFail("No In-Person Only Meetings!")
            return
        }
        XCTAssertEqual(inPersonOnlyMeetings.count, Self.numberOfInPersonOnlyMeetings)
        inPersonOnlyMeetings.forEach {
            XCTAssertEqual($0.meetingType, .inPerson)
            XCTAssertFalse($0.hasVirtual)
        }
        guard let virtualMeetings = Self.parser?.virtualMeetings
        else {
            XCTFail("No Virtual Meetings!")
            return
        }
        XCTAssertEqual(virtualMeetings.count, Self.numberOfVirtualMeetings)
        virtualMeetings.forEach {
            XCTAssertTrue(.virtual == $0.meetingType || .hybrid == $0.meetingType)
            XCTAssertTrue($0.hasVirtual)
        }
        guard let virtualOnlyMeetings = Self.parser?.virtualOnlyMeetings
        else {
            XCTFail("No Virtual Only Meetings!")
            return
        }
        XCTAssertEqual(virtualOnlyMeetings.count, Self.numberOfVirtualOnlyMeetings)
        virtualOnlyMeetings.forEach {
            XCTAssertEqual($0.meetingType, .virtual)
            XCTAssertFalse($0.hasInPerson)
        }
        guard let hybridMeetings = Self.parser?.hybridMeetings
        else {
            XCTFail("No Hybrid Meetings!")
            return
        }
        XCTAssertEqual(hybridMeetings.count, Self.numberOfHybridMeetings)
        hybridMeetings.forEach {
            XCTAssertEqual($0.meetingType, .hybrid)
            XCTAssertTrue($0.hasInPerson)
            XCTAssertTrue($0.hasVirtual)
        }

        guard let jsonDump = Self.parser?.meetingJSONData,
              !jsonDump.isEmpty,
              let jsonDumpDumpURL = testBundle.url(forResource: "SwiftBMLSDK_Meetings", withExtension: "json"),
              let jsonData = try? Data(contentsOf: jsonDumpDumpURL)
        else {
            XCTFail("No JSON Data!")
            return
        }
        XCTAssertEqual(jsonData.count, jsonDump.count)
        
// Commented out, but this is how we created the reference JSON file. A "known good" dump was saved.
//        guard let deskURL = (try? FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false))?.appending(path: "SwiftBMLSDK_Meetings.json") else { return }
//        try? jsonDump.write(to: deskURL)
    }

    /* ################################################################## */
    /**
     */
    func testSingleVirtualMeeting() {
        XCTAssertNotNil(Self.parser)
        guard let meetingsCount = Self.parser?.meetings.count,
              Self.virtualMeetingIndex < meetingsCount,
              let meeting = Self.parser?.meetings[Self.virtualMeetingIndex]
        else {
            XCTFail("No Virtual Meeting!")
            return
        }
        print(meeting.debugDescription)
    }

    /* ################################################################## */
    /**
     */
    func testSingleHybridMeeting() {
        XCTAssertNotNil(Self.parser)
        guard let meetingsCount = Self.parser?.meetings.count,
              Self.hybridMeetingIndex < meetingsCount,
              let meeting = Self.parser?.meetings[Self.hybridMeetingIndex]
        else {
            XCTFail("No Hybrid Meeting!")
            return
        }
        print(meeting.debugDescription)
    }

    /* ################################################################## */
    /**
     */
    func testSingleInPersonMeeting() {
        XCTAssertNotNil(Self.parser)
        guard let meetingsCount = Self.parser?.meetings.count,
              Self.inPersonMeetingIndex < meetingsCount,
              let meeting = Self.parser?.meetings[Self.inPersonMeetingIndex]
        else {
            XCTFail("No In-Person Meeting!")
            return
        }
        print(meeting.debugDescription)
    }
}
