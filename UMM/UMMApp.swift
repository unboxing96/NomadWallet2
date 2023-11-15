//
//  UMMApp.swift
//  UMM
//
//  Created by Wonil Lee on 10/5/23.
//

import SwiftUI

@main
struct UMMApp: App {
    let tempSave = TempSave.shared
    let numberFormatterHandler = NumberFormatterHandler.shared
    
    var body: some Scene {
        WindowGroup {
//            MainView()
            SplashView()
//            TestView()
        }
    }
}
