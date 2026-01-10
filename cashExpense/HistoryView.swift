//
//  HistoryView.swift
//  cashExpense

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    @Query(
        filter: #Predicate<Expense> { $0.isDeleted == false },
        sort: \Expense.dateSpent,
        order: .reverse
    )
    private var allActiveExpenses: [Expense]
    
    @State private var searchText: String = ""
    @State private var editingExpense: Expense?
    @State private var showingAdd = false
    @State private var showingFilters = false
    @State private var rangePreset: HistoryRangePreset = .thisMonth
    @State private var customStart: Date = DateUtils.startOfMonth(.now)
    @State private var customEnd: Date = DateUtils.startOfNextMonth(.now)
    @State private var selectedCategoryIds: Set<UUID> = []
    
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif
    @State private var selection = Set<PersistentIdentifier>()
    
    private var config: AppConfig? { configs.first }
    private var currencyCode: String { config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD") }
    
    private var categoryById: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    
    private var dateRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch rangePreset {
        case .thisWeek:
            let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? DateUtils.startOfDay(now)
            let end = cal.date(byAdding: .day, value: 7, to: start) ?? now
            return (start, end)
        case .thisMonth:
            let start = DateUtils.startOfMonth(now, calendar: cal)
            let end = DateUtils.startOfNextMonth(now, calendar: cal)
            return (start, end)
        case .custom:
            return (customStart, max(customEnd, customStart.addingTimeInterval(60)))
        }
    }
    
    private var filtered: [Expense] {
        let s = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return allActiveExpenses.filter { e in
            guard e.dateSpent >= dateRange.start && e.dateSpent < dateRange.end else { return false }
            if !selectedCategoryIds.isEmpty, !selectedCategoryIds.contains(e.categoryId) { return false }
            if s.isEmpty { return true }
            let note = (e.note ?? "").lowercased()
            let catName = categoryById[e.categoryId]?.name.lowercased() ?? ""
            return note.contains(s) || catName.contains(s)
        }
    }
    
    private var groupedByDay: [(day: Date, items: [Expense])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { e in
            cal.startOfDay(for: e.dateSpent)
        }
        return groups
            .map { ($0.key, $0.value.sorted(by: { $0.dateSpent > $1.dateSpent })) }
            .sorted(by: { $0.0 > $1.0 })
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selection) {
                if groupedByDay.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No expenses" : "No expenses found",
                        systemImage: "tray",
                        description: Text(searchText.isEmpty ? "Add your first expense to see history here." : "Try adjusting your search or filters.")
                    )
                    .padding(.vertical, 20)
                } else {
                    ForEach(groupedByDay, id: \.day) { section in
                        Section(header: Text(sectionTitle(section.day))) {
                            ForEach(section.items) { expense in
                                Button {
                                    editingExpense = expense
                                } label: {
                                    ExpenseRowView(
                                        expense: expense,
                                        category: categoryById[expense.categoryId],
                                        currencyCode: currencyCode
                                    )
                                }
                                .buttonStyle(.plain)
                                #if os(iOS)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(expense)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        editingExpense = expense
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                #endif
                                .tag(expense.persistentModelID)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            #if os(iOS)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search notes or category")
            .environment(\.editMode, $editMode)
            #else
            .searchable(text: $searchText, prompt: "Search notes or category")
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add expense")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters")
                }
                
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if editMode == .active {
                        Button(role: .destructive) {
                            bulkDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(selection.isEmpty)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAdd) {
                AddEditExpenseView(mode: .add, onDone: {})
            }
            .sheet(item: $editingExpense) { exp in
                AddEditExpenseView(mode: .edit(exp), onDone: {})
            }
            .sheet(isPresented: $showingFilters) {
                HistoryFiltersView(
                    preset: $rangePreset,
                    customStart: $customStart,
                    customEnd: $customEnd,
                    categories: categories.filter { $0.isArchived == false },
                    selectedCategoryIds: $selectedCategoryIds
                )
            }
        }
    }
    
    private func sectionTitle(_ day: Date) -> String {
        let now = Date()
        if DateUtils.isToday(day, now: now) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func delete(_ expense: Expense) {
        withAnimation {
            expense.isDeleted = true
            expense.updatedAt = Date()
        }
    }
    
    private func bulkDelete() {
        guard !selection.isEmpty else { return }
        let ids = selection
        selection.removeAll()
        
        // Soft delete selected expenses
        withAnimation {
            for e in allActiveExpenses {
                if ids.contains(e.persistentModelID) {
                    e.isDeleted = true
                    e.updatedAt = Date()
                }
            }
        }
        toastManager.show("Deleted")
        #if os(iOS)
        editMode = .inactive
        #endif
    }
}

enum HistoryRangePreset: String, CaseIterable, Identifiable {
    case thisWeek
    case thisMonth
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .thisWeek: return "This week"
        case .thisMonth: return "This month"
        case .custom: return "Custom"
        }
    }
}

struct HistoryFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var preset: HistoryRangePreset
    @Binding var customStart: Date
    @Binding var customEnd: Date
    let categories: [Category]
    @Binding var selectedCategoryIds: Set<UUID>
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date range") {
                    Picker("Range", selection: $preset) {
                        ForEach(HistoryRangePreset.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    if preset == .custom {
                        DatePicker("Start", selection: $customStart, displayedComponents: .date)
                        DatePicker("End", selection: $customEnd, displayedComponents: .date)
                    }
                }
                
                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            Button {
                                if selectedCategoryIds.contains(category.id) {
                                    selectedCategoryIds.remove(category.id)
                                } else {
                                    selectedCategoryIds.insert(category.id)
                                }
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(CategoryColor.subtleBackground(for: category.colorKey))
                                            .frame(width: 24, height: 24)
                                        Image(systemName: category.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(category.accentColor)
                                    }
                                    Text(category.name)
                                    Spacer()
                                    if selectedCategoryIds.contains(category.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(category.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button("Clear selection") {
                            selectedCategoryIds.removeAll()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
