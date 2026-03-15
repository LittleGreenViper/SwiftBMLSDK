 **1.3.9** *March 15, 2026*
 
 - I now use the new fast date calculator, wherever possible.
 
 **1.3.8** *March 15, 2026*
 
 - Added a couple of fast date calculators, so no more stupid mutating functions.
 
 **1.3.7** *March 15, 2026*
 
 - Made the Meeting type identifiable.
 
 **1.3.6** *March 15, 2026*
 
 - Added localized handling of distance to meetings.
 
 **1.3.1** *March 15, 2026*
 
 - Updated the documentation.
 - Added the ability to get the duration included into the localized time string.
 - Updated the PhoneNumberKit version.
 
 **1.3.0** *March 14, 2026*
 
 - Added a dependency to PhoneNumberKit, and an extractor for phone URLs.
 
 **1.2.5** *March 13, 2026*
 
 - Added the ability to have a priority assigned to a search.
 - Updated the file headers.
 
 **1.2.4** *March 8, 2026*
 
 - Added the mapRegion computed property to the meeting array extension.
 
 **1.2.3** *March 7, 2026*
 
 - Fixed visibility issue.
 - Fixed documentation issue.
 
 **1.2.0** *March 7, 2026*
 
 - Added support for localized address and time.
 - Updated the tools.
 - Fixed some documentation issues.
 
 **1.1.8** *May 26, 2025*
 
 - Added a rather ineffective QUIC fix for simulator network issues. I think I'll have to wait for Apple to fix it.
 
 **1.1.7** *January 14, 2025*
 
 - Added "Belt and supenders" URL decoding to the various text fields, as there might actually be double-encoded data (data hygiene).
 
 **1.1.6** *December 17, 2024*
 
 - I now change the way the search radius expands, depending on its scope.
 
 **1.1.5** *December 15, 2024*
 
 - Remove percent encoding (data hygiene).
 
 **1.1.4** *December 13, 2024*
 
 - Added the `distanceInMeters` property to the meeting struct.
 
 **1.1.3** *December 13, 2024*
 
 - Added the `distanceFrom(_:)` method to the meeting struct.
 
 **1.1.2** *December 12, 2024*
 
 - Made the meetings sortable.
 
 **1.1.1** *December 12, 2024*
 
  - Added an ID-specific search.

 **1.1.0** *December 12, 2024*
 
 - Added an auto-radius search to the query struct.
 
 **1.0.20** *August 28, 2024*
 
 - Added simple sorting to the JSON output. Not perfect, but keeps it consistent.
 
 **1.0.19** *August 28, 2024*
 
 - Made some changes to the JSON output of the Meeting Array extension.
 - Updated the dependencies in the test harness app.
 
 **1.0.18** *August 22, 2024*
 
 - Added a weekday string to the JSON dump, as that should help NLP model training.
 
 **1.0.17** *August 6, 2024*
 
 - Documentation cleanup. No API changes.
 
 **1.0.16** *July 31, 2024*
 
 - If a meeting has no timezone, it can be skipped (specify "IGNORE_NO_TZ" as an environment variable). This allows meetings to "opt out," by not specifying a timezone.
 
 **1.0.15** *July 27, 2024*
 
 - Made the next start time getter faster.
 
 **1.0.14** *July 23, 2024*
 
 - Added a SKIP_CANOPEN environment variable, that allows the library to ignore whether or not the URL should be openable (DO NOT USE FOR SHIP!)
 
 **1.0.13** *July 23, 2024*
 
 - Tweaked the phone number filtering a bit.
 
 **1.0.12** *July 22, 2024*
 
 - Added more flexibility, with the phone number parsing.
 
 **1.0.11** *July 5, 2024*
 
 - Added a "cacherizer" to the virtual meeting collection class.
 
 **1.0.10** *July 5, 2024*
 
 - Added support for accessing the direct URL parser.
 
 **1.0.9** *July 4, 2024*
 
 - Added support for Jitsi Meet.
 
 **1.0.8** *July 4, 2024*
 
 - The factory wasn't generating Google Meet or Discord direct URIs. That's been fixed.
 
 **1.0.7** *June 29, 2024*
 
 - Added support for a direct, tested phone URI.
 
 **1.0.6** *June 29, 2024*
 
 - Fixed documentation typos.
 - I had to make the Zoom URL detector "looser," in order to compensate for spectacularly bad URIs.
 
 **1.0.5** *June 27, 2024*
 
 - The NAWS coordinates were wrong.
 
 **1.0.4** *June 27, 2024*
 
 - Forgot to make the enum Comparable

 **1.0.3** *June 27, 2024*
 
 - Added support for a "sortable" meeting type.

 **1.0.2** *June 24, 2024*
 
 - There was an issue with the callback in the test harness. It should have been called in the main thread, and wasn't. This does not affect the API.
 
 **1.0.1** *June 24, 2024*
 
 - Removed unused function
 
 **1.0.0** *June 23, 2024*

- Initial Release
