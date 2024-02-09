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
     This will cache our parser, so we don't have to keep reloading it.
     */
    static var parser: MeetingJSONParser?
        
    /* ################################################################## */
    /**
     This sets up the parser, so I guess it's actually our first test.
     */
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard nil == Self.parser else { return }
        guard let meetingDumpURL = testBundle.url(forResource: "MeetingDump", withExtension: "json") else { fatalError() }
        let jsonData = try Data(contentsOf: meetingDumpURL)
        Self.parser = MeetingJSONParser(jsonData: jsonData)
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
        // Test Meetings
        guard let inPersonMeetings = Self.parser?.meetings.inPersonMeetings
        else {
            XCTFail("No In-Person Meetings!")
            return
        }
        XCTAssertEqual(inPersonMeetings.count, Self.numberOfInPersonMeetings)
        inPersonMeetings.forEach {
            XCTAssertTrue(.inPerson == $0.meetingType || .hybrid == $0.meetingType)
            XCTAssertTrue($0.hasInPerson)
        }
        guard let inPersonOnlyMeetings = Self.parser?.meetings.inPersonOnlyMeetings
        else {
            XCTFail("No In-Person Only Meetings!")
            return
        }
        XCTAssertEqual(inPersonOnlyMeetings.count, Self.numberOfInPersonOnlyMeetings)
        inPersonOnlyMeetings.forEach {
            XCTAssertEqual($0.meetingType, .inPerson)
            XCTAssertFalse($0.hasVirtual)
        }
        guard let virtualMeetings = Self.parser?.meetings.virtualMeetings
        else {
            XCTFail("No Virtual Meetings!")
            return
        }
        XCTAssertEqual(virtualMeetings.count, Self.numberOfVirtualMeetings)
        virtualMeetings.forEach {
            XCTAssertTrue(.virtual == $0.meetingType || .hybrid == $0.meetingType)
            XCTAssertTrue($0.hasVirtual)
        }
        guard let virtualOnlyMeetings = Self.parser?.meetings.virtualOnlyMeetings
        else {
            XCTFail("No Virtual Only Meetings!")
            return
        }
        XCTAssertEqual(virtualOnlyMeetings.count, Self.numberOfVirtualOnlyMeetings)
        virtualOnlyMeetings.forEach {
            XCTAssertEqual($0.meetingType, .virtual)
            XCTAssertFalse($0.hasInPerson)
        }
        guard let hybridMeetings = Self.parser?.meetings.hybridMeetings
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

        guard let taggedStringDumpTemp = Self.parser?.meetings.taggedStringSummary,
              !taggedStringDumpTemp.isEmpty,
              let taggedStringDump = try? JSONEncoder().encode(taggedStringDumpTemp),
              let taggedStringDumpURL = testBundle.url(forResource: "TaggedData", withExtension: "json"),
              let taggedStringData = try? Data(contentsOf: taggedStringDumpURL)
        else {
            XCTFail("No Tagged String Data!")
            return
        }
        
        XCTAssertEqual(taggedStringData.count, taggedStringDump.count)

        guard let jsonDump = Self.parser?.meetings.jsonData,
              !jsonDump.isEmpty,
              let jsonDumpDumpURL = testBundle.url(forResource: "SwiftBMLSDK_Meetings", withExtension: "json"),
              let jsonData = try? Data(contentsOf: jsonDumpDumpURL)
        else {
            XCTFail("No JSON Data!")
            return
        }
        
        XCTAssertEqual(jsonData.count, jsonDump.count)
    }
}
