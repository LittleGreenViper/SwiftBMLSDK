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
import CoreLocation
@testable import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Test Base Class -
/* ###################################################################################################################################### */
class SwiftBMLSDK_TestCase: XCTestCase {
    /* ################################################################## */
    /**
     This will cache our original JSON data, so we don't have to keep reloading it.
     */
    private static var _originalJSONData: Data?

    /* ################################################################## */
    /**
     This caches it as parsed JSON data, so we don't have to keep re-parsing.
     */
    private static var _parsedOriginalJSONData: NSDictionary?
    
    /* ################################################################## */
    /**
     This is how many meetings we expect to be in the dump.
     */
    static let numberOfMeetingsInDump = 34375

    /* ################################################################## */
    /**
     This returns the bundle for this test.
     */
    var testBundle: Bundle { Bundle(for: type(of: self)) }

    /* ################################################################## */
    /**
     This will cache our parser, so we don't have to keep reloading it.
     */
    static var parser: SwiftBMLSDK_Parser?

    /* ################################################################## */
    /**
     This sets up the parser, so I guess it's actually our first test.
     */
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard nil == Self.parser else { return }
        if nil == Self._originalJSONData {
            guard let meetingDumpURL = testBundle.url(forResource: "MeetingDump", withExtension: "json") else { fatalError() }
            Self._originalJSONData = try Data(contentsOf: meetingDumpURL)
            guard let jsonData = Self._originalJSONData,
                  let simpleJSON = try? JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as? NSDictionary else { return }
            Self._parsedOriginalJSONData = simpleJSON
        }
        guard let jsonData = Self._originalJSONData else { return }
        Self.parser = SwiftBMLSDK_Parser(jsonData: jsonData)
    }
    
    /* ################################################################## */
    /**
     This compares a parsed meeting instance, with the original JSON data for that meeting.
     
     - parameter index: The 0-based index of the meeting (used to extract the original data).
     - parameter meeting: The parsed meeting instance.
     */
    func validateMeeting(index inIndex: Int, meeting inMeeting: SwiftBMLSDK_Parser.Meeting) {
        /* ############################################################## */
        /**
         "Cleans" a URI.
         
         - parameter urlString: The URL, as a String. It can be optional.
         
         - returns: an optional String. This is the given URI, "cleaned up" ("https://" or "tel:" may be prefixed)
         */
        func cleanURI(urlString inURLString: String?) -> String? {
            /* ########################################################## */
            /**
             This tests a string to see if a given substring is present at the start.
             
             - Parameters:
             - inString: The string to test.
             - inSubstring: The substring to test for.
             
             - returns: true, if the string begins with the given substring.
             */
            func string (_ inString: String, beginsWith inSubstring: String) -> Bool {
                var ret: Bool = false
                if let range = inString.range(of: inSubstring) {
                    ret = (range.lowerBound == inString.startIndex)
                }
                return ret
            }
            
            guard var ret: String = inURLString?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                  let regex = try? NSRegularExpression(pattern: "^(http://|https://|tel://|tel:)", options: .caseInsensitive)
            else { return nil }
            
            // We specifically look for tel URIs.
            let wasTel = string(ret.lowercased(), beginsWith: "tel:")
            
            // Yeah, this is pathetic, but it's quick, simple, and works a charm.
            ret = regex.stringByReplacingMatches(in: ret, options: [], range: NSRange(location: 0, length: ret.count), withTemplate: "")
            
            if ret.isEmpty {
                return nil
            }
            
            if wasTel {
                ret = "tel:" + ret
            } else {
                ret = "https://" + ret
            }
            
            return ret
        }
        guard let meetingsJSON = Self._parsedOriginalJSONData?["meetings"] as? [[String: Any]],
              (0..<meetingsJSON.count).contains(inIndex)
        else {
            XCTFail("Original JSON Not Available!")
            return
        }
        
        let original = meetingsJSON[inIndex]
        
        guard !original.isEmpty,
              let originalServerID = original["server_id"] as? Int,
              let originalLocalMeetingID = original["meeting_id"] as? Int,
              let originalWeekdayIndex = original["weekday"] as? Int,
              (1..<8).contains(originalWeekdayIndex),
              let originalDuration = original["duration"] as? TimeInterval,
              let originalTimezone = original["time_zone"] as? String,
              let originalStartTimeString = original["start_time"] as? String,
              let originalName = original["name"] as? String,
              let originalOrganization = original["organization_key"] as? String
        else {
            XCTFail("Original Meeting JSON Not Available!")
            return
        }
        
        let originalFormats = original["formats"] as? [[String: Any]] ?? []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let originalStartTime = dateFormatter.date(from: originalStartTimeString)
        
        // First, compare the required fields.
        XCTAssertEqual(originalServerID, inMeeting.serverID)
        XCTAssertEqual(originalLocalMeetingID, inMeeting.localMeetingID)
        XCTAssertEqual(originalWeekdayIndex, inMeeting.weekday)
        XCTAssertEqual(originalStartTime, inMeeting.startTime)
        XCTAssertEqual(originalDuration, inMeeting.duration)
        XCTAssertEqual(originalTimezone, inMeeting.timeZone.identifier)
        XCTAssertEqual(originalName, inMeeting.name)
        XCTAssertEqual(originalOrganization, inMeeting.organization.rawValue)
        
        if !originalFormats.isEmpty {
            var index = 0
            originalFormats.forEach{ format in
                if let key = (format["key"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !key.isEmpty,
                   let name = (format["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let description = (format["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let language = (format["language"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let id = format["id"] as? Int {
                    let currentFormat = inMeeting.formats[index]
                    XCTAssertEqual(currentFormat.key, key)
                    XCTAssertEqual(currentFormat.name, name)
                    XCTAssertEqual(currentFormat.description, description)
                    XCTAssertEqual(currentFormat.language, language)
                    XCTAssertEqual(currentFormat.id, String(id))
                } else {
                    XCTFail("Original Format Missing Required Field!")
                }
                
                index += 1
            }
        } else {
            XCTAssertTrue(inMeeting.formats.isEmpty)
        }
        
        // Now, start on the optional fields.
        XCTAssertEqual(inMeeting.comments, (original["comments"] as? String ?? "").isEmpty ? nil : (original["comments"] as? String)!)
        
        if let latitude = original["latitude"] as? Double,
           let longitude = original["longitude"] as? Double {
            XCTAssertEqual(latitude, inMeeting.coords?.latitude)
            XCTAssertEqual(longitude, inMeeting.coords?.longitude)
        } else {
            XCTAssertNil(inMeeting.coords)
        }

        if let virtualInfo = original["virtual_information"] as? [String: String],
           !virtualInfo.isEmpty {
            XCTAssertEqual(virtualInfo["phone_number"], inMeeting.virtualPhoneNumber)
            if let originalURL = cleanURI(urlString: virtualInfo["url"]),
               !originalURL.isEmpty,
               let testOrig = URL(string: originalURL),
               let meetingURLString = inMeeting.virtualURL?.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines),
               !meetingURLString.isEmpty {
                XCTAssertEqual(testOrig.absoluteString, meetingURLString)
            } else {
                XCTAssertNil(inMeeting.virtualURL)
            }
        } else {
            XCTAssertNil(inMeeting.virtualPhoneNumber)
            XCTAssertNil(inMeeting.virtualURL)
        }
        
        if let virtualInfo = (original["virtual_information"] as? [String: String]),
           let virtualComments = virtualInfo["info"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !virtualComments.isEmpty {
            XCTAssertEqual(virtualComments, inMeeting.virtualInfo)
        } else {
            XCTAssertNil(inMeeting.virtualInfo)
        }
        
        if let originalPhysicalLocation = original["physical_address"] as? [String: String],
           !originalPhysicalLocation.isEmpty,
           let meetingAddress = inMeeting.inPersonAddress {
            XCTAssertEqual(originalPhysicalLocation["info"]?.trimmingCharacters(in: .whitespacesAndNewlines), inMeeting.locationInfo)
            XCTAssertEqual(originalPhysicalLocation["name"]?.trimmingCharacters(in: .whitespacesAndNewlines), inMeeting.inPersonVenueName)
            XCTAssertEqual((originalPhysicalLocation["street"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.street)
            XCTAssertEqual((originalPhysicalLocation["city"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.city)
            XCTAssertEqual((originalPhysicalLocation["province"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.state)
            XCTAssertEqual((originalPhysicalLocation["neighborhood"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.subLocality)
            XCTAssertEqual((originalPhysicalLocation["county"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.subAdministrativeArea)
            XCTAssertEqual((originalPhysicalLocation["postal_code"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.postalCode)
            XCTAssertEqual((originalPhysicalLocation["nation"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", meetingAddress.country)
        } else {
            XCTAssertNil(inMeeting.locationInfo)
            XCTAssertNil(inMeeting.inPersonVenueName)
            XCTAssertNil(inMeeting.inPersonAddress)
        }
    }
}
