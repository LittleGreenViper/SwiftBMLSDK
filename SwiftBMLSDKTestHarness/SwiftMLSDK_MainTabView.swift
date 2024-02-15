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

/* ###################################################################################################################################### */
// MARK: - Main App Tab View -
/* ###################################################################################################################################### */
/**
 This view comprises the main app structure.
 
 The app is a tabbed app, with each tab, providing context.
 */
struct SwiftMLSDK_MainTabView: View {
    /* ################################################# */
    /**
     This ensures that the selected tab is the last one we used.
     */
    @AppStorage("selectedTabIndex") var selectedTabIndex = Tabs.search

    /* ################################################# */
    /**
     These are the enums that denote the various tabs.
     */
    enum Tabs: Int {
        /* ############################################# */
        /**
         Search specification and review.
         */
        case search
        
        /* ############################################# */
        /**
         ML Text Processor.
         */
        case textProcess
    }
    
    /* ################################################# */
    /**
     This provides the main tab bar for the app.
     */
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            // The meeting search specification and review tab.
            SwiftMLSDK_SearchView()
                .tabItem {
                    Label("SLUG-TAB-0", systemImage: "magnifyingglass")
                }
                .tag(Tabs.search)
            
            // The text processor ML tab.
            SwiftMLSDK_TextProcessView()
                .tabItem {
                    Label("SLUG-TAB-1", systemImage: "doc.plaintext")
                }
                .tag(Tabs.textProcess)
        }
    }
}

/* ##################################################### */
/**
 Just the preview generator.
 */
#Preview {
    SwiftMLSDK_MainTabView()
}
