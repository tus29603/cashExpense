//
//  NewRootView.swift
//  cashExpense
//
//  New root view with clean full-screen layout
//

import SwiftUI

struct NewRootView: View {
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                NewTodayView()
                    .tabItem { Label("Today", systemImage: "house.fill") }
                
                NewHistoryView()
                    .tabItem { Label("History", systemImage: "list.bullet") }
                
                NewSummaryView()
                    .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
                
                NewSettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            
            #if os(iOS)
            AdBannerView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            #endif
        }
    }
}
