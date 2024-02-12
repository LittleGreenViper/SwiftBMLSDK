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
// MARK: - Parser Extensions Test Class -
/* ###################################################################################################################################### */
final class SwiftBMLSDK_Parser_ExtensionTests: SwiftBMLSDK_TestCase {
    /* ################################################################## */
    /**
     This is how many in-person (or hybrid) meetings we expect to be in the dump.
     */
    static let numberOfInPersonMeetings = 30029

    /* ################################################################## */
    /**
     This is how many in-person (no hybrid) meetings we expect to be in the dump.
     */
    static let numberOfInPersonOnlyMeetings = 28709
    
    /* ################################################################## */
    /**
     This is how many virtual (or hybrid) meetings we expect to be in the dump.
     */
    static let numberOfVirtualMeetings = 5666

    /* ################################################################## */
    /**
     This is how many virtual (no hybrid) meetings we expect to be in the dump.
     */
    static let numberOfVirtualOnlyMeetings = 4346

    /* ################################################################## */
    /**
     This is how many hybrid meetings we expect to be in the dump.
     */
    static let numberOfHybridMeetings = 1320
    
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
}
