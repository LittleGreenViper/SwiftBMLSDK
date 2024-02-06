import Foundation
import CreateML

@available(macOS 13.0, *)

func loadJSON(file inFileSize: String) -> (meta: MeetingJSONParser.PageMeta, meetings: [MeetingJSONParser.Meeting])? {
    print("Getting File")
    guard let jsonFileURL = Bundle.main.url(forResource: "\(inFileSize)-dump", withExtension: "json") else { return nil }
    print("Extracting Data")
    guard let jsonData = try? Data(contentsOf: jsonFileURL) else { return nil }
    print("Parsing Data")
    guard let parser = MeetingJSONParser(jsonData: jsonData as Data) else { return nil }
    
    return (meta: parser.meta, meetings: parser.meetings)
}

func createModelFile(file inFileSize: String = "small") {
    if let results = loadJSON(file: inFileSize) {
        print("Training Day!")
        if let classifier = try? MLTextClassifier(trainingData: results.meetings.taggedStringData),
           let modelURL = URL(string: "~/Desktop/NAMeetings.mlmodel") {
            let metadata = MLModelMetadata(author: "BMLSDK", shortDescription: "NA Meetings", license: "", version: "1.0")
            print("Get to Work! (\(modelURL))")
            do {
                try classifier.write(toFile: modelURL.absoluteString, metadata: metadata)
            } catch {
                print("ERROR: \(error)")
            }
        }
    }
}

createModelFile(file: "large")
exit
