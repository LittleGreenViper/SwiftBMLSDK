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
// MARK: - Test Base Class -
/* ###################################################################################################################################### */
class SwiftBMLSDK_TestCase: XCTestCase {
    /* ################################################################## */
    /**
     This is how many meetings we expect to be in the dump.
     */
    static let numberOfMeetingsInDump = 34358

    /* ################################################################## */
    /**
     This returns the bundle for this test.
     */
    var testBundle: Bundle { Bundle(for: type(of: self)) }

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
}
