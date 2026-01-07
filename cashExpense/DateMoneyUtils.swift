//
//  DateMoneyUtils.swift
//  cashExpense
//

import Foundation

enum DateUtils {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }
    
    static func startOfNextMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        let start = startOfMonth(date, calendar: calendar)
        return calendar.date(byAdding: .month, value: 1, to: start) ?? start
    }
    
    static func isToday(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }
    
    static func isYesterday(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        calendar.isDateInYesterday(date) && !calendar.isDate(date, inSameDayAs: now)
    }
}

enum MoneyUtils {
    static func roundedCurrency(_ value: Decimal, scale: Int = 2) -> Decimal {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, scale, .bankers)
        return result
    }
    
    static func format(_ value: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
    
    static func parseDecimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        
        // Allow both "," and "." as decimal separators.
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }
}


