/*
 © Copyright 2024 - 2025, Little Green Viper Software Development LLC
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
     This fetches each meeting, and tests it for correctness.
     
     Yup. All of them.
     
     Go fix a cup of coffee. In fact, grow and roast it. This will take a while...
     */
    func testAllMeetings() {
        XCTAssertFalse(Self.parser?.meetings.isEmpty ?? true)
        guard let meetings = Self.parser?.meetings else {
            XCTFail("No Meetings!")
            return
        }
        for enumerated in meetings.enumerated() {
            validateMeeting(index: enumerated.offset, meeting: enumerated.element)
        }
    }
}
