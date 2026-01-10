//
//  ExportCSVView.swift
//  cashExpense
//

import SwiftUI
import SwiftData

struct ExportCSVView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
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
    
    @State private var showingShare = false
    @State private var exportText: String = ""
    
    private var config: AppConfig? { configs.first }
    private var currencyCode: String { config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD") }
    private var categoryById: [UUID: Category] { Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) }) }
    
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Range") {
                    Picker("Preset", selection: $preset) {
                        ForEach(DateRangePreset.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    if preset == .custom {
                        DatePicker("Start", selection: $customStart, displayedComponents: .date)
                        DatePicker("End", selection: $customEnd, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button("Generate & Share CSV") {
                        exportText = CSVExport.makeCSV(
                            expenses: allActiveExpenses,
                            categoriesById: categoryById,
                            currencyCode: currencyCode,
                            start: range.start,
                            end: range.end
                        )
                        config?.lastExportAt = Date()
                        config?.updatedAt = Date()
                        showingShare = true
                    }
                }
                
                Section("Preview") {
                    Text(exportText.isEmpty ? "Tap Generate to preview." : exportText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(8)
                }
            }
            .navigationTitle("Export CSV")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShare) {
                ActivityShareView(items: [exportText])
            }
            .onAppear {
                SeedData.ensureSeeded(modelContext: modelContext)
            }
        }
    }
}


