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
