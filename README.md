# ``SwiftBMLSDK``

A native Swift client SDK for the `LGV_MeetingServer` Web server.

## Overview

![Icon](icon.png)

Use the SwiftBMLSDK to query instances of the [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) meeting aggregator server.

This service manages structured queries, and allows powerful parsing and filtering of search results.

## Usage

create an instance of ``SwiftBMLSDK_Query``, and use that to query an external [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) server.

The response to the query will be an instance of ``SwiftBMLSDK_Parser``, which can then be used to access, filter and sort the meetings, contained, therein.

That's just about the only thing that you need to do, as a user of the SDK. It uses completion procs for most of its responses.

## Topics

### Making a Query to the Server

This is the struct that you need to instantiate, in order to execute queries to [the meeting server](https://github.com/LittleGreenViper/LGV_MeetingServer). Everything else comes from that instance.

- ``SwiftBMLSDK_Query``

### Meeting Server Information Queries

This is a query that fetches basic information from the server.

- ``SwiftBMLSDK_Query/serverInfo(completion:)``

- ``SwiftBMLSDK_Query/ServerInfo``

### Meeting Search Queries

This is how you do a meeting search. Create a ``SwiftBMLSDK_Query/SearchSpecification`` instance, and pass that to the ``SwiftBMLSDK_Query/meetingSearch(specification:completion:)`` method.

- ``SwiftBMLSDK_Query/SearchSpecification``

- ``SwiftBMLSDK_Query/meetingSearch(specification:priority:completion:)``

- ``SwiftBMLSDK_Query/meetingSearch(minimumNumberOfResults:specification:priority:completion:)``

- ``SwiftBMLSDK_Parser``

### Useful Classes

You can create an instance of ``SwiftBMLSDK_MeetingLocalTimezoneCollection``, and use that to manage all the meetings (which are represented in the user's local timezone).

- ``SwiftBMLSDK_MeetingLocalTimezoneCollection``

### Useful Extensions

- ``SwiftBMLSDK_Parser/Meeting/directAppURI``

- ``SwiftBMLSDK_MeetingProtocol``

## Dependencies

This SDK depends upon the [PhoneNumberKit](https://github.com/marmelroy/PhoneNumberKit) package, for formatting usable phone numbers from meeting data.

## License

### [MIT License](https://opensource.org/license/mit)

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
