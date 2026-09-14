# ``SwiftBMLSDK``

Search an LGV_MeetingServer aggregator and interpret its weekly meeting schedules.

## Overview

![SwiftBMLSDK icon](icon.png)

Create a ``SwiftBMLSDK_Query`` with your aggregator's complete entrypoint URL. Search results
arrive as a ``SwiftBMLSDK_Parser`` with server metadata and an array of meeting objects.
Query completions run once, asynchronously on the main queue. Empty searches are successful
responses with an empty meeting array; failures provide an error.

The SDK supports iOS/iPadOS 16+, macOS 13+, and watchOS 9+. tvOS is unsupported because
the public address type requires Contacts, which tvOS does not provide. It uses Swift 5
language mode and depends on PhoneNumberKit 5, which requires Swift tools 5.9 or newer.

```swift
import Foundation
import SwiftBMLSDK

let query = SwiftBMLSDK_Query(
    serverBaseURI: URL(string: "https://example.org/LGV_MeetingServer/entrypoint.php")
)
query.meetingSearch(specification: .init(type: .virtual())) { results, error in
    if let error = error {
        print(error.localizedDescription)
        return
    }
    for meeting in results?.meetings ?? [] {
        print(meeting.name, meeting.localizedWeekdayTimeString(adjusted: true))
    }
}
```

Replace the example URL with your server's actual entrypoint. See <doc:Searching> for
paging and radius searches, and <doc:MeetingTimes> for timezone-aware display.

## Topics

### Guides

- <doc:Searching>
- <doc:MeetingTimes>
- <doc:MeetingLinks>

### Queries

- ``SwiftBMLSDK_Query``
- ``SwiftBMLSDK_Query/SearchSpecification``
- ``SwiftBMLSDK_Query/meetingSearch(specification:priority:completion:)``
- ``SwiftBMLSDK_Query/meetingAutoRadiusSearch(minimumNumberOfResults:specification:priority:completion:)``
- ``SwiftBMLSDK_Query/serverInfo(completion:)``
- ``SwiftBMLSDK_Query/ServerInfo``

### Results and Schedules

- ``SwiftBMLSDK_Parser``
- ``SwiftBMLSDK_Parser/PageMeta``
- ``SwiftBMLSDK_Parser/Meeting``
- ``SwiftBMLSDK_Parser/Meeting/nextOccurrenceDateFast(from:calendar:)``
- ``SwiftBMLSDK_Parser/Meeting/previousOccurrenceDateFast(from:calendar:)``
- ``SwiftBMLSDK_Parser/Meeting/localizedWeekdayTimeString(style:locale:calendar:timeZone:adjusted:includeDuration:)``

### Collections and Links

- ``SwiftBMLSDK_MeetingLocalTimezoneCollection``
- ``SwiftBMLSDK_MeetingLocalTimezoneCollection/CachedMeeting``
- ``SwiftBMLSDK_MeetingProtocol``
- ``SwiftBMLSDK_Parser/Meeting/directAppURI``
- ``SwiftBMLSDK_Parser/Meeting/directPhoneURI``
