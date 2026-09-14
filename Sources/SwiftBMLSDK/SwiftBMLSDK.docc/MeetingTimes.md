# Meeting Times and Timezones

Convert a weekly wall-clock schedule into an absolute date and a localized display.

## Overview

### Understand the stored schedule

A meeting's ``SwiftBMLSDK_Parser/Meeting/weekday`` is Sunday = 1 through Saturday = 7.
``SwiftBMLSDK_Parser/Meeting/startTime`` is a floating clock value stored on January 1, 2001,
in GMT. Its hour, minute, and second describe the schedule in ``SwiftBMLSDK_Parser/Meeting/timeZone``.
It is not a real meeting occurrence; formatting it in the device timezone changes its apparent clock time.

For wall-clock access, use ``SwiftBMLSDK_Parser/Meeting/integerStartTime`` (`HHMM`),
``SwiftBMLSDK_Parser/Meeting/startTimeInSecondsFromMidnight``, or
``SwiftBMLSDK_Parser/Meeting/dateComponents``.

By default, the parser skips meetings with a missing or invalid timezone. Setting `IGNORE_NO_TZ`
in the process environment accepts them using the device's current timezone, which may differ
from the meeting's intended schedule.

### Calculate real occurrences

``SwiftBMLSDK_Parser/Meeting/nextOccurrenceDateFast(from:calendar:)`` returns the first occurrence
strictly after the reference instant. At the exact meeting start, it returns next week's start.
``SwiftBMLSDK_Parser/Meeting/previousOccurrenceDateFast(from:calendar:)`` includes the reference
instant, so at the exact start it returns the occurrence starting now.

Both methods return absolute `Date` values. Do not shift them by timezone offsets. Set a formatter's
timezone to display the same instant in another location.

The schedule retains its wall-clock time across daylight-saving changes. For nonexistent times,
a missing hour moves forward while preserving minutes and seconds: 02:30 becomes 03:30. When an hour
repeats, the first occurrence is used. These rules also apply to previous-occurrence and in-progress checks.

``SwiftBMLSDK_Parser/Meeting/isMeetingInProgressNow`` and ``SwiftBMLSDK_Parser/Meeting/isMeetingInProgress()``
include the start and exclude the end. Zero-duration meetings are never in progress. The
``SwiftBMLSDK_Parser/Meeting/nextMeetingIn`` property and ``SwiftBMLSDK_Parser/Meeting/meetingStartsIn()``
calculate a fresh countdown, rounded up to whole seconds.

### Display the meeting

Use ``SwiftBMLSDK_Parser/Meeting/localizedWeekdayTimeString(style:locale:calendar:timeZone:adjusted:includeDuration:)``
for a localized weekday and time. Its default displays the meeting's timezone. Pass `adjusted: true`
to display the device timezone or the supplied `timeZone` argument. `includeDuration: true` appends the
end time; the weekday shown is the start's weekday, even if the end is on another day.

``SwiftBMLSDK_Parser/Meeting/localWeekdayString(style:)`` localizes the scheduled weekday's name.
``SwiftBMLSDK_Parser/Meeting/localWeekdayIndex`` converts it to a zero-based position relative to
the device calendar's first weekday. Neither changes the schedule to the device timezone.
``SwiftBMLSDK_Parser/Meeting/adjustedIntegerStartTime`` does convert the next occurrence to the device timezone.

### Sort and cache

Meeting comparison sorts by next absolute occurrence, then meeting type, name, and ID. Equality
and hashing use the composite ID. For a large list, calculate `sortingKeyFast(from:)` for each
meeting using one shared reference date, then sort those cached keys.

``SwiftBMLSDK_MeetingLocalTimezoneCollection`` fetches virtual and hybrid meetings once.
Its ``SwiftBMLSDK_MeetingLocalTimezoneCollection/CachedMeeting`` objects recalculate upcoming
starts after the cached time passes or the underlying meeting is replaced. Stored dates remain
absolute instants and the underlying meetings retain their original timezones.

Use this mutable collection on the main thread. `refreshCaches` recalculates dates for the
stored meetings; it does not fetch new data. Initialization callbacks run asynchronously on
the main queue and return an empty collection on failure. Use the query API directly when
an application needs to distinguish a fetch failure from an empty response.
