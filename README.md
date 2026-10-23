# SwiftBMLSDK

![SwiftBMLSDK icon](icon.png)

A native Swift client for the [LGV_MeetingServer](https://github.com/LittleGreenViper/LGV_MeetingServer) meeting aggregator. Version **1.5.7**.

## Requirements and installation

Supports iOS/iPadOS 16+, macOS 13+, and watchOS 9+. tvOS is unsupported because the SDK's public address type requires Contacts, which tvOS does not provide. The SDK uses Swift 5 language mode; normal builds require Swift tools 5.9+ through the PhoneNumberKit 5 dependency.

Add `https://github.com/LittleGreenViper/SwiftBMLSDK` as a Swift package dependency, then add the `SwiftBMLSDK` library product to your target. [PhoneNumberKit](https://github.com/PhoneNumberKit/PhoneNumberKit) is resolved automatically.

## Search for meetings

Use the complete HTTP or HTTPS entrypoint URL of your aggregator, including the script name when required. Replace the example URL below with your server's URL.

```swift
import Foundation
import SwiftBMLSDK
import CoreLocation

let query = SwiftBMLSDK_Query(
    serverBaseURI: URL(string: "https://example.org/LGV_MeetingServer/entrypoint.php")
)
let specification = SwiftBMLSDK_Query.SearchSpecification(
    type: .inPerson(isExclusive: false),
    locationCenter: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    locationRadius: 5_000
)

query.meetingSearch(specification: specification) { results, error in
    if let error = error {
        print("Search failed: \(error.localizedDescription)")
        return
    }
    guard let results = results else { return }
    for meeting in results.meetings {
        print(meeting.name, meeting.localizedWeekdayTimeString())
    }
}
```

Query completions run once, asynchronously on the main queue, including failures before a request starts. Successful empty searches return a parser with an empty `meetings` array. Transport errors are preserved; HTTP failures return `URLError.badServerResponse`, with `HTTPStatusCode` in the error's `userInfo`. Invalid response content returns `URLError.cannotDecodeContentData`. Requests on the same query instance run independently.

`meetingSearch` returns its `URLSessionDataTask` (or nil for an invalid URL).
Retain it and call `cancel()` to stop that request without affecting other searches;
its completion receives `URLError.cancelled`. Ignoring the return value preserves
existing behavior. A higher-level owner should also discard cancelled results
that were already being parsed or queued for delivery when cancellation occurred.

## Search options

- `locationRadius` is in **meters**. Nonpositive or nonfinite radii disable geographic filtering for an ordinary search. Coordinates must be valid; the default center is `(0, 0)`.
- `.inPerson()` and `.virtual()` include hybrid meetings. Set `isExclusive: true` to exclude hybrids. `.hybrid` selects meetings with both components. Exclusively virtual searches ignore location.
- `meetingIDs` accepts the composite `meeting.id` values. IDs override type and location filters; paging still applies.
- `pageSize` defaults to `-1` (all results). Use `0` for metadata only, or a positive size and zero-based `page` for paging.
- `meetingAutoRadiusSearch(minimumNumberOfResults:specification:priority:completion:)` expands from 100 meters (or a smaller maximum), doubling until the target count or exact maximum radius is reached. A nonpositive maximum means 100 km. Geographic auto-radius searches ignore paging and may return fewer meetings than requested. ID or exclusively virtual specifications perform a single ordinary search.
- `serverInfo(completion:)` returns the aggregator version, last update, services, and organization totals.

The parser preserves server order, skips invalid meeting records, and applies the requested meeting type. Metadata counts come from the server and can exceed the number of accepted meetings. Missing or invalid timezones cause a record to be skipped by default. Setting the process environment variable `IGNORE_NO_TZ` accepts those records using the device's current timezone.

## Meeting accessibility and attendance flags

`SwiftBMLSDK_Parser.Meeting` exposes `wheelchairAccessible`, `isOpen`, and
`isClosed` as `Bool?`, read from the server's `wheelchair_accessible`, `is_open`,
and `is_closed` fields. LGV_MeetingServer 1.6.1 emits `true` when the source
explicitly asserts a flag and otherwise omits it. Missing fields (including older
responses) and JSON null become `nil`, meaning unknown. Missing accessibility
does not mean inaccessible; missing open/closed status does not assert its opposite.
Explicit Boolean `false` is retained if supplied. Invalid types, including numeric
or string booleans, cause the meeting record to be skipped.

The three flags are independent: `isOpen` and `isClosed` can both be true when
upstream data conflicts. They are independent of venue type, and are never inferred
from localized display `formats` such as `O`, `C`, or `WC`. Existing format objects
and composite meeting identity remain unchanged.

```swift
let confirmedAccessible = results.meetings.filter { $0.wheelchairAccessible == true }
let confirmedOpen = results.meetings.filter { $0.isOpen == true }
let conflictingStatus = results.meetings.filter { $0.isOpen == true && $0.isClosed == true }
```

Filtering is local to the fetched results. No server flag filters are available;
metadata counts describe the original query, and further pages may contain matches.
The SDK's flat JSON export uses `wheelchairAccessible`, `isOpen`, and `isClosed`,
omitting nil values and retaining both true and false. The export remains a separate
schema and is not an input cache format.

## Dates, filtering, and display

`weekday` uses Sunday = 1 through Saturday = 7 in the meeting's timezone. `startTime` stores a floating clock time on January 1, 2001, in GMT; it is not an actual meeting date. Prefer these helpers:

- `nextOccurrenceDateFast(from:calendar:)` returns the next absolute occurrence strictly after the reference date.
- `previousOccurrenceDateFast(from:calendar:)` returns the most recent occurrence at or before the reference date.
- `localizedWeekdayTimeString(adjusted: true)` displays the next occurrence in the user's timezone. The default, `adjusted: false`, displays the meeting's timezone. `includeDuration: true` adds the end time.
- `isMeetingInProgressNow` includes the start and excludes the end. Zero-duration meetings are never in progress.

Occurrence calculations preserve local clock time across daylight-saving changes. Missing hours move forward while preserving minutes and seconds; repeated hours use the first occurrence.

```swift
func mondayMorningMeetings(in results: SwiftBMLSDK_Parser) -> [SwiftBMLSDK_Parser.Meeting] {
    let morning: Range<TimeInterval> = 32_400..<43_200
    return results.inPersonMeetings[.monday][morning]
}
```

Weekday and time filters use each meeting's own timezone. Use a `Range<TimeInterval>` for time filtering: an integer range selects Swift's standard array-index subscript. `localWeekdayIndex` changes weekday ordering to match the user's calendar, without timezone conversion.

Meeting arrays expose `allCoords`, `mapRegion`, and `asJSONData`. Exported JSON uses the SDK's flattened field names and is **not** the server's input schema. `distanceInMeters` is `-1` when no geographic search distance is available; `distanceInMeters(from:)` returns an optional distance for an explicit coordinate.

`SwiftBMLSDK_MeetingLocalTimezoneCollection` fetches virtual and hybrid meetings once and caches upcoming dates. Use it on the main thread. `refreshCaches` recalculates stored dates without fetching the server; the fetch callback has no error argument, so use `SwiftBMLSDK_Query` directly when you need error details.

## App and phone links

`directAppURI` converts recognized meeting URLs into app links. On iOS and iPadOS, read it on the main thread and declare the schemes your app uses in `LSApplicationQueriesSchemes`: `zoomus`, `lmi-g2m`, `skype`, `gmeet`, `discord`, and `org.jitsi.meet`. The SDK checks `canOpenURL`; macOS and watchOS generate links without checking installation. A generated URL does not guarantee that a particular service or app version accepts it. The `SKIP_CANOPEN` environment variable bypasses this check for testing.

`directPhoneURI` creates a normalized `tel:` URL, retaining pauses and numeric meeting IDs or PINs. Numbers without an international prefix use the US region. Ambiguous multiple-number strings return `nil`. This property does not test whether the device can place calls.

## Documentation and tests

The source uses block-style HeaderDoc comments for Xcode Quick Help and DocC. Open the package in Xcode and choose **Product → Build Documentation** for the API reference and guides. The catalog is in `Sources/SwiftBMLSDK/SwiftBMLSDK.docc`.

Run `swift test` on macOS to run the meeting-dump checks and deterministic regressions. The query regressions use local HTTP stubs and do not contact a live server.

`SWIFTBMLSDK_DOCS=1` omits PhoneNumberKit for documentation-only builds; phone URL helpers return `nil` in that configuration. Use normal builds for runtime validation. The existing `docs/` directory contains separately generated Jazzy documentation.

See [CHANGELOG.md](CHANGELOG.md) for release history. Licensed under the [MIT License](LICENSE).

To run the optional prerelease flag smoke test (one page of at most ten meetings):

```sh
SWIFTBMLSDK_LIVE_TESTS=1 swift test --filter testPrereleaseMeetingFlagsLive
```

It checks the prerelease `info` response and compares parsed flags with the wire
response by server and meeting ID. Live records may change; deterministic tests
cover every flag combination, legacy responses, null, false, and malformed values.
