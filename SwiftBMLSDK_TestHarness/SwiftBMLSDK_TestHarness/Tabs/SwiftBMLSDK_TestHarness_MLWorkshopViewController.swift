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

import UIKit
import RVS_Generic_Swift_Toolbox
import CreateML
import TabularData

/* ###################################################################################################################################### */
// MARK: - Text Processor Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 */
class SwiftBMLSDK_TestHarness_MLWorkshopViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     The "busy throbber" view.
     */
    @IBOutlet weak var throbberView: UIView?
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MLWorkshopViewController {
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MLWorkshopViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        throbberView?.isHidden = false
    }
    
    /* ################################################################## */
    /**
     Called when the view has appeared.
     
     - parameter inIsAnimated: True, if the appearance was animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        guard let resultJSON = prefs.searchResults?.textProcessorJSONData else { return }
        do {
            #if DEBUG
                try? resultJSON.write(to: URL.documentsDirectory.appending(path:  "textProcessor.json"))
                print("Processor Data Saved to \(URL.documentsDirectory.absoluteString)textProcessor.json")
            #endif
            let dataFrame = try DataFrame(jsonData: resultJSON)
            let metaData = MLModelMetadata(author: "LGV", shortDescription: "Meeting Data Model", version: "1.0")
            var regressor: MLLinearRegressor? = try MLLinearRegressor(trainingData: dataFrame, targetColumn: "id", featureColumns: ["summary", "type"])
            try regressor?.write(to: URL.documentsDirectory.appending(path: "Regressor.mlmodel"), metadata: metaData)
            #if DEBUG
                print("Saved regressor model to \(URL.documentsDirectory.absoluteString)Regressor.mlmodel")
            #endif
            regressor = nil
            var classifier: MLTextClassifier? = try MLTextClassifier(trainingData: dataFrame, textColumn: "summary", labelColumn: "type")
            try classifier?.write(to: URL.documentsDirectory.appending(path: "TextClassifier.mlmodel"), metadata: metaData)
            #if DEBUG
                print("Saved classifier model to \(URL.documentsDirectory.absoluteString)TextClassifier.mlmodel")
            #endif
            classifier = nil
            throbberView?.isHidden = true
        } catch {
            print(error.localizedDescription)
        }
    }
}

