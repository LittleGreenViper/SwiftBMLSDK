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
     */
    @IBOutlet weak var mlTypeSwitch: UISegmentedControl?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var goButton: UIButton?
    
    /* ################################################################## */
    /**
     */
    @IBAction func goButtonHit(_: Any) {
        throbberView?.isHidden = false
        let metaData = MLModelMetadata(author: "LGV", shortDescription: "Meeting Data Model", version: "1.0")
        
        switch mlTypeSwitch?.selectedSegmentIndex ?? 0 {
        case 0:
            makeTextClassifier(meta: metaData) { self.throbberView?.isHidden = true }

        default:
            makeRegressor(meta: metaData) { self.throbberView?.isHidden = true }
        }
    }
    
    /* ################################################################## */
    /**
     The "busy throbber" view.
     */
    @IBOutlet weak var throbberView: UIView?
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
        goButton?.setTitle(goButton?.title(for: .normal)?.localizedVariant, for: .normal)
        for index in 0..<(mlTypeSwitch?.numberOfSegments ?? 0) {
            mlTypeSwitch?.setTitle(mlTypeSwitch?.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MLWorkshopViewController {
    /* ################################################################## */
    /**
     */
    func makeTextClassifier(meta inMeta: MLModelMetadata, completion inCompletion: @escaping () -> Void) {
        DispatchQueue.global().async {
            guard let resultJSON = self.prefs.searchResults?.textProcessorJSONData,
                  let dataFrame = try? DataFrame(jsonData: resultJSON),
                  let classifier = try? MLTextClassifier(trainingData: dataFrame, textColumn: "summary", labelColumn: "type") else {
                DispatchQueue.main.async { inCompletion() }
                return
            }
            try? classifier.write(to: URL.documentsDirectory.appending(path: "TextClassifier.mlmodel"), metadata: inMeta)
            #if DEBUG
                print("Saved classifier model to \(URL.documentsDirectory.absoluteString)TextClassifier.mlmodel")
            #endif
            DispatchQueue.main.async { inCompletion() }
        }
    }

    /* ################################################################## */
    /**
     */
    func makeRegressor(meta inMeta: MLModelMetadata, completion inCompletion: @escaping () -> Void) {
        DispatchQueue.global().async {
            guard let resultJSON = self.prefs.searchResults?.textProcessorJSONData,
                  let dataFrame = try? DataFrame(jsonData: resultJSON),
                  let regressor = try? MLRandomForestRegressor(trainingData: dataFrame, targetColumn: "id", featureColumns: ["summary", "type"]) else {
                DispatchQueue.main.async { inCompletion() }
                return
            }
            try? regressor.write(to: URL.documentsDirectory.appending(path: "Regressor.mlmodel"), metadata: inMeta)
            #if DEBUG
                print("Saved regressor model to \(URL.documentsDirectory.absoluteString)Regressor.mlmodel")
            #endif
            DispatchQueue.main.async { inCompletion() }
        }
    }
}

