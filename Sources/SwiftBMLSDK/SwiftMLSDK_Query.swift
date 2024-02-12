/*
 © Copyright 2024, Little Green Viper Software Development LLC
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

import Foundation

/* ###################################################################################################################################### */
// MARK: - Meeting Search Query And Communication -
/* ###################################################################################################################################### */
/**
 This struct is about generating queries to instances of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer), and returning the parsed results.
 */
public struct SwiftMLSDK_Query {
    /* ################################################# */
    /**
     This is the main directory ("base") URI for the target [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer) instance.
     */
    private var _serverBaseURI: URL?
    
    /* ################################################# */
    /**
     Default initializer.
     
     - parameter serverBaseURI: The URL to the "base (main directory) of an instance of [`LGV_MeetingServer`](https://github.com/LittleGreenViper/LGV_MeetingServer). Optional. Can be omitted.
     */
    init(serverBaseURI inServerBaseURI: URL? = nil) {
        _serverBaseURI = inServerBaseURI
    }
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftMLSDK_Query {
    /* ################################################# */
    /**
     Accessor for the base URI.
     */
    public var serverBaseURI: URL? {
        get { _serverBaseURI }
        set { _serverBaseURI = newValue }
    }
}
