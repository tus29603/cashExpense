//
//  cashExpenseApp.swift
//  cashExpense
//
//  Created by Tesfaldet Haileab on 1/7/26.
//

import SwiftUI
import SwiftData

@main
struct cashExpenseApp: App {
    @StateObject private var toastManager = ToastManager()
    @StateObject private var lockManager = LockManager()
    
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
