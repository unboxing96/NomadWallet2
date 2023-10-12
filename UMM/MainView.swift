//
//  MainView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            TravelListView()
                .tabItem {
                    Label("여행 관리", systemImage: "person.crop.circle.fill")
                }
            RecordView()
                .tabItem {
                    Label("", systemImage: "mic")
                }
            ExpenseView()
                .tabItem {
                    Label("지출 관리", systemImage: "tray.and.arrow.down.fill")
                }
        }
    }
}

#Preview {
    MainView()
}
