# ``SwiftBMLSDK``

This is a native Swift client SDK for the `LGV_MeetingServer` Web server.

## Overview

Use the SwiftBMLSDK to query instances of the [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) meeting aggregator server.

This service manages structured queries, and allows powerful parsing and filtering of search results.

## Usage

Instantiate an instance of ``SwiftBMLSDK_Query``, and use that to query an external [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) server. The response will be an instance of ``SwiftBMLSDK_Parser``, which can be used to access, filter and sort the response.

## Topics
