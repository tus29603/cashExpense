//
//  SeedData.swift
//  cashExpense
//

import Foundation
import SwiftData

enum SeedData {
    // Stable IDs so we don't accidentally duplicate defaults.
    static let foodId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let transportId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let groceriesId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let rentId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let billsId = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let shoppingId = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    static let healthId = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    static let entertainmentId = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
    static let coffeeId = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
    static let otherId = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    
    static func ensureSeeded(modelContext: ModelContext) {
        do {
            let categoriesCount = try modelContext.fetchCount(FetchDescriptor<Category>())
            if categoriesCount == 0 {
                let defaults: [Category] = [
                    Category(id: foodId, name: "Food", icon: "fork.knife", colorKey: "red", sortOrder: 0, isDefault: true),
                    Category(id: transportId, name: "Transport", icon: "car.fill", colorKey: "blue", sortOrder: 1, isDefault: true),
                    Category(id: groceriesId, name: "Groceries", icon: "cart.fill", colorKey: "green", sortOrder: 2, isDefault: true),
                    Category(id: rentId, name: "Rent", icon: "house.fill", colorKey: "indigo", sortOrder: 3, isDefault: true),
                    Category(id: billsId, name: "Bills", icon: "doc.text.fill", colorKey: "orange", sortOrder: 4, isDefault: true),
                    Category(id: shoppingId, name: "Shopping", icon: "bag.fill", colorKey: "pink", sortOrder: 5, isDefault: true),
                    Category(id: healthId, name: "Health", icon: "cross.case.fill", colorKey: "teal", sortOrder: 6, isDefault: true),
                    Category(id: entertainmentId, name: "Entertainment", icon: "gamecontroller.fill", colorKey: "purple", sortOrder: 7, isDefault: true),
                    Category(id: coffeeId, name: "Coffee", icon: "cup.and.saucer.fill", colorKey: "brown", sortOrder: 8, isDefault: true),
                    Category(id: otherId, name: "Other", icon: "square.grid.2x2.fill", colorKey: "gray", sortOrder: 9, isDefault: true),
                ]
                for c in defaults { modelContext.insert(c) }
            }
            
            let configCount = try modelContext.fetchCount(FetchDescriptor<AppConfig>())
            if configCount == 0 {
                // Auto-detect currency from device locale (fallback to USD)
                let deviceCurrency = Locale.current.currency?.identifier ?? "USD"
                let config = AppConfig(selectedCurrencyCode: deviceCurrency, defaultCategoryId: otherId)
                modelContext.insert(config)
            }
        } catch {
            // If seeding fails, the app can still run; we avoid crashing on launch.
            // The UI will show an empty state.
            print("SeedData error: \(error)")
        }
    }
}


