//
//  NewTodayView.swift
//  cashExpense
//
//  New Today view with full-screen layout
//

import SwiftUI
import SwiftData

struct NewTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    
    @Query private var todayExpenses: [Expense]
    @Query private var monthExpenses: [Expense]
    @Query private var recentExpensesQuery: [Expense]
    
    @State private var showingAdd = false
    @State private var editingExpense: Expense?
    
    private var config: AppConfig? { configs.first }
    
    private var categoryById: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
    
    init(now: Date = .now) {
        let cal = Calendar.current
        let todayStart = DateUtils.startOfDay(now, calendar: cal)
        let tomorrowStart = cal.date(byAdding: .day, value: 1, to: todayStart) ?? now
        
        let monthStart = DateUtils.startOfMonth(now, calendar: cal)
        let nextMonthStart = DateUtils.startOfNextMonth(now, calendar: cal)
        
        _todayExpenses = Query(
            filter: #Predicate<Expense> {
                $0.isDeleted == false &&
                $0.dateSpent >= todayStart &&
                $0.dateSpent < tomorrowStart
            },
            sort: \Expense.dateSpent,
            order: .reverse
        )
        
        _monthExpenses = Query(
            filter: #Predicate<Expense> {
                $0.isDeleted == false &&
                $0.dateSpent >= monthStart &&
                $0.dateSpent < nextMonthStart
            },
            sort: \Expense.dateSpent,
            order: .reverse
        )
        
        _recentExpensesQuery = Query(
            filter: #Predicate<Expense> { $0.isDeleted == false },
            sort: \Expense.dateSpent,
            order: .reverse
        )
    }
    
    private var todayTotal: Decimal {
        MoneyUtils.roundedCurrency(todayExpenses.reduce(Decimal.zero) { $0 + $1.amount })
    }
    
    private var monthTotal: Decimal {
        MoneyUtils.roundedCurrency(monthExpenses.reduce(Decimal.zero) { $0 + $1.amount })
    }
    
    private var currencyCode: String {
        config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD")
    }
    
    private var recentExpenses: [Expense] { Array(recentExpensesQuery.prefix(20)) }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Today")
                                .font(.headline)
                            Text(MoneyUtils.format(todayTotal, currencyCode: currencyCode))
                                .font(.largeTitle.weight(.bold))
                                .accessibilityLabel("Today total \(MoneyUtils.format(todayTotal, currencyCode: currencyCode))")
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("This month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(MoneyUtils.format(monthTotal, currencyCode: currencyCode))
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("This month total \(MoneyUtils.format(monthTotal, currencyCode: currencyCode))")
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Quick Add", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Add expense")
                }
                
                // Empty state - only show if no expenses exist at all
                if recentExpenses.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No expenses yet")
                                .font(.headline)
                            Text("Tap Quick Add to record your first cash expense.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                
                Section("Recent") {
                    if recentExpenses.isEmpty {
                        EmptyView()
                    } else {
                        ForEach(recentExpenses) { expense in
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
                        }
                    }
                }
            }
            .navigationTitle("Cash Expense")
            .sheet(isPresented: $showingAdd) {
                AddEditExpenseView(mode: .add, onDone: {
                    toastManager.show("Saved")
                })
            }
            .sheet(item: $editingExpense) { exp in
                AddEditExpenseView(mode: .edit(exp), onDone: {
                    toastManager.show("Saved")
                })
            }
        }
    }
    
    private func delete(_ expense: Expense) {
        withAnimation {
            expense.isDeleted = true
            expense.updatedAt = Date()
        }
    }
}
