import Foundation
import CreateML

@available(macOS 13.0, *)

func loadJSON() -> (meta: MeetingJSONParser.PageMeta, meetings: [MeetingJSONParser.Meeting])? {
    print("Getting File")
    guard let jsonFileURL = Bundle.main.url(forResource: "large-dump", withExtension: "json") else { return nil }
    print("Extracting Data")
    guard let jsonData = try? Data(contentsOf: jsonFileURL) else { return nil }
    print("Parsing Data")
    guard let parser = MeetingJSONParser(jsonData: jsonData as Data) else { return nil }
    
    return (meta: parser.meta, meetings: parser.meetings)
}

if let results = loadJSON() {
    print("Training Day!")
    if let classifier = try? MLTextClassifier(trainingData: results.meetings.taggedStringData) {
        print(classifier)
    }
}

