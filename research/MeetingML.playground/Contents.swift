import Foundation
import CreateML
import TabularData

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

func createTextClassifierModelFile(file inFileSize: String = "small") {
    if let results = loadJSON(file: inFileSize) {
        print("Training Day!")
        if let classifier = try? MLTextClassifier(trainingData: results.meetings.taggedStringData),
           let modelURL = URL(string: "~/Desktop/SwiftBMLSDK_Classifier.mlmodel") {
            let metadata = MLModelMetadata(author: "SwiftBMLSDK_Classifier", shortDescription: "NA Meetings", license: "", version: "1.0")
            print("Get to Work! (\(modelURL))")
            do {
                try classifier.write(toFile: modelURL.absoluteString, metadata: metadata)
            } catch {
                print("ERROR: \(error)")
            }
        }
    }
}

if let results = loadJSON(file: "small") {
    let outputURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent("SwiftBMLSDK_Meetings.json")
    do {
        print("Extracting Data")
        if let jsonData = results.meetings.jsonData {
            print("Writing the File")
            try jsonData.write(to: outputURL)
            print("Creating Regressor")
            let data = try DataFrame(jsonData: jsonData)
            print("Training Day!")
            let regressor = try MLLinearRegressor(trainingData: data, targetColumn: "id")
            print("Done!")
        }
    } catch {
        print("ERROR: \(error)")
    }
}
