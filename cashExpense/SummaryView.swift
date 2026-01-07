//
//  SummaryView.swift
//  cashExpense
//

import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    @Query(
        filter: #Predicate<Expense> { $0.isDeleted == false },
        sort: \Expense.dateSpent,
        order: .reverse
    )
    private var allActiveExpenses: [Expense]
    
    @State private var preset: DateRangePreset = .thisMonth
    @State private var customStart: Date = DateUtils.startOfMonth(.now)
    @State private var customEnd: Date = DateUtils.startOfNextMonth(.now)
    
    private var config: AppConfig? { configs.first }
    private var currencyCode: String { config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD") }
    
    private var categoryById: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    
    private var range: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch preset {
        case .thisMonth:
            let start = DateUtils.startOfMonth(now, calendar: cal)
            let end = DateUtils.startOfNextMonth(now, calendar: cal)
            return (start, end)
        case .lastMonth:
            let thisStart = DateUtils.startOfMonth(now, calendar: cal)
            let lastStart = cal.date(byAdding: .month, value: -1, to: thisStart) ?? thisStart
            return (lastStart, thisStart)
        case .custom:
            return (customStart, max(customEnd, customStart.addingTimeInterval(60)))
        }
    }
    
    private var summary: SummaryResult {
        ExpenseCalculations.summarize(expenses: allActiveExpenses, start: range.start, end: range.end)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $preset) {
                        ForEach(DateRangePreset.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if preset == .custom {
                        DatePicker("Start", selection: $customStart, displayedComponents: .date)
                        DatePicker("End", selection: $customEnd, displayedComponents: .date)
                    }
                }
                
                Section("Summary") {
                    SummaryCard(title: "Total", value: MoneyUtils.format(summary.total, currencyCode: currencyCode))
                    SummaryCard(title: "Avg / day", value: MoneyUtils.format(summary.avgPerDay, currencyCode: currencyCode))
                    SummaryCard(
                        title: "Highest day",
                        value: MoneyUtils.format(summary.highestDayTotal, currencyCode: currencyCode),
                        subtitle: summary.highestDay.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—"
                    )
                }
                
                Section("Daily spend") {
                    if summary.dailyTotals.isEmpty {
                        Text("No data for this range.")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart {
                            ForEach(summary.dailyTotals, id: \.day) { entry in
                                BarMark(
                                    x: .value("Day", entry.day, unit: .day),
                                    y: .value("Total", NSDecimalNumber(decimal: entry.total).doubleValue)
                                )
                                .foregroundStyle(Color.accentColor.gradient)
                            }
                        }
                        .frame(height: 140)
                    }
                }
                
                Section("Category breakdown") {
                    if summary.categoryTotals.isEmpty {
                        Text("No data for this range.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(summary.categoryTotals, id: \.categoryId) { row in
                            let pct: String = {
                                if summary.total == 0 { return "0%" }
                                let ratio = (NSDecimalNumber(decimal: row.total).doubleValue) / max(0.000001, NSDecimalNumber(decimal: summary.total).doubleValue)
                                return NumberFormatter.percent.string(from: NSNumber(value: ratio)) ?? "—"
                            }()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(categoryById[row.categoryId]?.name ?? "Unknown")
                                        .font(.headline)
                                    Text(pct)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(MoneyUtils.format(row.total, currencyCode: currencyCode))
                                    .font(.headline)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private extension NumberFormatter {
    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 0
        return f
    }()
}


