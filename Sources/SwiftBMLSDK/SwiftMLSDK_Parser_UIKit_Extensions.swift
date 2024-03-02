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
import CoreLocation

#if canImport(UIKit)
    import UIKit
#endif

/* ###################################################################################################################################### */
// MARK: - Utility String Extension -
/* ###################################################################################################################################### */
fileprivate extension StringProtocol {
    /* ################################################################## */
    /**
     This simply strips out all non-decimal characters in the string, leaving only valid decimal digits.
     */
    var _decimalOnly: String {
        let decimalDigits = CharacterSet(charactersIn: "0123456789")
        return String(self).filter {
            // The higher-order function stuff will convert each character into an aggregate integer, which then becomes a Unicode scalar. Very primitive, but shouldn't be a problem for us, as we only need a very limited ASCII set.
            guard let cha = UnicodeScalar($0.unicodeScalars.map { $0.value }.reduce(0, +)) else { return false }
            
            return decimalDigits.contains(cha)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Protocol For Special Computed Properties -
/* ###################################################################################################################################### */
/**
 We have special properties that apply only to specific runtime environments.
 */
public protocol SwiftMLSDK_Meeting {
    /* ################################################# */
    /**
     If the URL for the virtual meeting is one that can open an app on the user's device, a direct URL scheme version of the URL is returned.
     */
    var directAppURI: URL? { get }
}

/* ###################################################################################################################################### */
// MARK: - UIKit Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension uses UIKit to determine the proper app for app-specific URIs.
 */
extension SwiftMLSDK_Parser.Meeting: SwiftMLSDK_Meeting {
    /* ################################################################################################################################## */
    // MARK: - Enum For Virtual Direct URLs -
    /* ################################################################################################################################## */
    /**
     This enum helps us to create direct (as in opening the app directly) URLs, for various services.
     */
    enum DirectVirtual: CaseIterable {
        /* ############################################# */
        /**
         The Zoom app.
         */
        case zoom(_: URL? = nil)
        
        /* ############################################# */
        /**
         Verizon BlueJeans
         */
        case bluejeans(_: URL? = nil)
        
        /* ############################################# */
        /**
         GoToMeeting
         */
        case gotomeeting(_: URL? = nil)
        
        /* ############################################# */
        /**
         Microsoft Skype
         */
        case skype(_: URL? = nil)
        
        /* ############################################# */
        /**
         Google Meet
         */
        case meet(_: URL? = nil)

        /* ############################################# */
        /**
         CaseIterable Conformance
         */
        static var allCases: [SwiftMLSDK_Parser.Meeting.DirectVirtual] { [.zoom(nil), .bluejeans(nil), .gotomeeting(nil), .skype(nil), .meet(nil)] }
        
        /* ############################################# */
        /**
         This returns the protocol for the given service.
         */
        private var _serviceProtocol: String {
            switch self {
            case .zoom:
                return "zoomus"
                
            case .bluejeans:
                return "bjn"

            case .gotomeeting:
                return "lmi-g2m"

            case .skype:
                return "skype"

            case .meet:
                return "gmeet"
            }
        }
        
        /* ############################################# */
        /**
         This returns the host for the given service.
         */
        private var _serviceURLHost: String {
            switch self {
            case .zoom:
                return "zoom.us"
                
            case .bluejeans:
                return "bluejeans.com"

            case .gotomeeting:
                return "gotomeeting.com"

            case .skype:
                return "skype.com"

            case .meet:
                return "meet.google.com"
            }
        }

        /* ############################################# */
        /**
         This returns a localization token for the app name.
         */
        var appName: String {
            switch self {
            case .zoom:
                return "SLUG-DIRECT-URI-ZOOM"
                
            case .bluejeans:
                return "SLUG-DIRECT-URI-BLUEJEANS"

            case .gotomeeting:
                return "SLUG-DIRECT-URI-GOTOMEETING"

            case .skype:
                return "SLUG-DIRECT-URI-SKYPE"

            case .meet:
                return "SLUG-DIRECT-URI-MEET"
            }
        }

        /* ############################################# */
        /**
         This returns a URL to open the relevant app for the URI.
         
         If the app is not installed on the phone, then nil is returned.
         */
        var directURL: URL? {
            var ret: URL?
            var confNum: String = ""
            
            switch self {
            case .zoom(let inURL):
                guard let query = inURL?.query,
                      !query.isEmpty else { return nil }
                
                let pwd = query.split(separator: "&").reduce("") { (current, next) in
                    if current.isEmpty,
                       next.starts(with: "pwd=") {
                        return String(next[next.index(next.startIndex, offsetBy: 4)...])
                    }
                    
                    return ""
                }
                
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                // Primitive, but it will work. It gets an element that has a run of more than eight positive numeric characters, and assumes that is the conference code.
                // The conference code should come before the password (which might also be a string of numbers).
                // This cleans out query strings.
                let numStringArray: [String] = comp.compactMap {
                    let str = String($0._decimalOnly)
                    
                    return str.isEmpty ? nil : str
                }
                
                for elem in numStringArray where 8 < elem.count {
                    confNum = elem
                    break
                }

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/join?confno=\(confNum)" + (!pwd.isEmpty ? "&pwd=\(pwd)" : "")

                ret = URL(string: retString)
                
            case .bluejeans(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                let numStringArray: [String] = comp.compactMap {
                    let str = String($0._decimalOnly)
                    
                    return str.isEmpty ? nil : str
                }
                
                for elem in numStringArray where 8 < elem.count {
                    confNum = elem
                    break
                }

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/\(confNum)"

                ret = URL(string: retString)

            case .gotomeeting(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                let numStringArray: [String] = comp.compactMap {
                    let str = String($0._decimalOnly)
                    
                    return str.isEmpty ? nil : str
                }
                
                for elem in numStringArray where 8 < elem.count {
                    confNum = elem
                    break
                }

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/join/\(confNum)"

                ret = URL(string: retString)

            case .skype(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                confNum = comp[0]

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/\(confNum)"

                ret = URL(string: retString)

            case .meet(let inURL):
                guard let comp = inURL?.pathComponents,
                      !comp.isEmpty else { return nil }
                
                confNum = comp[0]

                guard !confNum.isEmpty else { return nil }
                
                let retString = "\(_serviceProtocol)://\(_serviceURLHost)/\(confNum)"

                ret = URL(string: retString)
            }
            
            #if canImport(UIKit)
                guard let ret = ret,
                      UIApplication.shared.canOpenURL(ret)
                else { return nil }
            #endif
            
            return ret
        }
        
        /* ############################################# */
        /**
         This is a factory function that returns the appropriate enum case. It returns nil, if none are available.
         
         - parameter url: The URL to check.
         - returns: The enum case ( or nil, if none).
         */
        static func factory(url inURL: URL) -> DirectVirtual? {
            var ret: DirectVirtual?
            
            if inURL.host?.contains(DirectVirtual.zoom(nil)._serviceURLHost) ?? false {
                ret = DirectVirtual.zoom(inURL)
            } else if inURL.host?.contains(DirectVirtual.bluejeans(nil)._serviceURLHost) ?? false {
                ret = DirectVirtual.bluejeans(inURL)
            } else if inURL.host?.contains(DirectVirtual.gotomeeting(nil)._serviceURLHost) ?? false {
                ret = DirectVirtual.gotomeeting(inURL)
            } else if inURL.host?.contains(DirectVirtual.skype(nil)._serviceURLHost) ?? false {
                ret = DirectVirtual.skype(inURL)
            }
            
            return nil != ret?.directURL ? ret : nil
        }
    }
    
    /* ################################################# */
    /**
     If the URL for the virtual meeting is one that can open an app on the user's device, a direct URL scheme version of the URL is returned.
     */
    public var directAppURI: URL? {
        guard let virtualURL = virtualURL,
              "https" == virtualURL.scheme
        else { return nil }
        
        return DirectVirtual.factory(url: virtualURL)?.directURL
    }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension, for Arrays of meetings -
/* ###################################################################################################################################### */
public extension Array where Element==SwiftMLSDK_Parser.Meeting {
    /* ################################################# */
    /**
     This returns all of the in-person meeting coordinates in an array.
     */
    var allCoords: [CLLocationCoordinate2D] {
        compactMap { $0.coords }
    }
}
