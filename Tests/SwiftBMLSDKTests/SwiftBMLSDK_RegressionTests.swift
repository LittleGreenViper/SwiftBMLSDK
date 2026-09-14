/*
 © Copyright 2024 - 2026, Little Green Viper Software Development LLC
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
// MARK: - Deterministic SDK Regression Tests -
/* ###################################################################################################################################### */
final class SwiftBMLSDK_RegressionTests: XCTestCase {
    private typealias Meeting = SwiftBMLSDK_Parser.Meeting

    /* ################################################################## */
    /**
     Builds a small server record. Each test changes only the fields it exercises.
     */
    private func record(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var value: [String: Any] = [
            "server_id": 1, "meeting_id": 2, "weekday": 2, "start_time": "19:30:15",
            "time_zone": "America/New_York", "organization_key": "na", "name": "Example",
            "duration": 3600, "virtual_information": ["url": "https://meet.google.com/abc-defg-hij"]
        ]
        value.merge(overrides) { _, new in new }
        return value
    }

    private func meeting(_ overrides: [String: Any] = [:]) throws -> Meeting {
        try XCTUnwrap(Meeting(record(overrides), searchCenter: nil))
    }

    private func page(_ meetings: [[String: Any]] = [], total: Int? = nil) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "meta": ["total": total ?? meetings.count, "actual_size": meetings.count,
                     "page_size": meetings.count, "starting_index": 0, "total_pages": 1,
                     "page": 0, "search_time": 0.01],
            "meetings": meetings
        ])
    }

    private func date(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }

    func testEmptyAndCountOnlyPages() throws {
        for count in [0, 42] {
            let parser = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: page(total: count), specification: .init(pageSize: 0)))
            XCTAssertTrue(parser.meetings.isEmpty)
            XCTAssertEqual(parser.meta.total, count)
        }
        let legacy = Data(#"{"meta":{"total":0},"meetings":[]}"#.utf8)
        XCTAssertNotNil(SwiftBMLSDK_Parser(jsonData: legacy, specification: .init()))
        XCTAssertNil(SwiftBMLSDK_Parser(jsonData: Data(#"{"meta":{},"meetings":[]}"#.utf8), specification: .init()))
    }

    func testMalformedMeetingRecordsAreSkipped() throws {
        for time in ["19:no:30", "19::30", "19:30:15:20", "24:00", "-1:30", "19:60"] {
            XCTAssertNil(Meeting(record(["start_time": time]), searchCenter: nil), time)
        }
        for fields in [["server_id": -1], ["meeting_id": -1], ["server_id": 0x100000], ["meeting_id": 0x100000000000]] {
            XCTAssertNil(Meeting(record(fields), searchCenter: nil))
        }
        let largest = try meeting(["server_id": 0xFFFFF, "meeting_id": 0xFFFFFFFFFFF])
        XCTAssertEqual(largest.id, UInt64.max)
        let parser = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: page([record(), record(["weekday": 8])]), specification: .init()))
        XCTAssertEqual(parser.meetings.count, 1)
        XCTAssertEqual(parser.meta.actualSize, 2)
    }

    func testPercentDecodingPreservesLiteralPercentSigns() throws {
        for (source, expected) in [("100% Recovery", "100% Recovery"), ("100%25 Recovery", "100% Recovery"), ("A%2520B", "A B")] {
            let result = try meeting(["name": source, "comments": source, "virtual_information": ["url": "https://example.com", "info": source]])
            XCTAssertEqual(result.name, expected)
            XCTAssertEqual(result.comments, expected)
            XCTAssertEqual(result.virtualInfo, expected)
            let format = Meeting.Format(key: source, name: source, description: source, language: "en", id: "1")
            XCTAssertEqual(format.key, expected)
            XCTAssertEqual(format.name, expected)
            XCTAssertEqual(format.description, expected)
        }
    }

    func testVirtualURLPreservesEscapesAndTrimsWhitespace() throws {
        let result = try meeting(["virtual_information": ["url": "  https://example.com/a%20b?pwd=a%26b  "]])
        XCTAssertEqual(result.virtualURL?.absoluteString, "https://example.com/a%20b?pwd=a%26b")
    }

    func testClockSecondsAndExportAreIndependentOfDeviceTimezone() throws {
        let value = try meeting()
        XCTAssertEqual(value.integerStartTime, 1930)
        XCTAssertEqual(value.startTimeInSecondsFromMidnight, 70215)
        XCTAssertEqual(value.dateComponents?.second, 15)
        XCTAssertTrue(value.description.contains("19:30:15"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
        XCTAssertEqual(json["startTime"] as? String, "19:30:15")
        XCTAssertEqual([value][70215.0..<70216.0].count, 1)
        XCTAssertTrue([value][70200.0..<70215.0].isEmpty)
    }

    func testCompactTimeStyleUsesFourDigits() throws {
        let value = try meeting(["time_zone": "UTC", "start_time": "19:30:00"])
        let text = value.localizedWeekdayTimeString(style: .twentyFourHourCompact,
                                                    locale: Locale(identifier: "en_US"),
                                                    includeDuration: true)
        XCTAssertEqual(text, "Monday 1930-2030")
    }

    func testOccurrenceBoundariesIncludeSeconds() throws {
        let value = try meeting(["time_zone": "UTC"])
        let reference = try date("2026-09-14T19:30:15Z")
        XCTAssertEqual(value.previousOccurrenceDateFast(from: reference), reference)
        XCTAssertEqual(value.nextOccurrenceDateFast(from: reference), try date("2026-09-21T19:30:15Z"))
        XCTAssertEqual(value.nextOccurrenceDateFast(from: reference.addingTimeInterval(-0.1)), reference)
    }

    func testSpringAndFallDaylightSavingKeepWallClockTime() throws {
        let value = try meeting(["weekday": 1, "start_time": "09:30:15"])
        XCTAssertEqual(value.nextOccurrenceDateFast(from: try date("2026-03-08T05:00:00Z")), try date("2026-03-08T13:30:15Z"))
        XCTAssertEqual(value.nextOccurrenceDateFast(from: try date("2026-11-01T04:00:00Z")), try date("2026-11-01T14:30:15Z"))
    }

    func testMissingHourAndPreviousOccurrenceUseSamePolicy() throws {
        let value = try meeting(["weekday": 1, "start_time": "02:30:15"])
        let expected = try date("2026-03-08T07:30:15Z")
        XCTAssertEqual(value.nextOccurrenceDateFast(from: try date("2026-03-08T07:15:00Z")), expected)
        XCTAssertEqual(value.previousOccurrenceDateFast(from: try date("2026-03-14T12:00:00Z")), expected)
    }

    func testRepeatedHourUsesFirstOccurrence() throws {
        let value = try meeting(["weekday": 1, "start_time": "01:30:15"])
        let first = try date("2026-11-01T05:30:15Z")
        XCTAssertEqual(value.nextOccurrenceDateFast(from: try date("2026-11-01T04:00:00Z")), first)
        XCTAssertEqual(value.previousOccurrenceDateFast(from: try date("2026-11-01T06:15:00Z")), first)
        XCTAssertEqual(value.nextOccurrenceDateFast(from: try date("2026-11-01T06:15:00Z")), try date("2026-11-08T06:30:15Z"))
    }

    func testCountdownNoLongerDependsOnUnpopulatedCache() throws {
        let value = try meeting()
        XCTAssertGreaterThan(value.nextMeetingIn, 0)
        XCTAssertEqual(value.nextMeetingIn, value.meetingStartsIn(), accuracy: 1)
    }

    func testComparisonUsesAbsoluteDatesAndIdentity() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let weekday = calendar.component(.weekday, from: Date()) % 7 + 1
        let eastern = try meeting(["weekday": weekday, "start_time": "09:00:00", "meeting_id": 1])
        let pacific = try meeting(["weekday": weekday, "start_time": "08:00:00", "meeting_id": 2, "time_zone": "America/Los_Angeles"])
        XCTAssertLessThan(eastern, pacific)
        XCTAssertFalse(pacific < eastern)
        let duplicate = try meeting(["weekday": weekday, "start_time": "01:00:00", "meeting_id": 1])
        XCTAssertEqual(eastern, duplicate)
        XCTAssertFalse(eastern < duplicate)
        XCTAssertFalse(duplicate < eastern)
    }

    func testWeekdayStylesAndAdjustedWeekStart() throws {
        let value = try meeting(["weekday": 4])
        XCTAssertEqual(value.localWeekdayString(style: .short), Calendar.autoupdatingCurrent.shortWeekdaySymbols[3])
        XCTAssertEqual(value.localWeekdayString(style: .standaloneFull), Calendar.autoupdatingCurrent.standaloneWeekdaySymbols[3])
        typealias Weekday = [Meeting].Weekdays
        XCTAssertEqual(Weekday(rawValue: 1, isAdjusted: true)?.rawValue, Calendar.current.firstWeekday)
        for invalid in [0, -1, 8] { XCTAssertNil(Weekday(rawValue: invalid, isAdjusted: true)) }
    }

    func testDistanceFormattingOverloadsRemainUsable() throws {
        let value = try meeting(["latitude": 40.0, "longitude": -74.0, "physical_address": ["street": "1 Main Street"]])
        let center = CLLocationCoordinate2D(latitude: 40.01, longitude: -74)
        let defaultString = value.distanceStringFrom(location: center)
        XCTAssertFalse(defaultString.isEmpty)
        XCTAssertEqual(defaultString, value.distanceStringFrom(location: center, width: .abbreviated))
        XCTAssertEqual(defaultString, value.distanceStringFrom(location: center, width: Meeting.DistanceStringWidth.abbreviated))
        XCTAssertEqual(defaultString, value.distanceStringFrom(location: center, width: Meeting.DistanceUnitWidth.abbreviated))
    }

    func testSearchDistanceIsOnlySetForGeographicRequests() throws {
        let data = try page([record(["latitude": 40.0, "longitude": -74.0, "physical_address": ["street": "1 Main Street"]])])
        let ordinary = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: data, specification: .init()))
        XCTAssertEqual(ordinary.meetings.first?.distanceInMeters, -1)
        let center = CLLocationCoordinate2D(latitude: 40, longitude: -74)
        let nearby = try XCTUnwrap(SwiftBMLSDK_Parser(jsonData: data, specification: .init(locationCenter: center, locationRadius: 1000)))
        XCTAssertEqual(nearby.meetings.first?.distanceInMeters, 0)
        XCTAssertEqual(ordinary.meetings.first?.distanceInMeters, -1)
        XCTAssertEqual(nearby.meetings.first?.distanceFrom(kCLLocationCoordinate2DInvalid), -1)
    }

    func testIDQueriesIgnoreMeetingTypeButKeepPaging() throws {
        let spec = SwiftBMLSDK_Query.SearchSpecification(type: .inPerson(isExclusive: true), meetingIDs: [UInt64.max], pageSize: 10, page: 2)
        let items = spec.urlQueryItems
        XCTAssertEqual(items.first(where: { $0.name == "ids" })?.value, "(1048575,17592186044415)")
        XCTAssertEqual(items.first(where: { $0.name == "page" })?.value, "2")
        XCTAssertFalse(items.contains { $0.name == "type" || $0.name == "geo_radius" })
        XCTAssertEqual(SwiftBMLSDK_Parser(jsonData: try page([record()]), specification: spec)?.meetings.count, 1)
    }

    func testCoordinateBoundsHandleLinesDuplicatesAndDateLine() throws {
        func physical(_ lat: Double, _ lon: Double) throws -> Meeting {
            try meeting(["latitude": lat, "longitude": lon, "physical_address": ["street": "1 Main Street"]])
        }
        XCTAssertNil([Meeting]().mapRegion)
        let first = try physical(40, -74)
        XCTAssertNotNil([first, first].mapRegion)
        XCTAssertNotNil(try [first, physical(40, -73)].mapRegion)
        XCTAssertNotNil(try [first, physical(41, -74)].mapRegion)
        let region = try XCTUnwrap([physical(10, 179), physical(10, -179)].mapRegion)
        XCTAssertEqual(region.span.longitudeDelta, 2, accuracy: 0.001)
        XCTAssertEqual(abs(region.center.longitude), 180, accuracy: 0.001)
    }

    func testCachedMeetingReplacementInvalidatesDate() throws {
        let cached = try SwiftBMLSDK_MeetingLocalTimezoneCollection.CachedMeeting(meeting: meeting())
        let original = cached.nextDate
        cached.meeting = try meeting(["weekday": 5])
        XCTAssertNotEqual(cached.nextDate, original)
        XCTAssertEqual(cached.nextDate, cached.meeting.nextOccurrenceDateFast())
        XCTAssertEqual(cached.isInProgress, cached.meeting.isMeetingInProgressNow)
    }

    func testDirectLinksKeepPasswordAndRoomPaths() throws {
        #if canImport(UIKit)
            let old = ProcessInfo.processInfo.environment["SKIP_CANOPEN"]
            setenv("SKIP_CANOPEN", "1", 1)
            defer { if let old = old { setenv("SKIP_CANOPEN", old, 1) } else { unsetenv("SKIP_CANOPEN") } }
        #endif
        let zoom = try XCTUnwrap(Meeting.DirectVirtual.zoom(URL(string: "https://us02web.zoom.us/j/123456789?pwd=a%26b&other=1")).directURL)
        XCTAssertEqual(URLComponents(url: zoom, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "pwd" })?.value, "a&b")
        XCTAssertEqual(Meeting.DirectVirtual.meet(URL(string: "https://meet.google.com/abc-defg-hij")).directURL?.path, "/abc-defg-hij")
        XCTAssertEqual(Meeting.DirectVirtual.skype(URL(string: "https://join.skype.com/room")).directURL?.path, "/room")
        XCTAssertEqual(Meeting.DirectVirtual.jitsi(URL(string: "https://meet.jit.si/room")).directURL?.host, "meet.jit.si")
        XCTAssertNotNil(Meeting.DirectVirtual.factory(url: try XCTUnwrap(URL(string: "https://meet.jit.si/room"))))
        XCTAssertNil(Meeting.DirectVirtual.factory(url: try XCTUnwrap(URL(string: "https://zoom.us.example.com/j/123456789"))))
        XCTAssertNil(Meeting.DirectVirtual.discord(URL(string: "https://discord.com")).directURL)
        XCTAssertNil(Meeting.DirectVirtual.discord(URL(string: "https://discord.com/channels")).directURL)
        XCTAssertEqual(Meeting.DirectVirtual.discord(URL(string: "https://discord.com/channels/123/456")).directURL?.absoluteString, "discord://channels/123/456")
        XCTAssertEqual(Meeting.DirectVirtual.discord(URL(string: "https://discord.com/123")).directURL?.absoluteString, "discord://channels/123")
    }

    #if !SWIFTBMLSDK_DOCS
    func testDialInURLsRetainDTMFAndRejectAmbiguity() throws {
        for raw in ["+1 (212) 555-1212,,1234567890#", "tel:+12125551212,,1234567890%23", "New York: +1 212 555 1212 Meeting ID: 1234567890"] {
            let value = try meeting(["virtual_information": ["phone_number": raw]])
            XCTAssertEqual(value.directPhoneURI?.absoluteString, "tel:+12125551212,,1234567890%23", raw)
            XCTAssertNil(value.directPhoneURI?.fragment)
        }
        let shortPIN = try meeting(["virtual_information": ["phone_number": "+1 212 555 1212 PIN: 1"]])
        XCTAssertEqual(shortPIN.directPhoneURI?.absoluteString, "tel:+12125551212,,1%23")
        let multiple = try meeting(["virtual_information": ["phone_number": "+1 212 555 1212 or +1 646 555 1212"]])
        XCTAssertNil(multiple.directPhoneURI)
    }
    #endif

    /* ################################################################## */
    /**
     Creates a query backed by a local URL protocol; these tests never contact a server.
     */
    private func query(_ handler: @escaping (URLRequest) throws -> (Int, String, Data)) -> SwiftBMLSDK_Query {
        SwiftBMLSDK_TestURLProtocol.handler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SwiftBMLSDK_TestURLProtocol.self]
        let session = URLSession(configuration: config)
        addTeardownBlock { session.invalidateAndCancel() }
        return SwiftBMLSDK_Query(serverBaseURI: URL(string: "https://sdk.test/entrypoint.php?existing=yes#fragment"), session: session)
    }

    func testQueryPreservesTransportErrorsAndMainQueueDelivery() {
        let query = query { _ in throw URLError(.timedOut) }
        let searchDone = expectation(description: "Search error")
        let infoDone = expectation(description: "Info error")
        query.meetingSearch(specification: .init()) { parser, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(parser)
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
            searchDone.fulfill()
        }
        query.serverInfo { result, error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(result)
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
            infoDone.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testInvalidURLCompletesAsynchronouslyOnMainQueue() {
        let done = expectation(description: "Invalid URL")
        var returned = false
        SwiftBMLSDK_Query().meetingSearch(specification: .init()) { parser, error in
            XCTAssertTrue(returned)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNil(parser)
            XCTAssertEqual((error as? URLError)?.code, .badURL)
            done.fulfill()
        }
        returned = true
        waitForExpectations(timeout: 5)
    }

    func testHTTPAndMalformedResponseErrors() throws {
        for (status, mime, body, code) in [
            (503, "application/json", try page(), URLError.Code.badServerResponse),
            (200, "text/html", Data("error".utf8), .cannotDecodeContentData),
            (200, "application/json", Data("not json".utf8), .cannotDecodeContentData),
            (200, "application/json", Data("{}".utf8), .cannotDecodeContentData)
        ] {
            let query = query { _ in (status, mime, body) }
            let done = expectation(description: "Invalid response")
            query.meetingSearch(specification: .init()) { parser, error in
                XCTAssertNil(parser)
                XCTAssertEqual((error as? URLError)?.code, code)
                if status == 503 { XCTAssertEqual((error as NSError?)?.userInfo["HTTPStatusCode"] as? Int, 503) }
                done.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func testServerInfoPreservesExistingQueryAndEmptyServer() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "server_version": "1.0", "last_update_timestamp": 100,
            "organizations": ["na": 2, "total_meetings": 2],
            "services": ["bmlt": ["service_name": "BMLT", "servers": [
                "01": ["name": "Empty", "num_meetings": 0, "url": "https://example.com", "organizations": [String: Int]()]
            ]]]
        ])
        let query = query { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            XCTAssertTrue(items.contains { $0.name == "existing" && $0.value == "yes" })
            XCTAssertTrue(items.contains { $0.name == "info" })
            XCTAssertNil(request.url?.fragment)
            return (200, "application/json", data)
        }
        let done = expectation(description: "Server info")
        query.serverInfo { result, error in
            XCTAssertNil(error)
            XCTAssertEqual(result?.totalServers, 1)
            XCTAssertEqual(result?.services.first?.servers.first?.id, 1)
            XCTAssertNil(result?.organizationTotals["total_meetings"])
            done.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAutoRadiusSearchReachesExactMaximumAndReturnsPartialResults() throws {
        let empty = try page()
        let partial = try page([record()])
        var radii: [Double] = []
        let query = query { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let radius = Double(items.first(where: { $0.name == "geo_radius" })?.value ?? "") ?? -1
            radii.append(radius)
            XCTAssertFalse(items.contains { $0.name == "page_size" || $0.name == "page" })
            return (200, "application/json", radius < 0.2 ? empty : partial)
        }
        let done = expectation(description: "Auto radius partial result")
        query.meetingAutoRadiusSearch(minimumNumberOfResults: 3, specification: .init(locationRadius: 250, pageSize: 1, page: 4)) { parser, error in
            XCTAssertNil(error)
            XCTAssertEqual(parser?.meetings.count, 1)
            XCTAssertEqual(radii, [0.1, 0.2, 0.25])
            done.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAutoRadiusCanStartBelowOneHundredMeters() throws {
        let empty = try page()
        var requests = 0
        let query = query { request in
            requests += 1
            XCTAssertTrue(request.url?.query?.contains("geo_radius=0.01") ?? false)
            return (200, "application/json", empty)
        }
        let done = expectation(description: "Small radius")
        query.meetingAutoRadiusSearch(minimumNumberOfResults: 1, specification: .init(locationRadius: 10)) { parser, error in
            XCTAssertNil(error)
            XCTAssertNotNil(parser)
            XCTAssertEqual(requests, 1)
            done.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAutoRadiusStopsAsSoonAsTargetIsReached() throws {
        let data = try page([record()])
        var requests = 0
        let query = query { _ in requests += 1; return (200, "application/json", data) }
        let done = expectation(description: "Target reached")
        query.meetingAutoRadiusSearch(minimumNumberOfResults: 1, specification: .init(locationRadius: 1000)) { parser, error in
            XCTAssertNil(error)
            XCTAssertEqual(parser?.meetings.count, 1)
            XCTAssertEqual(requests, 1)
            done.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAutoRadiusUsesOneRequestForIDsAndExclusiveVirtualMeetings() throws {
        let data = try page()
        for specification in [SwiftBMLSDK_Query.SearchSpecification(meetingIDs: [1], pageSize: 2), .init(type: .virtual(isExclusive: true), pageSize: 2)] {
            var requests = 0
            let query = query { request in
                requests += 1
                let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                XCTAssertFalse(items.contains { $0.name == "geo_radius" })
                XCTAssertEqual(items.first(where: { $0.name == "page_size" })?.value, "2")
                return (200, "application/json", data)
            }
            let done = expectation(description: "Nongeographic search")
            query.meetingAutoRadiusSearch(minimumNumberOfResults: 100, specification: specification) { parser, error in
                XCTAssertNil(error)
                XCTAssertNotNil(parser)
                XCTAssertEqual(requests, 1)
                done.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func testAutoRadiusRejectsInvalidGeographyWithoutRequesting() {
        for specification in [SwiftBMLSDK_Query.SearchSpecification(locationCenter: kCLLocationCoordinate2DInvalid), .init(locationRadius: .infinity), .init(locationRadius: .nan)] {
            let query = query { _ in XCTFail("Invalid geography must not start a request"); throw URLError(.badURL) }
            let done = expectation(description: "Invalid geography")
            query.meetingAutoRadiusSearch(minimumNumberOfResults: 1, specification: specification) { parser, error in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(parser)
                XCTAssertEqual((error as? URLError)?.code, .badURL)
                done.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func testAutoRadiusStopsOnError() {
        var requests = 0
        let query = query { _ in requests += 1; throw URLError(.notConnectedToInternet) }
        let done = expectation(description: "Auto radius error")
        query.meetingAutoRadiusSearch(minimumNumberOfResults: 1, specification: .init(locationRadius: 1000)) { parser, error in
            XCTAssertNil(parser)
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
            XCTAssertEqual(requests, 1)
            done.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}

/* ###################################################################################################################################### */
// MARK: - Local HTTP Response Stub -
/* ###################################################################################################################################### */
private final class SwiftBMLSDK_TestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, String, Data))?

    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "sdk.test" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let response = try Self.handler!(request)
            let http = HTTPURLResponse(url: request.url!, statusCode: response.0, httpVersion: nil, headerFields: ["Content-Type": response.1])!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.2)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
