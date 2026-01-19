//
//  cashExpenseApp.swift
//  cashExpense
//
//  Created by Tesfaldet Haileab on 1/7/26.
//

import SwiftUI
import SwiftData

#if os(iOS)
import GoogleMobileAds
#endif

@main
struct cashExpenseApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject private var lockManager = LockManager()
    
    init() {
        #if os(iOS)
        // Initialize Google Mobile Ads SDK once on app launch
        MobileAds.shared.start(completionHandler: nil)
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            Category.self,
            AppConfig.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(toastManager)
                .environmentObject(lockManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
