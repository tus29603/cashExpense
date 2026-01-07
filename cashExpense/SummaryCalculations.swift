//
//  SummaryCalculations.swift
//  cashExpense
//

import Foundation

enum DateRangePreset: String, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .thisMonth: return "This month"
        case .lastMonth: return "Last month"
        case .custom: return "Custom"
        }
    }
}

struct SummaryResult {
    let total: Decimal
    let avgPerDay: Decimal
    let highestDayTotal: Decimal
    let highestDay: Date?
    let categoryTotals: [(categoryId: UUID, total: Decimal)]
    let dailyTotals: [(day: Date, total: Decimal)]
}

enum ExpenseCalculations {
    static func summarize(
        expenses: [Expense],
        start: Date,
        end: Date,
        calendar: Calendar = .current
    ) -> SummaryResult {
        let inRange = expenses.filter { e in
            e.isDeleted == false && e.dateSpent >= start && e.dateSpent < end
        }
        
        let total = MoneyUtils.roundedCurrency(inRange.reduce(Decimal.zero) { $0 + $1.amount })
        
        // Daily totals
        let byDay = Dictionary(grouping: inRange) { e in
            calendar.startOfDay(for: e.dateSpent)
        }.mapValues { items in
            MoneyUtils.roundedCurrency(items.reduce(Decimal.zero) { $0 + $1.amount })
        }
        
        let daily = byDay
            .map { (day: $0.key, total: $0.value) }
            .sorted(by: { $0.day < $1.day })
        
        let (highestDay, highestTotal) = daily.max(by: { $0.total < $1.total }).map { ($0.day, $0.total) } ?? (nil, Decimal.zero)
        
        // Avg/day
        let dayCount = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 1)
        let avg = MoneyUtils.roundedCurrency(total / Decimal(dayCount))
        
        // Category totals
        let byCategory = Dictionary(grouping: inRange, by: { $0.categoryId })
            .mapValues { items in MoneyUtils.roundedCurrency(items.reduce(Decimal.zero) { $0 + $1.amount }) }
        
        let categoryTotals = byCategory
            .map { (categoryId: $0.key, total: $0.value) }
            .sorted(by: { $0.total > $1.total })
        
        return SummaryResult(
            total: total,
            avgPerDay: avg,
            highestDayTotal: highestTotal,
            highestDay: highestDay,
            categoryTotals: categoryTotals,
            dailyTotals: daily
        )
    }
}


