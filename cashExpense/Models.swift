//
//  Models.swift
//  cashExpense
//
//  Offline-first models (SwiftData)
//

import Foundation
import SwiftData

enum WeekStart: Int, CaseIterable, Identifiable {
    case monday = 1
    case sunday = 0
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .monday: return "Monday"
        case .sunday: return "Sunday"
        }
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var currencyCode: String
    var categoryId: UUID
    var note: String?
    var dateSpent: Date
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        currencyCode: String,
        categoryId: UUID,
        note: String? = nil,
        dateSpent: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.note = note
        self.dateSpent = dateSpent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorKey: String
    var sortOrder: Int
    var isDefault: Bool
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorKey: String,
        sortOrder: Int,
        isDefault: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorKey = colorKey
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.isArchived = isArchived
    }
}

@Model
final class AppConfig {
    @Attribute(.unique) var id: UUID
    
    var selectedCurrencyCode: String
    var weekStartRaw: Int
    var defaultCategoryId: UUID?
    
    /// Stub for v1.x (StoreKit entitlements later)
    var hasPro: Bool
    
    var isAppLockEnabled: Bool
    var hasSeenOnboarding: Bool
    var lastExportAt: Date?
    
    var createdAt: Date
    var updatedAt: Date
    
    var weekStart: WeekStart {
        get { WeekStart(rawValue: weekStartRaw) ?? .monday }
        set { weekStartRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        selectedCurrencyCode: String = Locale.current.currency?.identifier ?? "USD",
        weekStart: WeekStart = .monday,
        defaultCategoryId: UUID? = nil,
        hasPro: Bool = false,
        isAppLockEnabled: Bool = false,
        hasSeenOnboarding: Bool = false,
        lastExportAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.selectedCurrencyCode = selectedCurrencyCode
        self.weekStartRaw = weekStart.rawValue
        self.defaultCategoryId = defaultCategoryId
        self.hasPro = hasPro
        self.isAppLockEnabled = isAppLockEnabled
        self.hasSeenOnboarding = hasSeenOnboarding
        self.lastExportAt = lastExportAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}



