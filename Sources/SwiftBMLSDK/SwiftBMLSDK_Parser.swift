/*
 © Copyright 2024 - 2026, Little Green Viper Software Development LLC
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
import CoreLocation         // For coordinates
import Contacts             // For the in-person address
import MapKit               // For the Array extension that returns location data for meetings.
#if !SWIFTBMLSDK_DOCS && canImport(PhoneNumberKit)
    import PhoneNumberKit   // For parsing phone numbers.

    /* ###################################################################################################################################### */
    // MARK: - Meeting Extensions -
    /* ###################################################################################################################################### */
    /**
     This extension adds proper phone number parsing.
     */
    private extension SwiftBMLSDK_Parser.Meeting {
        /* ################################################################## */
        /**
         Attempts to synthesize a best-effort `tel:` URL from a raw virtual meeting
         phone string.

         This is intended for dial-in meeting strings that may contain:

         - A plain phone number
         - An international number
         - A phone number plus meeting ID / PIN / passcode
         - An existing `tel:` URL
         - Descriptive text such as city names or country labels

         The function extracts one primary dial-in number, validates and normalizes it
         with `PhoneNumberUtility`, then appends any discovered post-dial DTMF content.

         Ambiguous strings containing multiple distinct plausible phone numbers return `nil`.

         - parameter inRawValue: The raw meeting phone string.
         - parameter inDefaultRegion: The region used for non-international numbers.
           Default is `"US"`.
         - returns: A synthesized `tel:` URL, or `nil`.
         */
        private static func _dialInURL(from inRawValue: String,
                                      defaultRegion inDefaultRegion: String = "US") -> URL? {
            let source = _normalizeDialInSource(inRawValue.removingPercentEncoding ?? inRawValue)
            guard !source.isEmpty else { return nil }

            let phoneUtility = PhoneNumberUtility()

            let strippedSource: String = {
                let lower = source.lowercased()

                if lower.hasPrefix("tel://") {
                    return String(source.dropFirst(6))
                } else if lower.hasPrefix("tel:") {
                    return String(source.dropFirst(4))
                }

                return source
            }()

            let candidates = _mainPhoneCandidates(in: strippedSource,
                                                  phoneUtility: phoneUtility,
                                                  defaultRegion: inDefaultRegion)

            let distinctCandidates = Array(Set(candidates.map(\.normalizedNumber)))
            guard 1 == distinctCandidates.count,
                  let mainMatch = candidates.first
            else { return nil }

            var postDial = ""

            let tail = String(strippedSource[mainMatch.range.upperBound...])
            postDial += _extractExplicitPostDial(from: tail)

            let labeledPostDial = _extractLabeledPostDial(from: strippedSource,
                                                          excluding: mainMatch.range)
            if !labeledPostDial.isEmpty {
                let normalizedExisting = _normalizedDialPayload(postDial)
                let normalizedLabeled = _normalizedDialPayload(labeledPostDial)

                if !normalizedExisting.contains(normalizedLabeled) {
                    postDial += labeledPostDial
                }
            }

            let telBody = _percentEncodeTelBody(mainMatch.normalizedNumber + postDial)
            return URL(string: "tel:\(telBody)")
        }

        /* ################################################################################################################################## */
        // MARK: - Private Types -
        /* ################################################################################################################################## */

        private struct _MainPhoneMatch {
            let normalizedNumber: String
            let range: Range<String.Index>
        }

        /* ################################################################################################################################## */
        // MARK: - Private Helpers -
        /* ################################################################################################################################## */

        /* ################################################################## */
        /**
         Normalizes the source string.
         */
        private static func _normalizeDialInSource(_ inSource: String) -> String {
            inSource
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                .replacingOccurrences(of: "\u{202F}", with: " ")
                .replacingOccurrences(of: "\u{2007}", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "—", with: "-")
                .replacingOccurrences(of: "–", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        /* ################################################################## */
        /**
         Returns plausible primary phone-number candidates in order of appearance.
         */
        private static func _mainPhoneCandidates(in inSource: String,
                                                 phoneUtility inPhoneUtility: PhoneNumberUtility,
                                                 defaultRegion inDefaultRegion: String) -> [_MainPhoneMatch] {
            let pattern = #"""
            (?x)
            (?:
                \+?\d[\d\(\)\.\-\s]{6,}\d
            )
            """#

            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

            let nsRange = NSRange(inSource.startIndex..<inSource.endIndex, in: inSource)
            let matches = regex.matches(in: inSource, options: [], range: nsRange)

            var results: [_MainPhoneMatch] = []
            var seen = Set<String>()

            for match in matches {
                guard let range = Range(match.range, in: inSource) else { continue }

                let rawCandidate = String(inSource[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !_isClearlyLabeledAsCode(in: inSource, matchRange: range) else { continue }

                do {
                    let parsed = try inPhoneUtility.parse(rawCandidate,
                                                          withRegion: inDefaultRegion,
                                                          ignoreType: true)
                    let normalized = inPhoneUtility.format(parsed, toType: .e164)
                    guard !seen.contains(normalized) else { continue }

                    seen.insert(normalized)
                    results.append(.init(normalizedNumber: normalized, range: range))
                } catch {
                    continue
                }
            }

            return results
        }

        /* ################################################################## */
        /**
         Returns `true` if a candidate appears to be a meeting code rather than a phone number.
         */
        private static func _isClearlyLabeledAsCode(in inSource: String,
                                                    matchRange inMatchRange: Range<String.Index>) -> Bool {
            let prefix = String(inSource[..<inMatchRange.lowerBound])
            let pattern = #"(?i)(?:\b(?:meeting\s*id|id|password|passcode|pass|pin|code)\s*[:#-]?\s*|[,;#*]\s*)$"#
            return prefix.range(of: pattern, options: .regularExpression) != nil
        }

        /* ################################################################## */
        /**
         Extracts explicit post-dial content that immediately follows the main number.
         */
        private static func _extractExplicitPostDial(from inTail: String) -> String {
            guard !inTail.isEmpty else { return "" }

            var index = inTail.startIndex

            while index < inTail.endIndex, inTail[index].isWhitespace {
                index = inTail.index(after: index)
            }

            guard index < inTail.endIndex,
                  "," == inTail[index] || ";" == inTail[index]
            else { return "" }

            var result = ""

            while index < inTail.endIndex {
                let char = inTail[index]

                if char.isWhitespace {
                    index = inTail.index(after: index)
                    continue
                }

                if char.isNumber || "," == char || ";" == char || "#" == char || "*" == char {
                    result.append(char)
                    index = inTail.index(after: index)
                } else {
                    break
                }
            }

            return result
        }

        /* ################################################################## */
        /**
         Extracts labeled DTMF payloads such as meeting IDs, PINs, and passcodes.
         */
        private static func _extractLabeledPostDial(from inSource: String,
                                                    excluding inExcludedRange: Range<String.Index>) -> String {
            let pattern = #"(?i)\b(meeting\s*id|id|pin|passcode|password|pass|code)\b\s*[:#-]?\s*([0-9](?:[0-9\s-]*[0-9])?)\s*(#)?"#

            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return "" }

            let nsRange = NSRange(inSource.startIndex..<inSource.endIndex, in: inSource)
            let matches = regex.matches(in: inSource, options: [], range: nsRange)

            var segments: [String] = []

            for match in matches {
                guard 3 <= match.numberOfRanges,
                      let wholeRange = Range(match.range(at: 0), in: inSource),
                      let valueRange = Range(match.range(at: 2), in: inSource)
                else { continue }

                guard !wholeRange.overlaps(inExcludedRange) else { continue }

                let digits = inSource[valueRange].filter(\.isNumber)
                guard !digits.isEmpty else { continue }

                segments.append(",,\(digits)#")
            }

            return segments.joined()
        }

        /* ################################################################## */
        /**
         Returns a normalized payload for deduplication comparisons.
         */
        private static func _normalizedDialPayload(_ inPayload: String) -> String {
            inPayload.filter { $0.isNumber || "," == $0 || ";" == $0 || "#" == $0 || "*" == $0 }
        }

        /* ################################################################## */
        /**
         Percent-encodes the body of a `tel:` URL.
         */
        private static func _percentEncodeTelBody(_ inBody: String) -> String {
            var allowed = CharacterSet.decimalDigits
            allowed.insert(charactersIn: "+,;*")

            return inBody.addingPercentEncoding(withAllowedCharacters: allowed) ?? inBody
        }
    }
#else
    private extension SwiftBMLSDK_Parser.Meeting { private static func _dialInURL(from: String, defaultRegion: String = "US") -> URL? { nil } }
#endif

/* ###################################################################################################################################### */
// MARK: - Meeting Text Decoding -
/* ###################################################################################################################################### */
fileprivate extension String {
    /* ################################################################## */
    /**
     Removes up to two layers of percent encoding, retaining the last valid text.
     */
    var _decodedMeetingText: String {
        let once = removingPercentEncoding ?? self
        return once.removingPercentEncoding ?? once
    }
}

/* ###################################################################################################################################### */
// MARK: - Calendar Extension -
/* ###################################################################################################################################### */
fileprivate extension Calendar {
    /* ################################################################## */
    /**
     Converts 1...7 where 1 = Sunday into 0...6 where 0 = this calendar's firstWeekday.
     - parameter inWeekdayIndex: 1 is Sunday weekday index.
     - returns: localized weekday strings ordered in this calendar's preferred week-start order.
     */
    func _userWeekStartIndex(fromSundayBasedWeekday inWeekdayIndex: Int) -> Int {
        precondition((1...7).contains(inWeekdayIndex))
        return (inWeekdayIndex - firstWeekday + 7) % 7
    }
    
    /* ################################################################## */
    /**
     Internal tool to return the basic symbol set for localization.
     - parameter inStyle: The style for the emitted string.
     - returns: localized weekday strings ordered in this calendar's preferred week-start order.
     */
    func _localizedWeekdaySymbols(style inStyle: WeekdayStyle = .full) -> [String] {
        let base: [String]
        switch inStyle {
        case .full:
            base = weekdaySymbols
        case .short:
            base = shortWeekdaySymbols
        case .veryShort:
            base = veryShortWeekdaySymbols
        case .standaloneFull:
            base = standaloneWeekdaySymbols
        case .standaloneShort:
            base = shortStandaloneWeekdaySymbols
        case .standaloneVeryShort:
            base = veryShortStandaloneWeekdaySymbols
        }
        
        let start = firstWeekday - 1   // convert 1...7 to 0...6
        return Array(base[start...] + base[..<start])
    }
    
    /* ################################################################## */
    /**
     Converts a weekday index into a localized string.
     - parameter inWeekdayIndex: 1 is Sunday weekday index.
     - parameter inStyle: The style for the emitted string.
     - returns: the localized weekday string for a Sunday-based 1...7 input.
     */
    func _localizedWeekdayString(
        fromSundayBasedWeekday inWeekdayIndex: Int,
        style inStyle: WeekdayStyle = .full
    ) -> String {
        let index = _userWeekStartIndex(fromSundayBasedWeekday: inWeekdayIndex)
        return _localizedWeekdaySymbols(style: inStyle)[index]
    }
}

/* ###################################################################################################################################### */
// MARK: - Calendar Extension Extension -
/* ###################################################################################################################################### */
public extension Calendar {
    /* ################################################################## */
    /**
     The style to use for display of localized weekday/time.
     */
    enum WeekdayStyle {
        /* ############################################################## */
        /**
         The full weekday name used within a date.
         */
        case full

        /* ############################################################## */
        /**
         The abbreviated weekday name used within a date.
         */
        case short

        /* ############################################################## */
        /**
         The shortest weekday name used within a date.
         */
        case veryShort

        /* ############################################################## */
        /**
         The full weekday name for a stand-alone label.
         */
        case standaloneFull

        /* ############################################################## */
        /**
         The abbreviated weekday name for a stand-alone label.
         */
        case standaloneShort

        /* ############################################################## */
        /**
         The shortest weekday name for a stand-alone label.
         */
        case standaloneVeryShort
    }
}

/* ###################################################################################################################################### */
// MARK: - CoreLocation Extension -
/* ###################################################################################################################################### */
/**
 These are some useful Core Location tools.
 */
fileprivate extension CLLocationCoordinate2D {
    /* ################################################################## */
    /**
     - parameter inComp: A location (long and lat), to which we are comparing ourselves.
     - parameter precisionInMeters: This is an optional precision (slop area), in meters. If left out, then the match must be exact.
     
     - returns: True, if the locations are equal, according to the given precision.
     */
    func _isEqualTo(_ inComp: CLLocationCoordinate2D, precisionInMeters inPrecisionInMeters: CLLocationDistance = 0.0) -> Bool { CLLocation(latitude: latitude, longitude: longitude).distance(from: CLLocation(latitude: inComp.latitude, longitude: inComp.longitude)) <= inPrecisionInMeters }
}

/* ###################################################################################################################################### */
// MARK: - Meeting JSON Page Parser -
/* ###################################################################################################################################### */
/**
 This struct will contain one page of results from a meeting search, and is one of the response parameters to the ``SwiftBMLSDK_Query/QueryResultCompletion`` completion callback.
 
 The parser preserves server order while skipping invalid meeting records and applying the
 requested meeting type. Meeting IDs take precedence over the type filter. A valid empty or
 count-only response produces an empty ``meetings`` array.

 ``meta`` preserves the server's counts; ``meetings`` contains only records accepted by the
 parser, so their counts may differ. Each ``Meeting`` is a class with immutable stored data.
 Encoding a parser or its meetings produces the SDK's export schema, not the server's input schema.
 
 The parser then automatically populates a ``meta`` instance, that reports the page metadata from the server, and a ``meetings`` array, of all meeting instances, and some functional interfaces.
 
 # Supported Systems
 
 Supports iOS/iPadOS 16+, macOS 13+, and watchOS 9+. tvOS is unsupported because the public meeting address uses the Contacts framework, which is unavailable there.
 
 Normal builds require Swift tools 5.9 or greater through the PhoneNumberKit 5 dependency. The SDK uses Swift 5 language mode.
 
 # Usage
 
 Do not instantiate this type. That's handled by a ``SwiftBMLSDK_Query`` instance that performs a search, and returns an instance of this struct.
 
 # Dependencies
 
 This parser uses Apple's Foundation, CoreLocation, Contacts, and MapKit frameworks, and PhoneNumberKit 5 for dial-in numbers.
 */
public struct SwiftBMLSDK_Parser: Encodable {
    // MARK: - Internal Private Functionality -

    /* ################################################# */
    /**
     This parses the page metadata from the raw dictionary.
     
     - parameter inDictionary: The partly-parsed raw JSON
     */
    private static func _parseMeta(_ inDictionary: [String: Any]) -> PageMeta? {
        // Older server versions use only { "total": 0 } for an empty search.
        if inDictionary.count == 1, let total = inDictionary["total"] as? Int, total == 0 {
            return PageMeta()
        }
        guard let actualSize = inDictionary["actual_size"] as? Int,
              let pageSize = inDictionary["page_size"] as? Int,
              let startingIndex = inDictionary["starting_index"] as? Int,
              let total = inDictionary["total"] as? Int,
              let totalPages = inDictionary["total_pages"] as? Int,
              let page = inDictionary["page"] as? Int,
              let searchTime = inDictionary["search_time"] as? TimeInterval
        else { return nil }
        
        return PageMeta(actualSize: actualSize,
                        pageSize: pageSize,
                        startingIndex: startingIndex,
                        total: total,
                        totalPages: totalPages,
                        page: page,
                        searchTime: searchTime
        )
    }

    // MARK: Internal Initializer
    
    /* ################################################# */
    /**
     This is a failable initializer. It parses the JSON data.
     
     - parameter inJSONData: Raw server JSON, including metadata and a meeting array.
     - parameter inSpecification: The request whose type and geographic center apply to these records.
     */
    internal init?(jsonData inJSONData: Data, specification inSpecification: SwiftBMLSDK_Query.SearchSpecification) {
        guard let simpleJSON = try? JSONSerialization.jsonObject(with: inJSONData, options: [.allowFragments]) as? NSDictionary,
              let metaJSON = simpleJSON["meta"] as? [String: Any],
              let meta = Self._parseMeta(metaJSON),
              let meetingsJSON = simpleJSON["meetings"] as? [[String: Any]]
        else { return nil }
        let searchCenter = inSpecification.urlQueryItems.contains { $0.name == "geo_radius" }
            ? inSpecification.locationCenter : nil
        self.meta = meta
        self.meetings = meetingsJSON.compactMap {
            let ret = Meeting($0, searchCenter: searchCenter)
            guard inSpecification.meetingIDs.isEmpty else { return ret }
            switch inSpecification.type {
            case .any:
                return ret
                
            case .hybrid:
                return .hybrid == ret?.meetingType && (!(ret?.inPersonVenueName ?? "").isEmpty || !(ret?.inPersonAddress?.street ?? "").isEmpty) ? ret : nil
                
            case .virtual(let isExclusive):
                return .virtual == ret?.meetingType || (!isExclusive && .hybrid == ret?.meetingType) ? ret : nil
                
            case .inPerson(let isExclusive):
                return (.inPerson == ret?.meetingType || (!isExclusive && .hybrid == ret?.meetingType)) ? ret : nil
            }
        }
    }

    // MARK: -
    // MARK: - Exported Public Interface -

    // MARK: - Public Data Types and Enums -
    
    /* ################################################################################################################################## */
    // MARK: Page Metadata Container
    /* ################################################################################################################################## */
    /**
     This struct holds metadata about the page of meeting results, as reported by the server.
     */
    public struct PageMeta: Encodable {
        /* ############################################# */
        /**
         Default Initializer (internal).
         
         - parameters:
             - actualSize: This is the actual size of this single page of results, in results (not bytes).
             - pageSize: This is the number of results allowed as a maximum, per page, in results.
             - startingIndex: This is the 0-based starting index, of the total found set (in results), for this page.
             - total: This is the total size of all results in the found set.
             - totalPages: This is the total number of pages that contain the found set.
             - page: This is the 0-based index of this page of results.
             - searchTime: This is the number of seconds, reported by the server, to generate this page of results.
         */
        internal init(actualSize inActualSize: Int = 0,
                    pageSize inPageSize: Int = 0,
                    startingIndex inStartingIndex: Int = 0,
                    total inTotal: Int = 0,
                    totalPages inTotalPages: Int = 0,
                    page inPage: Int = 0,
                    searchTime inSearchTime: TimeInterval = 0
        ) {
            actualSize = inActualSize
            pageSize = inPageSize
            startingIndex = inStartingIndex
            total = inTotal
            totalPages = inTotalPages
            page = inPage
            searchTime = inSearchTime
        }

        // MARK: - Exported Public Interface -

        /* ############################################# */
        /**
         This is the actual size of this single page of results, in results (not bytes).
         */
        public let actualSize: Int

        /* ############################################# */
        /**
         This is the number of results allowed as a maximum, per page, in results.
         */
        public let pageSize: Int

        /* ############################################# */
        /**
         This is the 0-based starting index, of the total found set (in results), for this page.
         */
        public let startingIndex: Int

        /* ############################################# */
        /**
         This is the total size of all results in the found set.
         */
        public let total: Int

        /* ############################################# */
        /**
         This is the total number of pages that contain the found set.
         */
        public let totalPages: Int

        /* ############################################# */
        /**
         This is the 0-based index of this page of results.
         */
        public let page: Int

        /* ############################################# */
        /**
         This is the number of seconds, reported by the server, to generate this page of results.
         */
        public let searchTime: TimeInterval
    }

    /* ################################################################################################################################## */
    // MARK: Meeting Data Container
    /* ################################################################################################################################## */
    /**
     A weekly meeting with a venue, a virtual URL, a dial-in number, or a combination of these.

     ``weekday`` and ``startTime`` describe the schedule in ``timeZone``. Use
     ``nextOccurrenceDateFast(from:calendar:)`` for an absolute date suitable for display or comparison.
     Equality and hashing use ``id``. Ordering uses the next absolute occurrence, then meeting type,
     name, and ID; records with the same ID compare equal.

     The parser requires a valid weekday, clock time, representable IDs, and usable meeting details.
     Records with a missing or invalid timezone are skipped by default. Setting the process environment
     variable `IGNORE_NO_TZ` accepts those records using the device's current timezone instead.
     
     > NOTE: There is a platform-dependent extension that adds the ``SwiftBMLSDK_Parser/Meeting/directAppURI`` computed property to this type.
     
     > NOTE: This is a class, as opposed to a struct, in order to reduce the memory and performance overhead of using this.
     */
    public class Meeting: Comparable, Identifiable {
        // MARK: Comparable Conformance
        /* ############################################# */
        /**
         - parameter lhs: The left-hand side of the comparison.
         - parameter rhs: The right-hand side of the comparison.
         
         - returns: True if lhs sorts before rhs by next occurrence, type, name, and ID.
         */
        public static func < (lhs: SwiftBMLSDK_Parser.Meeting, rhs: SwiftBMLSDK_Parser.Meeting) -> Bool {
            guard lhs.id != rhs.id else { return false }
            let now = Date()
            let leftDate = lhs.nextOccurrenceDateFast(from: now)
            let rightDate = rhs.nextOccurrenceDateFast(from: now)
            if leftDate != rightDate { return leftDate < rightDate }
            if lhs.sortableMeetingType != rhs.sortableMeetingType { return lhs.sortableMeetingType < rhs.sortableMeetingType }
            if lhs.name != rhs.name { return lhs.name < rhs.name }
            return lhs.id < rhs.id
        }
        

        /* ############################################################################################################################## */
        // MARK: Format Information Container
        /* ############################################################################################################################## */
        /**
         This struct holds a parsed format information instance.
         */
        public struct Format: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Comparable {
            /* ############################################# */
            /**
             Default initializer
             
             - parameters:
                - key: The format key
                - name: The short format name
                - description: The longer format description
                - language: The language code.
             */
            internal init(key inKey: String, name inName: String, description inDescription: String, language inLanguage: String, id inID: String) {
                key = inKey._decodedMeetingText  // Twice, because there may be icky data.
                name = inName._decodedMeetingText
                description = inDescription._decodedMeetingText
                language = inLanguage._decodedMeetingText
                id = inID._decodedMeetingText
            }

            /* ############################################# */
            /**
             Parses raw format data, substituting empty text or ID 0 for missing fields.
             
             - parameter inDictionary: A simple String-keyed dictionary of partly-parsed values.
             */
            internal init(_ inDictionary: [String: Any]) {
                self.init(key: (inDictionary["key"] as? String) ?? "", name: (inDictionary["name"] as? String) ?? "", description: (inDictionary["description"] as? String) ?? "", language: (inDictionary["language"] as? String) ?? "", id: String((inDictionary["id"] as? Int) ?? 0))
            }

            // MARK: Public Instance Properties
            
            /* ############################################# */
            /**
             This is the short format "key" string.
             */
            public let key: String

            /* ############################################# */
            /**
             This is the short name for the format.
             */
            public let name: String

            /* ############################################# */
            /**
             This is the longer description of the format.
             */
            public let description: String
            
            /* ############################################# */
            /**
             The server-supplied language code for the name and description (for example, `en`).
             */
            public let language: String

            /* ############################################# */
            /**
             This is the local server format ID.
             */
            public let id: String

            // MARK: Public Computed Properties
            
            /* ############################################# */
            /**
             Returns the format name followed by its description in parentheses: `Name (Description)`.
             */
            public var asString: String { "\(name) (\(description))" }
            
            // MARK: Comparable Conformance
            
            /* ############################################# */
            /**
             We simply sort by key, so there's consistency in the ordering.
             
             - parameter lhs: The left-hand side of the comparison.
             - parameter rhs: The right-hand side of the comparison.
             
             - returns: True if the left format key sorts before the right format key.
             */
            public static func < (lhs: Format, rhs: Format) -> Bool { lhs.key < rhs.key }
            
            // MARK: CustomDebugStringConvertible Conformance
            
            /* ############################################# */
            /**
             Returns a simple textual description of the data.
             */
            public var debugDescription: String { "\t\t(\(key))\t\(name)\t(\(language))\n\t\t\t\t\(description)\n\t\t\t\t\(id)" }
        }
        
        /* ################################################################## */
        /**
         Parses an HH:mm or HH:mm:ss wall-clock value on January 1, 2001, in GMT.
         */
        private static func _floatingTimeDate(from inString: String) -> Date? {
            let fields = inString.split(separator: ":", omittingEmptySubsequences: false)
            guard (2...3).contains(fields.count),
                  fields.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
                  let hour = Int(fields[0]), let minute = Int(fields[1]),
                  let second = fields.count == 3 ? Int(fields[2]) : 0 else { return nil }

            guard (0..<24).contains(hour),
                  (0..<60).contains(minute),
                  (0..<60).contains(second)
            else { return nil }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.year = 2001
            components.month = 1
            components.day = 1
            components.hour = hour
            components.minute = minute
            components.second = second

            return calendar.date(from: components)
        }

        // MARK: Internal Initializer
                
        /* ################################################# */
        /**
         This is a failable initializer, it parses an input dictionary.
         
         - parameter inDictionary: The semi-parsed JSON record for the meeting.
         - parameter searchCenter: The center for a distance search. Nil, if not a distance search.
         */
        internal init?(_ inDictionary: [String: Any], searchCenter inSearchCenter: CLLocationCoordinate2D?) {
            /* ########################################### */
            /**
             "Cleans" a URI.
             
             - parameter urlString: The URL, as a String. It can be optional.
             
             - returns: an optional String. This is the given URI, "cleaned up" ("https://" or "tel:" may be prefixed)
             */
            func cleanURI(urlString inURLString: String?) -> String? {
                guard var value = inURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !value.isEmpty else { return nil }
                if value.lowercased().hasPrefix("tel://") {
                    value = "tel:" + value.dropFirst(6)
                } else if value.lowercased().hasPrefix("http://") {
                    value = "https://" + value.dropFirst(7)
                } else if !value.lowercased().hasPrefix("https://"), !value.lowercased().hasPrefix("tel:") {
                    value = "https://" + value
                }
                guard let url = URL(string: value),
                      url.scheme?.lowercased() == "tel" || !(url.host ?? "").isEmpty else { return nil }
                return url.absoluteString
            }

            guard let serverID = inDictionary["server_id"] as? Int,
                  (0...0xFFFFF).contains(serverID),
                  let startTimeStr = inDictionary["start_time"] as? String,
                  let startTime = Self._floatingTimeDate(from: startTimeStr),
                  let localMeetingID = inDictionary["meeting_id"] as? Int,
                  localMeetingID >= 0, UInt64(localMeetingID) <= 0xFFFFFFFFFFF,
                  let weekday = inDictionary["weekday"] as? Int,
                  (1..<8).contains(weekday),
                  let organizationStr = inDictionary["organization_key"] as? String
            else { return nil }

            self.weekday = weekday
            self.startTime = startTime
            self.serverID = serverID
            self.localMeetingID = localMeetingID
            self.organization = Organization(rawValue: organizationStr) ?? .none
            
            let durationTemp = inDictionary["duration"] as? Int ?? 3600 // One hour default.
            self.duration = (0..<86400).contains(durationTemp) ? TimeInterval(durationTemp) : TimeInterval(3600)    // Can't be greater than 24 hours.

            self.formats = (inDictionary["formats"] as? [[String: Any]] ?? []).compactMap { Format($0) }.sorted()

            self.name = ((inDictionary["name"] as? String)?._decodedMeetingText ?? "")

            var fixedCoords = CLLocationCoordinate2D()
            
            var coords: CLLocationCoordinate2D?
            
            if let long = inDictionary["longitude"] as? Double,
               let lat = inDictionary["latitude"] as? Double,
               CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                fixedCoords = CLLocationCoordinate2D(latitude: lat, longitude: long)
                coords = fixedCoords
            }

            if let timezoneStr = inDictionary["time_zone"] as? String,
               let tz = TimeZone(identifier: timezoneStr) {
                self.timeZone = tz
            } else if nil == getenv("IGNORE_NO_TZ") {
                return nil  // Zero-tolerance for no timezone.
            } else {
                self.timeZone = .current
            }

            if let comments = (inDictionary["comments"] as? String)?._decodedMeetingText,  // Twice, because sometimes, there may be two levels of bad data.
               !comments.isEmpty {
                self.comments = comments
            } else {
                self.comments = nil
            }

            if let physicalAddress = inDictionary["physical_address"] as? [String: String],
               !((physicalAddress["street"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? "").isEmpty,
               !fixedCoords._isEqualTo(CLLocationCoordinate2D(latitude: 34.23596, longitude: -118.56352), precisionInMeters: 200) { // Since the NAWS office is the default BMLT physical location, we make sure that it is not the specified long/lat.
                let mutableGoPostal = CNMutablePostalAddress()
                mutableGoPostal.street = (physicalAddress["street"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.subLocality = (physicalAddress["neighborhood"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.city = (physicalAddress["city"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.state = (physicalAddress["province"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.subAdministrativeArea = (physicalAddress["county"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.postalCode = (physicalAddress["postal_code"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                mutableGoPostal.country = (physicalAddress["nation"]?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                self.inPersonAddress = mutableGoPostal
                let locationInfo = (physicalAddress["info"]?._decodedMeetingText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                self.locationInfo = locationInfo.isEmpty ? nil : locationInfo
                let inPersonVenueName = physicalAddress["name"]?._decodedMeetingText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.inPersonVenueName = inPersonVenueName.isEmpty ? nil : inPersonVenueName
            } else {
                coords = nil
                self.inPersonAddress = nil
                self.locationInfo = nil
                self.inPersonVenueName = nil
            }

            if let virtualMeetingInfo = inDictionary["virtual_information"] as? [String: String] {
                var splitsville = (virtualMeetingInfo["url"] ?? "").split(separator: "#@-@#")
                var splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let urlStr = cleanURI(urlString: splitString) ?? ""
                if !urlStr.isEmpty,
                   let virtualURL = URL(string: urlStr) {
                    self.virtualURL = virtualURL
                } else {
                    self.virtualURL = nil
                }
                
                splitsville = (virtualMeetingInfo["phone_number"] ?? "").split(separator: "#@-@#")
                splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let virtualPhoneNumber = splitString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !virtualPhoneNumber.isEmpty {
                    self.virtualPhoneNumber = virtualPhoneNumber
                } else {
                    self.virtualPhoneNumber = nil
                }
                
                splitsville = (virtualMeetingInfo["info"] ?? "").split(separator: "#@-@#")
                splitString = 1 < splitsville.count ? String(splitsville[1]) : !splitsville.isEmpty ? String(splitsville[0]) : ""
                let virtualInfo = splitString._decodedMeetingText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.virtualInfo = virtualInfo.isEmpty ? nil : virtualInfo
            } else {
                self.virtualURL = nil
                self.virtualPhoneNumber = nil
                self.virtualInfo = nil
            }
            
            if (inPersonAddress?.street ?? "").isEmpty,
               (inPersonVenueName ?? "").isEmpty,
               nil == virtualURL,
               (virtualPhoneNumber ?? "").isEmpty {
                return nil
            }
            
            self.coords = coords
            
            if let searchCenter = inSearchCenter,
               let coords = coords,
               CLLocationCoordinate2DIsValid(coords),
               CLLocationCoordinate2DIsValid(searchCenter) {
                let myLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
                let compLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
                self.distanceInMeters = myLocation.distance(from: compLocation)
            } else {
                self.distanceInMeters = -1
            }
        }

        // MARK: Public Interface
        
        /* ################################################# */
        /**
         This is how many seconds there are, in a week.
         */
        public static let oneWeekInSeconds = TimeInterval(604800)

        /* ############################################################################################################################## */
        // MARK: Meeting Type Enum
        /* ############################################################################################################################## */
        /**
         This provides values for the type of meeting.
         */
        public enum MeetingType: String {
            /* ############################################# */
            /**
             The meeting only gathers virtually.
             */
            case virtual

            /* ############################################# */
            /**
             The meeting only gathers in-person.
             */
            case inPerson

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually.
             */
            case hybrid
        }
        
        /* ############################################################################################################################## */
        // MARK: Meeting Type Enum
        /* ############################################################################################################################## */
        /**
         This has the type of meeting, but in a sortable manner.
         */
        public enum SortableMeetingType: Int, Comparable {
            /* ############################################# */
            /**
             Comparable Conformance
             - parameter lhs: The left-hand side of the comparison
             - parameter rhs: The right-hand side of the comparison
             - returns: True, if lhs < rhs.
             */
            public static func < (lhs: SwiftBMLSDK_Parser.Meeting.SortableMeetingType, rhs: SwiftBMLSDK_Parser.Meeting.SortableMeetingType) -> Bool { lhs.rawValue < rhs.rawValue }
            
            /* ############################################# */
            /**
             The meeting only gathers in-person.
             */
            case inPerson

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, by both phone and video.
             */
            case hybrid

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, but only via video.
             */
            case hybrid_video

            /* ############################################# */
            /**
             The meeting gathers, both in-person, and virtually, but only via phone.
             */
            case hybrid_phone

            /* ############################################# */
            /**
             The meeting only gathers virtually, by both phone and video.
             */
            case virtual

            /* ############################################# */
            /**
             The meeting only gathers virtually, and only by video.
             */
            case virtual_video

            /* ############################################# */
            /**
             The meeting only gathers virtually, and only by phone.
             */
            case virtual_phone
        }

        /* ############################################################################################################################## */
        // MARK: Organization Type Enum
        /* ############################################################################################################################## */
        /**
         This specifies the organization for the meeting.
         */
        public enum Organization: String, Codable {
            /* ############################################# */
            /**
             No organization specified
             */
            case none

            /* ############################################# */
            /**
             Narcotics Anonymous
             */
            case na
        }

        // MARK: Public Instance Properties
        
        /* ################################################################## */
        /**
         The distance in meters from the geographic request center to the meeting. Returns -1 when the request has no geographic filter or the meeting has no physical coordinates. This stored value is not changed by other distance helpers.
         */
        public let distanceInMeters: CLLocationDistance

        /* ################################################# */
        /**
         This is the unique ID (within the found set) for the data source server.
         */
        public let serverID: Int
        
        /* ################################################# */
        /**
         This is a unique ID (within the data source server) for this meeting.
         */
        public let localMeetingID: Int
        
        /* ################################################# */
        /**
         This is a 1-based weekday index, with 1 being Sunday, and 7 being Saturday.
         */
        public let weekday: Int
        
        /* ################################################# */
        /**
         The meeting's wall-clock start time, stored on January 1, 2001, in GMT.

         This value is a container for hour, minute, and second; it is not a real meeting occurrence.
         Extract or format it using GMT. For a real date, use ``nextOccurrenceDateFast(from:calendar:)``;
         for display, use ``localizedWeekdayTimeString(style:locale:calendar:timeZone:adjusted:includeDuration:)``.
         */
        public let startTime: Date
        
        /* ################################################# */
        /**
         The duration in seconds. Missing, negative, or 24-hour-or-longer values use 3,600 seconds. Zero is retained and is never considered in progress.
         */
        public let duration: TimeInterval
        
        /* ################################################# */
        /**
         This is the local timezone of this meeting.
         */
        public let timeZone: TimeZone
        
        /* ################################################# */
        /**
         This is the name of the meeting.
         */
        public let name: String

        /* ################################################# */
        /**
         This is the organization to which this meeting belongs.
         */
        public let organization: Organization
        
        /* ################################################# */
        /**
         The meeting formats, sorted by their keys.
         */
        public let formats: [Format]

        // MARK: Public Optional Instance Properties
        
        /* ################################################# */
        /**
         The validated physical coordinates, if a usable street address is retained. Virtual-only meetings and the known default NAWS office location have no coordinates.
         */
        public let coords: CLLocationCoordinate2D?
        
        /* ################################################# */
        /**
         This is any additional comments for the meeting. It is optional.
         */
        public let comments: String?
        
        /* ################################################# */
        /**
         This is the name for an in-person venue. It is optional.
         */
        public let inPersonVenueName: String?
        
        /* ################################################# */
        /**
         This is a physical address of an in-person meeting. It is optional.
         */
        public let inPersonAddress: CNPostalAddress?

        /* ################################################# */
        /**
         This is any additional text, describing the location. It is optional.
         */
        public let locationInfo: String?
        
        /* ################################################# */
        /**
         This is a URL for a virtual meeting. It is optional.
         */
        public let virtualURL: URL?
        
        /* ################################################# */
        /**
         This is a phone number for a virtual meeting. It is optional.
         */
        public let virtualPhoneNumber: String?
        
        /* ################################################# */
        /**
         This is any additional text, describing the virtual meeting. It is optional.
         */
        public let virtualInfo: String?
        
        // MARK: Public Computed Properties
        
        /* ################################################################## */
        /**
         Convenience accessor for the receiver's `virtualPhoneNumber`.
         */
        var virtualPhoneURL: URL? {
            guard let virtualPhoneNumber = virtualPhoneNumber,
                  !virtualPhoneNumber.isEmpty
            else { return nil }

            return Self._dialInURL(from: virtualPhoneNumber)
        }

        /* ################################################# */
        /**
         The composite ID: the server ID occupies the upper 20 bits, and the local meeting ID occupies the lower 44 bits. Pass this value to ``SwiftBMLSDK_Query/SearchSpecification/meetingIDs`` to fetch a specific meeting.
         */
        public var id: UInt64 { (UInt64(serverID) << 44) + UInt64(localMeetingID) }

        /* ################################################# */
        /**
         The meeting type.
         */
        public var meetingType: MeetingType {
            if (!(inPersonVenueName ?? "").isEmpty || !(inPersonAddress?.street ?? "").isEmpty),
               !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return .hybrid
            } else if !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return .virtual
            } else {
                return .inPerson
            }
        }

        /* ################################################# */
        /**
         The meeting type, as a sortable value.
         */
        public var sortableMeetingType: SortableMeetingType {
            if (!(inPersonVenueName ?? "").isEmpty || !(inPersonAddress?.street ?? "").isEmpty),
               !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return  (!(virtualURL?.absoluteString ?? "").isEmpty && (virtualPhoneNumber ?? "").isEmpty) ? .hybrid_video :
                ((virtualURL?.absoluteString ?? "").isEmpty && !(virtualPhoneNumber ?? "").isEmpty) ? .hybrid_phone : .hybrid
            } else if !(virtualURL?.absoluteString ?? "").isEmpty || !(virtualPhoneNumber ?? "").isEmpty {
                return  (!(virtualURL?.absoluteString ?? "").isEmpty && (virtualPhoneNumber ?? "").isEmpty) ? .virtual_video :
                ((virtualURL?.absoluteString ?? "").isEmpty && !(virtualPhoneNumber ?? "").isEmpty) ? .virtual_phone : .virtual
            } else {
                return .inPerson
            }
        }

        /* ################################################# */
        /**
         The start time, in the meeting's local timezone, as a military-style integer (HHMM).

         Returns -1 if the time could not be calculated.
         */
        public var integerStartTime: Int {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

            let components = calendar.dateComponents([.hour, .minute], from: self.startTime)

            guard let hour = components.hour,
                  (0..<24).contains(hour),
                  let minute = components.minute,
                  (0..<60).contains(minute)
            else { return -1 }

            return (hour * 100) + minute
        }
        
        /* ################################################# */
        /**
         The next meeting start time, expressed in the user's current timezone,
         as a military-style integer (`HHMM`).

         This interprets the next absolute occurrence of the meeting in the user's
         local timezone, without mutating the receiver.

         - returns: The adjusted start time as `HHMM`, or `-1` if it cannot be derived.
         */
        public var adjustedIntegerStartTime: Int {
            let starter = self.nextOccurrenceDateFast()
            let calendar = Calendar.autoupdatingCurrent
            let components = calendar.dateComponents([.hour, .minute], from: starter)
            
            guard let hour = components.hour,
                  (0..<24).contains(hour),
                  let minute = components.minute,
                  (0..<60).contains(minute)
            else { return -1 }
            
            return (hour * 100) + minute
        }

        /* ################################################# */
        /**
         Returns the meeting location as a CLLocation.
         > NOTE: This may return nil, as not all meetings have a location.
         */
        public var location: CLLocation? {
            guard let lat = coords?.latitude,
                  let lng = coords?.longitude,
                  CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            else { return nil }
            return CLLocation(latitude: lat, longitude: lng)
        }
        
        /* ################################################################## */
        /**
         This returns the address of an in-person meeting, in a localized format.
         
         - returns: A locality-relevant address string.
         
         > NOTE: The venue name is not a part of this.
         */
        public var localizedInPersonAddressString: String? {
            if let address = self.inPersonAddress {
                return CNPostalAddressFormatter.string(from: address, style: .mailingAddress)
            }
            
            return nil
        }
        
        /* ################################################################## */
        /**
         The meeting's scheduled weekday as a zero-based index relative to the device calendar's first weekday. This changes week ordering, not the meeting's timezone.
         */
        public var localWeekdayIndex: Int { Calendar.autoupdatingCurrent._userWeekStartIndex(fromSundayBasedWeekday: self.weekday) }
        
        /* ################################################################## */
        /**
         True during the interval from the previous occurrence up to, but excluding, its end. Equivalent to ``isMeetingInProgress()``.
         */
        public var isMeetingInProgressNow: Bool { isMeetingInProgress() }

        /* ################################################################## */
        /**
         Returns the meeting's scheduled weekday name in the device locale. It does not shift the weekday into the device timezone; use ``localizedWeekdayTimeString(style:locale:calendar:timeZone:adjusted:includeDuration:)`` with `adjusted: true` for that.
         
         - parameter inStyle: The style of weekday display. Optional, and default is `.standaloneFull`. Values are:
            - .full
            - .short
            - .veryShort
            - .standaloneFull
            - .standaloneShort
            - .standaloneVeryShort
         
         - returns: The localized string.
         */
        public func localWeekdayString(style inStyle: Calendar.WeekdayStyle = .standaloneFull) -> String { Calendar.autoupdatingCurrent._localizedWeekdayString(fromSundayBasedWeekday: self.weekday, style: inStyle) }
        
        /* ################################################################## */
        /**
         This returns a localized weekday/time string for the receiver's next occurrence
         (for example, `"Wednesday 7:30 PM"` or `"Wednesday 1930"`).

         The next occurrence is computed as an absolute `Date` using the receiver's local
         meeting weekday, start time, and `timeZone`. That absolute date is then formatted
         in either the meeting's local timezone or a caller-supplied display timezone.

         - parameter inStyle: The style of string the user wants. Optional. Default is the
           user's preferred time format. You can also force 24-hour format.
         - parameter inLocale: The locale used for formatting. Optional. Default is
           `.autoupdatingCurrent`.
         - parameter inCalendar: The calendar used for formatting. Optional. Default is
           `.autoupdatingCurrent`.
         - parameter inTimeZone: The timezone to use when `inIsAdjusted` is `true`.
           Optional. Default is `.autoupdatingCurrent`.
         - parameter inIsAdjusted: If `true`, format the result in `inTimeZone`. If `false`
           (the default), format in the meeting's local timezone.
         - parameter inIncludeDuration: Optional (default is `false`). If `true`, the string
           will display the time as a range, such as `"Wednesday 7:30 PM-8:30 PM"`.
         - returns: The formatted weekday/time string for the next start.
         */
        public func localizedWeekdayTimeString(
            style inStyle: LocalWeekdayTimeStyle = .userPreferredTime,
            locale inLocale: Locale = .autoupdatingCurrent,
            calendar inCalendar: Calendar = .autoupdatingCurrent,
            timeZone inTimeZone: TimeZone = .autoupdatingCurrent,
            adjusted inIsAdjusted: Bool = false,
            includeDuration inIncludeDuration: Bool = false
        ) -> String {
            let startDate = self.nextOccurrenceDateFast()
            
            let displayTimeZone = inIsAdjusted ? inTimeZone : self.timeZone
            
            var displayCalendar = inCalendar
            displayCalendar.timeZone = displayTimeZone
            
            let startFormatter = DateFormatter()
            startFormatter.locale = inLocale
            startFormatter.calendar = displayCalendar
            startFormatter.timeZone = displayTimeZone

            let endFormatter = DateFormatter()
            endFormatter.locale = inLocale
            endFormatter.calendar = displayCalendar
            endFormatter.timeZone = displayTimeZone

            switch inStyle {
            case .userPreferredTime:
                startFormatter.setLocalizedDateFormatFromTemplate("EEEE jm")
                endFormatter.setLocalizedDateFormatFromTemplate("jm")

            case .twentyFourHourCompact:
                startFormatter.dateFormat = "EEEE HHmm"
                endFormatter.dateFormat = "HHmm"
            }

            let startString = startFormatter.string(from: startDate)
            
            guard inIncludeDuration else { return startString }
            
            let endDate = startDate.addingTimeInterval(self.duration)
            let endString = endFormatter.string(from: endDate)
            
            return "\(startString)-\(endString)"
        }
        
        /* ################################################################## */
        /**
         This returns the distance between the instance, and another location, provided as coordinates.
         
         - parameter inCoords: The coordinates we are measuring from.
         - returns: The nonnegative distance in meters, or -1 if either location is invalid or unavailable.
         */
        public func distanceFrom(_ inCoords: CLLocationCoordinate2D) -> CLLocationDistance {
            guard let coords = location?.coordinate, CLLocationCoordinate2DIsValid(inCoords) else { return -1 }
            let compLocation = CLLocation(latitude: inCoords.latitude, longitude: inCoords.longitude)
            return CLLocation(latitude: coords.latitude, longitude: coords.longitude).distance(from: compLocation)
        }
    }

    // MARK: Public Immutable Properties
    
    /* ################################################# */
    /**
     The page metadata for this page of meetings.
     */
    public let meta: PageMeta
    
    /* ################################################# */
    /**
     The meeting data for this page of meetings.
     */
    public let meetings: [Meeting]
}

/* ###################################################################################################################################### */
// MARK: - Meeting Equatable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Equatable {
    /* ############################################# */
    /**
     Public Equatable Conformance
     
     - parameter lhs: The left-hand side of the comparison.
     - parameter rhs: The right-hand side of the comparison.
     */
    public static func == (lhs: SwiftBMLSDK_Parser.Meeting, rhs: SwiftBMLSDK_Parser.Meeting) -> Bool { lhs.id == rhs.id }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Hashable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Hashable {
    /* ############################################# */
    /**
     Public Hashable Conformance
     
     - parameter inOutHasher: (INOUT) -The hasher to be loaded.
     */
    public func hash(into inOutHasher: inout Hasher) { inOutHasher.combine(id) }
}

/* ###################################################################################################################################### */
// MARK: - Meeting CustomStringConvertible Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: CustomStringConvertible {
    /* ############################################# */
    /**
     Public CustomStringConvertible Conformance
     */
    public var description: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .gmt
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: startTime)
        var ret = "Meeting:\n\t"
        ret += "id:\t\(id)\n\t"
        ret += "serverID:\t\(serverID)\n\t"
        ret += "localMeetingID:\t\(localMeetingID)\n\t"
        ret += "weekday:\t\(weekday)\n\t"
        ret += "startTime:\t\(timeString)\n\t"
        ret += "duration:\t\(duration)\n\t"
        ret += "timeZone:\t\(timeZone.debugDescription)\n\t"
        ret += "organization:\t\(organization.rawValue)\n\t"
        ret += "name:\t\(name)\n\t"
        ret += "formats:\n\(formats.map { $0.debugDescription }.joined(separator: "\n"))\n\t"
        
        if let coords = coords {
            ret += "coords:\t(latitude: \(coords.latitude), longitude: \(coords.longitude))\n\t"
        }
        
        if let comments = comments,
           !comments.isEmpty {
            ret += "comments:\t\(comments)\n\t"
        }

        if let locationInfo = locationInfo,
           !locationInfo.isEmpty {
            ret += "locationInfo:\t\(locationInfo)\n\t"
        }

        if let virtualURL = virtualURL?.absoluteString,
           !virtualURL.isEmpty {
            ret += "virtualURL:\t\(virtualURL)\n\t"
        }

        if let virtualPhoneNumber = virtualPhoneNumber,
           !virtualPhoneNumber.isEmpty {
            ret += "virtualPhoneNumber:\t\(virtualPhoneNumber)\n\t"
        }

        if let virtualInfo = virtualInfo,
           !virtualInfo.isEmpty {
            ret += "virtualInfo:\t\(virtualInfo)\n\t"
        }

        if let inPersonVenueName = inPersonVenueName,
           !inPersonVenueName.isEmpty {
            ret += "inPersonVenueName:\t\(inPersonVenueName)\n\t"
        }

        if nil != inPersonAddress,
           !basicInPersonAddress.isEmpty {
            ret += "inPersonAddress:\t\(basicInPersonAddress)\n\t"
        }

        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting CustomDebugStringConvertible Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: CustomDebugStringConvertible {
    /* ############################################# */
    /**
     Public CustomDebugStringConvertible Conformance
     */
    public var debugDescription: String { description }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Encodable Conformance -
/* ###################################################################################################################################### */
extension SwiftBMLSDK_Parser.Meeting: Encodable {
    /* ############################################################################################################################## */
    // MARK: Codable Coding Keys
    /* ############################################################################################################################## */
    /**
     This defines the keys that we use for encoding and decoding.
     
     This struct was inspired by [this SO answer](https://stackoverflow.com/a/50715560/879365)
     */
    private struct _CustomCodingKeys: CodingKey {
        /* ############################################# */
        /**
         We only keep a string.
         */
        var stringValue: String

        /* ############################################# */
        /**
         We can initialize with a string.
         */
        init?(stringValue inStringValue: String) { stringValue = inStringValue }

        /* ############################################# */
        /**
         We define this, but it won't be used.
         */
        var intValue: Int?

        /* ############################################# */
        /**
         The integer variant always fails.
         */
        init?(intValue: Int) { nil }
    }
    
    /* ############################################# */
    /**
     Encoder
     
     The reason for the "flat" encoding, is that many ML parsers like fairly simple data, without nesting.
     Nested structures, like the coordinates and the formats, are converted to top-level basic data types, so that a JSON file, made from the encoder, is simple and flat.
     
     Each format is encoded under `format-<id>` with the value `Name (Description)`. Coordinates and address fields are flattened into top-level keys. The start time remains the meeting's wall-clock `HH:mm:ss` value.
     
     If a value is not valid, it is not included in the encoding.
     
     - parameter inEncoder: The encoder to load with the SDK export schema.
     - throws: Any error raised by the encoder. This type does not decode the export back into a meeting.
     */
    public func encode(to inEncoder: Encoder) throws {
        guard (1..<8).contains(weekday) else { return }
        
        var container = inEncoder.container(keyedBy: _CustomCodingKeys.self)
        
        try container.encode(id, forKey: _CustomCodingKeys(stringValue: "id")!)

        // These three must always be present.
        try container.encode(serverID, forKey: _CustomCodingKeys(stringValue: "serverID")!)
        
        try container.encode(localMeetingID, forKey: _CustomCodingKeys(stringValue: "localMeetingID")!)
        
        let typeString = meetingType.rawValue
        if !typeString.isEmpty {
            try container.encode(typeString, forKey: _CustomCodingKeys(stringValue: "meetingType")!)
        }

        if (1..<8).contains(weekday) {
            try container.encode(weekday, forKey: _CustomCodingKeys(stringValue: "weekday")!)
        }
        
        // We hardcode, to provide consistency.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .gmt
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: startTime)
        if !timeString.isEmpty {
            try container.encode(timeString, forKey: _CustomCodingKeys(stringValue: "startTime")!)
        }
        
        if 0 < duration {
            try container.encode(duration, forKey: _CustomCodingKeys(stringValue: "duration")!)
        }
        
        let tzString = timeZone.identifier
        if !tzString.isEmpty {
            try container.encode(tzString, forKey: _CustomCodingKeys(stringValue: "timezone")!)
        }
        
        let orgString = organization.rawValue
        if !orgString.isEmpty {
            try container.encode(orgString, forKey: _CustomCodingKeys(stringValue: "organization")!)
        }
        
        if !name.isEmpty {
            try container.encode(name, forKey: _CustomCodingKeys(stringValue: "name")!)
        }
        
        if !formats.isEmpty {
            try formats.forEach {
                let formatString = $0.asString
                if !formatString.isEmpty {
                    try container.encode(formatString, forKey: _CustomCodingKeys(stringValue: "format-\($0.id)")!)
                }
            }
        }
        
        if let comments = comments,
           !comments.isEmpty {
            try container.encode(comments, forKey: _CustomCodingKeys(stringValue: "comments")!)
        }
        
        if let locationInfo = locationInfo,
           !locationInfo.isEmpty {
            try container.encode(locationInfo, forKey: _CustomCodingKeys(stringValue: "locationInfo")!)
        }
        
        if let virtualURL = virtualURL?.absoluteString,
           !virtualURL.isEmpty {
            try container.encode(virtualURL, forKey: _CustomCodingKeys(stringValue: "virtualURL")!)
        }
        
        if let virtualPhoneNumber = virtualPhoneNumber,
           !virtualPhoneNumber.isEmpty {
            try container.encode(virtualPhoneNumber, forKey: _CustomCodingKeys(stringValue: "virtualPhoneNumber")!)
        }
        
        if let virtualInfo = virtualInfo,
           !virtualInfo.isEmpty {
            try container.encode(virtualInfo, forKey: _CustomCodingKeys(stringValue: "virtualInfo")!)
        }

        if let latitude = coords?.latitude,
           let longitude = coords?.longitude,
           CLLocationCoordinate2DIsValid(coords!) {
            try container.encode(Double(round(1000000.0 * latitude) / 1000000.0), forKey: _CustomCodingKeys(stringValue: "latitude")!)
            try container.encode(Double(round(1000000.0 * longitude) / 1000000.0), forKey: _CustomCodingKeys(stringValue: "longitude")!)
        }
        
        if let inPersonVenueName = inPersonVenueName,
           !inPersonVenueName.isEmpty {
            try container.encode(inPersonVenueName, forKey: _CustomCodingKeys(stringValue: "address_VenueName")!)
        }
        
        if let string = inPersonAddress?.street,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_Street")!)
        }
        
        if let string = inPersonAddress?.subLocality,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_SubLocality")!)
        }
        
        if let string = inPersonAddress?.city,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_City")!)
        }
        
        if let string = inPersonAddress?.state,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_State")!)
        }
        
        if let string = inPersonAddress?.subAdministrativeArea,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_SubAdministrativeArea")!)
        }
        
        if let string = inPersonAddress?.postalCode,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_PostalCode")!)
        }
        
        if let string = inPersonAddress?.country,
           !string.isEmpty {
            try container.encode(string, forKey: _CustomCodingKeys(stringValue: "address_Country")!)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic interpretation methods to the base class.
 */
extension SwiftBMLSDK_Parser.Meeting {
    /* ################################################################## */
    /**
     Use this for the distance string generator.
     */
    public typealias DistanceUnitWidth = Measurement<UnitLength>.FormatStyle.UnitWidth

    /* ################################################################## */
    /**
     These are the supported display widths for localized distance strings.
     */
    public enum DistanceStringWidth {
        /* ############################################################## */
        /**
         Localized abbreviated units (for example, "mi").
         */
        case abbreviated

        /* ############################################################## */
        /**
         Localized narrow units.
         */
        case narrow

        /* ############################################################## */
        /**
         Localized wide units (for example, "miles").
         */
        case wide

        /* ############################################################## */
        /**
         The Foundation width value that corresponds to the receiver.
         */
        fileprivate var unitWidth: DistanceUnitWidth {
            switch self {
            case .abbreviated:
                return .abbreviated

            case .narrow:
                return .narrow

            case .wide:
                return .wide
            }
        }
    }

    /* ################################################################## */
    /**
     The time-format preference used by the localized weekday/time display.
     */
    public enum LocalWeekdayTimeStyle {
        /* ############################################################## */
        /**
         e.g. "Sunday, 10:30 PM" or locale equivalent
         */
        case userPreferredTime

        /* ############################################################## */
        /**
         e.g. "Sunday, 2230"
         */
        case twentyFourHourCompact
    }

    // MARK: Public Computed Properties
    
    /* ################################################################## */
    /**
     True, if the meeting has a virtual component.
     */
    public var hasVirtual: Bool { .virtual == meetingType || .hybrid == meetingType }
    
    /* ################################################################## */
    /**
     True, if the meeting has an in-person component.
     */
    public var hasInPerson: Bool { .inPerson == meetingType || .hybrid == meetingType }
    
    /* ################################################# */
    /**
     The meeting's wall-clock start time as seconds from midnight, including the seconds field. No timezone conversion is applied.
     
     It returns -1, if there was a problem.
     */
    public var startTimeInSecondsFromMidnight: TimeInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        let components = calendar.dateComponents([.hour, .minute, .second], from: self.startTime)

        guard let startHour = components.hour,
              let startMinute = components.minute,
              (0..<24).contains(startHour),
              (0..<60).contains(startMinute)
        else { return -1 }

        return TimeInterval(startHour * 3600 + startMinute * 60 + (components.second ?? 0))
    }
    
    /* ################################################# */
    /**
     The scheduled weekday, hour, minute, and second in a Gregorian calendar configured with the meeting's timezone. These recurring components have no year, month, or day.
     */
    public var dateComponents: DateComponents? {
        var extractionCalendar = Calendar(identifier: .gregorian)
        extractionCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        let components = extractionCalendar.dateComponents([.hour, .minute, .second], from: self.startTime)

        guard let startHour = components.hour,
              let startMinute = components.minute
        else { return nil }

        var meetingCalendar = Calendar(identifier: .gregorian)
        meetingCalendar.timeZone = self.timeZone

        return DateComponents(
            calendar: meetingCalendar,
            timeZone: self.timeZone,
            hour: startHour,
            minute: startMinute,
            second: components.second ?? 0,
            weekday: weekday
        )
    }

    /* ################################################# */
    /**
     This returns the address as a basic readable address.
     */
    public var basicInPersonAddress: String {
        var ret = inPersonVenueName ?? ""
        if let postalAddress = inPersonAddress {
            let formatter = CNPostalAddressFormatter()
            formatter.style = .mailingAddress
            
            ret += (!ret.isEmpty ? "\n" : "") + formatter.string(from: postalAddress)
        }

        return ret
    }
    
    // MARK: Public Non-Mutating Instance Methods
    
    /* ################################################################## */
    /**
     Returns the linear distance, in meters, between the input coordinate, and the meeting's coordinate.
     
     > NOTE: May return nil, as not all meetings have a valid coordinate.
     
     - parameter inFrom: The coordinates of the location we are comparing to the meeting's location.
     - returns: An optional (may be nil) float, with the exact distance between the meeting's location, and the input. It is always positive (or 0), if not nil.
     */
    public func distanceInMeters(from inFrom: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let myLocation = location,
              CLLocationCoordinate2DIsValid(inFrom)
        else { return nil }
        
        return myLocation.distance(from: CLLocation(latitude: inFrom.latitude, longitude: inFrom.longitude))
    }
    
    /* ################################################################## */
    /**
     The number of seconds until the next occurrence, rounded up. Calculated on each access; equivalent to ``meetingStartsIn()``.
     */
    public var nextMeetingIn: TimeInterval { meetingStartsIn() }
    
    /* ################################################################## */
    /**
     Returns the distance from the receiver's coordinates to the supplied location.
     
     - parameter inLocation: The location from which the distance is measured.
     - returns: The distance in meters, or zero if either coordinate is invalid or unavailable. Use ``distanceInMeters(from:)`` when you need to distinguish an unavailable distance from zero.
     */
    public func distanceFrom(location inLocation: CLLocationCoordinate2D) -> Measurement<UnitLength> {
        guard let myCoords = self.coords, CLLocationCoordinate2DIsValid(inLocation) else {
            return .init(value: 0, unit: .meters)
        }
        
        let meetingLocation = CLLocation(latitude: myCoords.latitude, longitude: myCoords.longitude)
        let startingLocation = CLLocation(latitude: inLocation.latitude, longitude: inLocation.longitude)
        
        return .init(
            value: meetingLocation.distance(from: startingLocation),
            unit: .meters
        )
    }
    
    /* ################################################################## */
    /**
     Returns the distance from the receiver's coordinates to the supplied location
     as a localized display string.
     
     This uses Swift's modern measurement-formatting API, and formats the distance
     using a road/travel-oriented presentation for the current locale. The caller
     can control both the display width and the allowed fractional precision.
     
     Typical width values are:
     
     - `.abbreviated`: Compact output, such as `1.2 mi` or `850 m`
     - `.wide`: More explicit output, such as `1.2 miles`
     - `.narrow`: Very compact output where supported by the locale
     
     The precision is supplied as a closed integer range representing the minimum
     and maximum number of fraction digits to display. For example:
     
     - `0...1`: Show zero or one fractional digit
     - `0...2`: Show zero, one, or two fractional digits
     - `1...1`: Always show exactly one fractional digit
     
     If the distance is zero or unavailable, this returns an empty string.
     
     - parameter inLocation: The location from which the distance is measured.
     - parameter inWidth: The localized unit-width style used for formatting.
       Optional. Default is `.abbreviated`.
     - parameter inPrecision: The minimum and maximum number of fraction digits
       to display. Optional. Default is `0...1`.
     - returns: A localized distance string, or an empty string if the distance is zero or unavailable.
     */
    // Prefer the SDK width enum when the caller omits the width or uses an inferred case.
    @_disfavoredOverload
    public func distanceStringFrom(
        location inLocation: CLLocationCoordinate2D,
        width inWidth: Measurement<UnitLength>.FormatStyle.UnitWidth = .abbreviated,
        precision inPrecision: ClosedRange<Int> = 0...1
    ) -> String {
        let distance = self.distanceFrom(location: inLocation)
        
        guard 0 < distance.value else { return "" }
        
        return distance.formatted(
            .measurement(
                width: inWidth,
                usage: .road,
                numberFormatStyle: .number.precision(.fractionLength(inPrecision))
            )
        )
    }
    
    /* ################################################################## */
    /**
     Returns the distance from the receiver's coordinates to the supplied location
     as a localized string, using an SDK-defined width style.

     - parameter inLocation: The location from which the distance is measured.
     - parameter inWidth: The localized unit-width style used for formatting.
       Optional. Default is `.abbreviated`.
     - parameter inPrecision: The minimum and maximum number of fraction digits
       to display. Optional. Default is `0...1`.
     - returns: A localized distance string.
     */
    public func distanceStringFrom(
        location inLocation: CLLocationCoordinate2D,
        width inWidth: DistanceStringWidth = .abbreviated,
        precision inPrecision: ClosedRange<Int> = 0...1
    ) -> String {
        self.distanceStringFrom(
            location: inLocation,
            width: inWidth.unitWidth,
            precision: inPrecision
        )
    }

    /* ################################################################## */
    /**
     Returns the number of seconds until the next occurrence, rounded up to a whole second.
     
     - returns: The number of seconds, before the next start.
     */
    public func meetingStartsIn() -> TimeInterval {
        let now = Date.now
        let meetingStartTime = nextOccurrenceDateFast()
        var ret = now.distance(to: meetingStartTime)
        
        if 0 > ret {
            ret = floor(ret)
        } else {
            ret = ceil(ret)
        }
    
        return ret
    }

    /* ################################################################## */
    /**
     Returns whether the previous occurrence has started and has not yet ended.

     - returns: True for the half-open interval from the previous start to start plus duration. Zero-duration meetings return false.
     */
    public func isMeetingInProgress() -> Bool {
        guard duration > 0 else { return false }
        let now = Date()
        let previousStart = previousOccurrenceDateFast(from: now)
        return previousStart <= now && now < previousStart.addingTimeInterval(duration)
    }
}

/* ###################################################################################################################################### */
// MARK: - Meeting Extension: Fast Ocurrence Calculation Support -
/* ###################################################################################################################################### */
public extension SwiftBMLSDK_Parser.Meeting {
    /* ################################################################## */
    /**
     Returns the next absolute occurrence as date components in the meeting's timezone and the device's calendar.
     
     - returns: Date components in the meeting's local timezone.
     */
    var meetingLocalComponents: DateComponents {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = self.timeZone
        
        return calendar.dateComponents(
            [.year, .month, .day, .weekday, .hour, .minute, .second],
            from: self.nextOccurrenceDateFast()
        )
    }

    /* ################################################################## */
    /**
     Returns the first weekly occurrence strictly after the reference date.

     The weekday and wall-clock time are interpreted in ``timeZone``. Calendar-day math
     preserves that clock time across daylight-saving changes. A missing clock hour moves
     forward while preserving minutes and seconds (02:30 becomes 03:30). A repeated hour
     uses its first occurrence. The returned `Date` is absolute; format it in the desired
     display timezone without adding or subtracting timezone offsets.

     - parameter inReferenceDate: Exclusive lower bound. Default is the current instant.
     - parameter inCalendarIdentifier: Calendar for date math. Default is the device's
       autoupdating calendar identifier; the meeting's timezone is always used.
     - returns: The next absolute occurrence. An exact start-time reference advances to next week.
     */
    func nextOccurrenceDateFast(
        from inReferenceDate: Date = Date(),
        calendar inCalendarIdentifier: Calendar.Identifier = Calendar.autoupdatingCurrent.identifier
    ) -> Date {
        var calendar = Calendar(identifier: inCalendarIdentifier)
        calendar.timeZone = self.timeZone
        
        let dayOffset = (weekday - calendar.component(.weekday, from: inReferenceDate) + 7) % 7
        let today = calendar.startOfDay(for: inReferenceDate)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        let candidate = _occurrence(on: day, calendar: calendar)
        if candidate > inReferenceDate { return candidate }
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: day) ?? day
        return _occurrence(on: nextWeek, calendar: calendar)
    }
    
    /* ################################################################## */
    /**
     Returns the most recent weekly occurrence at or before the reference date.

     Uses the same meeting timezone and daylight-saving policy as
     ``nextOccurrenceDateFast(from:calendar:)``. The result includes an occurrence
     starting exactly at the reference date, which supports in-progress checks.

     - parameter inReferenceDate: Inclusive upper bound. Default is the current instant.
     - parameter inCalendarIdentifier: Calendar for date math. Default is the device's
       autoupdating calendar identifier; the meeting's timezone is always used.
     - returns: The previous or current occurrence as an absolute date.
     */
    func previousOccurrenceDateFast(
        from inReferenceDate: Date = Date(),
        calendar inCalendarIdentifier: Calendar.Identifier = Calendar.autoupdatingCurrent.identifier
    ) -> Date {
        var calendar = Calendar(identifier: inCalendarIdentifier)
        calendar.timeZone = self.timeZone

        let dayOffset = (calendar.component(.weekday, from: inReferenceDate) - weekday + 7) % 7
        let today = calendar.startOfDay(for: inReferenceDate)
        let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
        let candidate = _occurrence(on: day, calendar: calendar)
        if candidate <= inReferenceDate { return candidate }
        let previousWeek = calendar.date(byAdding: .day, value: -7, to: day) ?? day
        return _occurrence(on: previousWeek, calendar: calendar)
    }

    /* ################################################################## */
    /**
     Resolves the meeting's wall-clock time, preserving minutes and seconds across a
     missing daylight-saving hour and choosing the first occurrence of a repeated hour.
     */
    private func _occurrence(on inDay: Date, calendar inCalendar: Calendar) -> Date {
        let seconds = Int(startTimeInSecondsFromMidnight)
        let clock = DateComponents(hour: seconds / 3600,
                                   minute: (seconds % 3600) / 60,
                                   second: seconds % 60)
        return inCalendar.nextDate(after: inCalendar.startOfDay(for: inDay).addingTimeInterval(-1),
                                   matching: clock,
                                   matchingPolicy: .nextTimePreservingSmallerComponents,
                                   repeatedTimePolicy: .first) ?? inDay
    }
    
    /* ################################################################## */
    /**
     Returns a numeric sort key for the receiver's next occurrence.
     
     - parameter inReferenceDate: The point in time from which the next occurrence
     should be calculated. Optional. Default is `Date()`.
     - parameter inCalendarIdentifier: The calendar used for date math. Optional.
     Default is the current autoupdating.
     - returns: A sortable numeric key.
     */
    func sortingKeyFast(
        from inReferenceDate: Date = Date(),
        calendar inCalendarIdentifier: Calendar.Identifier = Calendar.autoupdatingCurrent.identifier
    ) -> TimeInterval {
        self.nextOccurrenceDateFast(
            from: inReferenceDate,
            calendar: inCalendarIdentifier
        ).timeIntervalSinceReferenceDate
    }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension -
/* ###################################################################################################################################### */
/**
 This extension allows us to perform additional operations on an Array of meetings.
 */
public extension Array where Element == SwiftBMLSDK_Parser.Meeting {
    /* ################################################################################################################################## */
    // MARK: Weekday Filtering Enum
    /* ################################################################################################################################## */
    /**
     This defines a 1-based Gregorian weekday specification.
     All meetings consider 1 to be Sunday, so the local week start should be converted (see init, below).
     */
    enum Weekdays: Int {
        /* ############################################# */
        /**
         Sunday
         */
        case sunday = 1
        
        /* ############################################# */
        /**
         Monday
         */
        case monday
        
        /* ############################################# */
        /**
         Tuesday
         */
        case tuesday
        
        /* ############################################# */
        /**
         Wednesday
         */
        case wednesday

        /* ############################################# */
        /**
         Thursday
         */
        case thursday

        /* ############################################# */
        /**
         Friday
         */
        case friday

        /* ############################################# */
        /**
         Saturday
         */
        case saturday
        
        /* ############################################# */
        /**
         This allows us to set the weekday as adjusted from our locale.
         - parameter rawValue: 1 -> 7, with 1 being the first day of the week.
         - parameter isAdjusted: Optional (default is true), telling the initializer to adjust from the current locale week start, to the 1 == Sunday start, required by the meeting instance.
         */
        init?(rawValue inRawValue: Int, isAdjusted inIsAdjusted: Bool = true) {
            guard (1...7).contains(inRawValue) else { return nil }
            let rawVal = inIsAdjusted ? (inRawValue + Calendar.current.firstWeekday - 2) % 7 + 1 : inRawValue
            self.init(rawValue: rawVal)
        }
    }
    
    /* ################################################# */
    /**
     Subscript that allows us to specify a particular meeting type.
     - parameter inMeetingType: The type of meeting we are looking for.
     - returns: Meetings of the specified type.
     > NOTE: This is fileprivate, and not exported.
     */
    fileprivate subscript(_ inMeetingType: SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType) -> [SwiftBMLSDK_Parser.Meeting] {
        switch inMeetingType {
        case .hybrid:
            return compactMap { .hybrid == $0.meetingType ? $0 : nil }
            
        case .virtual(let isExclusive):
            return compactMap { .virtual == $0.meetingType ? $0 : (isExclusive ? nil : (.hybrid == $0.meetingType ? $0 : nil)) }
            
        case .inPerson(let isExclusive):
            return compactMap { .inPerson == $0.meetingType ? $0 : (isExclusive ? nil : (.hybrid == $0.meetingType ? $0 : nil)) }

        default:
            return self
        }
    }

    /* ################################################# */
    /**
     Subscript that allows us to filter for multiple weekdays.
     - parameter inWeekdaySet: The weekdays to filter for. This is in the local meeting timezone.
     - returns: Meetings of the specified type.
     */
    subscript(_ inWeekdaySet: Set<Weekdays>) -> [SwiftBMLSDK_Parser.Meeting] {
        guard !inWeekdaySet.isEmpty else { return self }
        return compactMap {
            guard let meetingWeekday = Weekdays(rawValue: $0.weekday) else { return nil }
            return inWeekdaySet.contains(meetingWeekday) ? $0 : nil
        }
    }

    /* ################################################# */
    /**
     Subscript that allows us to filter for a single weekday. This is in the local meeting timezone.
     - parameter inWeekday: The weekday to filter for. This is in the local meeting timezone.
     - returns: Meetings of the specified type.
     */
    subscript(_ inWeekday: Weekdays) -> [SwiftBMLSDK_Parser.Meeting] { self[Set<Weekdays>([inWeekday])] }

    /* ################################################# */
    /**
     Subscript that allows us to filter for meetings that start within a certain time range. This is in the local meeting timezone.
     
     - parameter inStartTimeRangeInSecondsFromMidnight: A half-open range of seconds from midnight within 0..<86400. Use `Range<TimeInterval>` (for example, `32400.0..<43200.0`); an integer range selects the standard array-index subscript.
     - returns: Meetings of the specified type.
     */
    subscript(_ inStartTimeRangeInSecondsFromMidnight: Range<TimeInterval>) -> [SwiftBMLSDK_Parser.Meeting] {
        guard 0 <= inStartTimeRangeInSecondsFromMidnight.lowerBound,
              86400 >= inStartTimeRangeInSecondsFromMidnight.upperBound
        else { return [] }
        return compactMap { inStartTimeRangeInSecondsFromMidnight.contains($0.startTimeInSecondsFromMidnight) ? $0 : nil }
    }

    /* ################################################# */
    /**
     This returns the entire meeting list as a simple, 2-dimensional, JSON Data instance. The data is a simple sequence of single-dimension dictionaries.
     
     This is different from the input JSON, as it has the organization and "cleaning" provided by the parser. It also keeps it at 2 dimensions, for easy integration into ML stuff.
     */
    var asJSONData: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(self)
    }
    
    /* ################################################# */
    /**
     A region that encloses all meetings with valid physical coordinates.
     
     Meetings without coordinates are ignored.
     
     Returns nil only when there are no valid coordinates. Each span is at least 0.05 degrees, including duplicate or collinear locations. Longitude bounds use the shortest arc across the date line.
     */
    var mapRegion: MKCoordinateRegion? {
        let coordinates = compactMap { $0.coords }.filter { CLLocationCoordinate2DIsValid($0) }
        
        guard !coordinates.isEmpty else { return nil }
        
        if 1 == coordinates.count,
           let coordinate = coordinates.first {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.05,
                    longitudeDelta: 0.05
                )
            )
        }
        
        let minLatitude = coordinates.map(\.latitude).min() ?? 0
        let maxLatitude = coordinates.map(\.latitude).max() ?? 0
        let longitudes = coordinates.map { $0.longitude < 0 ? $0.longitude + 360 : $0.longitude }.sorted()
        var largestGap = -Double.infinity
        var arcStart = longitudes[0]
        for index in longitudes.indices {
            let next = (index + 1) % longitudes.count
            let gap = longitudes[next] + (next == 0 ? 360 : 0) - longitudes[index]
            if gap > largestGap {
                largestGap = gap
                arcStart = longitudes[next]
            }
        }
        let longitudeDelta = 360 - largestGap
        var centerLongitude = (arcStart + longitudeDelta / 2).truncatingRemainder(dividingBy: 360)
        if centerLongitude > 180 { centerLongitude -= 360 }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: Swift.max(maxLatitude - minLatitude, 0.05),
                                   longitudeDelta: Swift.max(longitudeDelta, 0.05))
        )
    }
}

/* ###################################################################################################################################### */
// MARK: - Parser Extensions -
/* ###################################################################################################################################### */
/**
 This extension adds some basic filtering and conversion options to the parser.
 */
public extension SwiftBMLSDK_Parser {
    /* ################################################# */
    /**
     Returns meetings that have an in-person component.
     */
    var inPersonMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.inPerson(isExclusive: false)] }
    
    /* ################################################# */
    /**
     Returns meetings that are only in-person.
     */
    var inPersonOnlyMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.inPerson(isExclusive: true)] }

    /* ################################################# */
    /**
     Returns meetings that have a virtual component.
     */
    var virtualMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.virtual(isExclusive: false)] }

    /* ################################################# */
    /**
     Returns meetings that are only virtual.
     */
    var virtualOnlyMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.virtual(isExclusive: true)] }

    /* ################################################# */
    /**
     Returns meetings that are only hybrid.
     */
    var hybridMeetings: [Meeting] { meetings[SwiftBMLSDK_Query.SearchSpecification.SearchForMeetingType.hybrid] }
}
