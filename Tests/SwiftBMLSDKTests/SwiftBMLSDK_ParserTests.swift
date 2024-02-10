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
// MARK: - Main Parser Test Class -
/* ###################################################################################################################################### */
final class SwiftBMLSDK_ParserTests: SwiftBMLSDK_TestCase {
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
    static let inPersonMeetingIndex = 34357
    
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
     This fetches a single fully-virtual meeting, and tests it for correctness.
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
     This fetches a single hybrid in-person-virtual meeting, and tests it for correctness.
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
     This fetches a single in-person meeting, and tests it for correctness.
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
