//
//  RootTabView.swift
//  cashExpense
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "house.fill") }
            
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
            
            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}



