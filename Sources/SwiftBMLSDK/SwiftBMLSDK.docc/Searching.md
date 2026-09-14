# Searching and Handling Results

Choose a search, handle its response, and filter the accepted meetings.

## Overview

### Configure the request

``SwiftBMLSDK_Query/serverBaseURI`` is the complete HTTP or HTTPS entrypoint, not necessarily
a directory. Existing URL query items are preserved. A missing or invalid URL produces
`URLError.badURL` in the completion.

``SwiftBMLSDK_Query/SearchSpecification`` controls the request:

| Option | Behavior |
| --- | --- |
| `type` | `.any` by default. In-person and virtual searches include hybrids unless exclusive. |
| `locationCenter` | Valid latitude and longitude. The default is `(0, 0)`. |
| `locationRadius` | Meters; nonpositive or nonfinite values disable ordinary geographic searches. |
| `meetingIDs` | Composite meeting IDs. Overrides type and location, while retaining paging. |
| `pageSize` | Negative means all results; zero means metadata only; positive means a page limit. |
| `page` | Zero-based page number. Nonpositive values request the first page. Ignored without a positive page size. |

Exclusively virtual requests ignore geographic fields. A meeting's ``SwiftBMLSDK_Parser/Meeting/id``
combines a 20-bit server ID and a 44-bit local meeting ID; use it directly for ID requests.

### Completion and error behavior

All query completions run once, asynchronously on the main queue. Parsing occurs before that
delivery. Independent requests do not cancel one another, including requests made from copies
of the same query struct.

A successful response always provides a parser or server-info object and no error. An empty
or count-only meeting response has an empty ``SwiftBMLSDK_Parser/meetings`` array. Failures
provide an error and no result:

- Network and cancellation errors are passed through from the URL session.
- Non-success HTTP status codes produce `URLError.badServerResponse`; `HTTPStatusCode` in
  the error's `userInfo` contains the status code.
- Missing JSON data, an incompatible content type, invalid JSON, or missing required response
  fields produces `URLError.cannotDecodeContentData`.

Meeting records with invalid fields are skipped. ``SwiftBMLSDK_Parser/meta`` reports the server's
original counts, so ``SwiftBMLSDK_Parser/PageMeta/actualSize`` can differ from the parsed array count.
The parser preserves server order; it does not automatically sort meetings.

### Expand a geographic search

``SwiftBMLSDK_Query/meetingAutoRadiusSearch(minimumNumberOfResults:specification:priority:completion:)``
starts at the smaller of 100 meters and the maximum radius, then doubles the radius until the target
number of parsed meetings is reached. It always requests the exact maximum before giving up and
returns that successful response even if it has too few meetings or none.

A nonpositive maximum means 100,000 meters. Geographic auto-radius searches require valid coordinates
and a finite radius. They ignore paging so every result at each radius can be counted. An error stops
the search immediately. For IDs or exclusively virtual meetings, this method runs one ordinary search
with the original specification because the geographic radius has no effect.

### Filter and export

The parser offers ``SwiftBMLSDK_Parser/inPersonMeetings``, ``SwiftBMLSDK_Parser/virtualMeetings``,
and ``SwiftBMLSDK_Parser/hybridMeetings``, plus exclusive variants. Meeting arrays can be filtered
by weekday and wall-clock time:

```swift
import Foundation
import SwiftBMLSDK

func filter(_ results: SwiftBMLSDK_Parser) -> [SwiftBMLSDK_Parser.Meeting] {
    let morning: Range<TimeInterval> = 32_400..<43_200
    return results.inPersonMeetings[.monday][morning]
}
```

An integer range invokes Swift's array-index subscript; use `Range<TimeInterval>` for time filtering.
These filters use each meeting's own timezone, not the user's display timezone.

A meeting array's `asJSONData` uses sorted JSON keys and flattened meeting fields, including
`startTime`, `timezone`, and `format-<id>`. This is an export format, not a round-trip copy of the
server response. ``SwiftBMLSDK_Parser`` and its meetings conform to `Encodable`, not `Decodable`.
