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

import SwiftUI
import RVS_Generic_Swift_Toolbox
import CoreLocation

/* ###################################################################################################################################### */
// MARK: - Meeting Search View -
/* ###################################################################################################################################### */
/**
 */
struct SwiftMLSDK_SearchView: View {
    @State private var _latitudeStr: String = ""
    @State private var _longitudeStr: String = ""
    @State private var _radiusStr: String = ""
    @State private var _locationSearch = false

    /* ################################################# */
    /**
     */
    var body: some View {
        NavigationStack {
            Form {
                Section("SLUG-TAB-0-LOCATION-SECTION".localizedVariant) {
                    Toggle("SLUG-TAB-0-LOCATION-TOGGLE".localizedVariant, isOn: $_locationSearch.animation())
                    if _locationSearch {
                        TextField("SLUG-TAB-0-LOCATION-LAT".localizedVariant, text: $_latitudeStr, prompt: Text("SLUG-TAB-0-LOCATION-PL-LAT".localizedVariant))
                        TextField("SLUG-TAB-0-LOCATION-LNG".localizedVariant, text: $_longitudeStr, prompt: Text("SLUG-TAB-0-LOCATION-PL-LNG".localizedVariant))
                        TextField("SLUG-TAB-0-LOCATION-DST".localizedVariant, text: $_radiusStr, prompt: Text("SLUG-TAB-0-LOCATION-PL-DST".localizedVariant))
                    }
                }
            }
        }
    }
}

/* ##################################################### */
/**
 Just the preview generator.
 */
#Preview {
    SwiftMLSDK_SearchView()
}
