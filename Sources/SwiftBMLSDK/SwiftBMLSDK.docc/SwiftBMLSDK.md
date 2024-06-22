# ``SwiftBMLSDK``

A native Swift client SDK for the `LGV_MeetingServer` Web server.

## Overview

Use the SwiftBMLSDK to query instances of the [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) meeting aggregator server.

This service manages structured queries, and allows powerful parsing and filtering of search results.

## Usage

create an instance of ``SwiftBMLSDK_Query``, and use that to query an external [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) server.

The response to the query will be an instance of ``SwiftBMLSDK_Parser``, which can then be used to access, filter and sort the meetings, contained, therein.

## Topics

### Making a Query to the Server

This is the struct that you need to instantiate, in order to execute queries to [the meeting server](https://github.com/LittleGreenViper/LGV_MeetingServer).

- ``SwiftBMLSDK_Query``

### Meeting Server Information Queries

- ``SwiftBMLSDK_Query/serverInfo(completion:)``

- ``SwiftBMLSDK_Query/ServerInfo``

### Meeting Search Queries

- ``SwiftBMLSDK_Query/SearchSpecification``

- ``SwiftBMLSDK_Query/meetingSearch(specification:completion:)``

- ``SwiftBMLSDK_Parser``
