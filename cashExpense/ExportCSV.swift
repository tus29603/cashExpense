//
//  ExportCSV.swift
//  cashExpense
//

import Foundation

enum CSVExport {
    static func makeCSV(
        expenses: [Expense],
        categoriesById: [UUID: Category],
        currencyCode: String,
        start: Date,
        end: Date
    ) -> String {
        let header = "dateSpent,amount,currency,category,note,createdAt\n"
        
        let rows: [String] = expenses
            .filter { $0.isDeleted == false && $0.dateSpent >= start && $0.dateSpent < end }
            .sorted(by: { $0.dateSpent < $1.dateSpent })
            .map { e in
                let dateSpent = e.dateSpent.ISO8601Format()
                let amount = NSDecimalNumber(decimal: MoneyUtils.roundedCurrency(e.amount)).stringValue
                let currency = currencyCode
                let category = categoriesById[e.categoryId]?.name ?? "Unknown"
                let note = e.note ?? ""
                let createdAt = e.createdAt.ISO8601Format()
                
                return [
                    csvEscape(dateSpent),
                    csvEscape(amount),
                    csvEscape(currency),
                    csvEscape(category),
                    csvEscape(note),
                    csvEscape(createdAt),
                ].joined(separator: ",")
            }
        
        return header + rows.joined(separator: "\n") + (rows.isEmpty ? "" : "\n")
    }
    
    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}


