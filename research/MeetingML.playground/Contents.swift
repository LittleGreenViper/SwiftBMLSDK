import Foundation
import CreateML
@available(macOS 13.0, *)

func loadJSON() -> (meta: MeetingJSONParser.PageMeta, meetings: [MeetingJSONParser.Meeting])? {
    guard let jsonFileURL = Bundle.main.url(forResource: "all-meetings", withExtension: "json"),
          let jsonData = try? Data(contentsOf: jsonFileURL),
          let parser = MeetingJSONParser(jsonData: jsonData)
    else { return nil }
    
    return (meta: parser.meta, meetings: parser.meetings)
}

if let results = loadJSON(),
    let mlDataTable = try? MLDataTable(dictionary: results.meetings.taggedData) {
    print(mlDataTable)
}
//
//let classifier = try MLTextClassifier(trainingData: dataFrame, textColumn: "text", labelColumn: "sentiment")
//
//let metaData = MLModelMetadata(author: "Mohammad Azam", shortDescription: "Predicts the sentiments associated with financial news", version: "1.0")
//
//try classifier.write(toFile: "~/Desktop/FinancialNewsSentimentAnalysis.mlmodel", metadata: metaData)

