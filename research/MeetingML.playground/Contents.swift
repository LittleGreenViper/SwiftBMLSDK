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

func getDataFrame(from inJSONData: Data) -> DataFrame? {
    let outputURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent("SwiftBMLSDK_Meetings.json")
    do {
        print("Writing the File")
        try inJSONData.write(to: outputURL)
        print("Creating DataFrame")
        return try DataFrame(jsonData: inJSONData)
    } catch {
        print("ERROR: \(error)")
    }
    
    return nil
}

if let results = loadJSON(file: "small") {
    if let jsonData = results.meetings.jsonData,
       let dataFrame = getDataFrame(from: jsonData) {
    }
}
