//
//  AddEditExpenseView.swift
//  cashExpense
//

import SwiftUI
import SwiftData

enum AddEditMode: Identifiable {
    case add
    case edit(Expense)
    
    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let e): return e.id.uuidString
        }
    }
}

struct AddEditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    @Query(filter: #Predicate<Category> { $0.isArchived == false }, sort: \Category.sortOrder, order: .forward)
    private var categories: [Category]
    
    let mode: AddEditMode
    let onDone: () -> Void
    
    @FocusState private var amountFocused: Bool
    @State private var amountText: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var note: String = ""
    @State private var dateSpent: Date = Date()
    
    private var config: AppConfig? { configs.first }
    
    private var currencyCode: String {
        config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD")
    }
    
    private var parsedAmount: Decimal? {
        MoneyUtils.parseDecimal(from: amountText).map { MoneyUtils.roundedCurrency($0) }
    }
    
    private var canSave: Bool {
        guard let parsedAmount else { return false }
        return parsedAmount > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("0.00", text: $amountText)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .font(Font.largeTitle.weight(.bold))
                        .focused($amountFocused)
                        .accessibilityLabel("Amount")
                    
                    Text(currencyCode)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Amount")
                }
                
                Section("Category") {
                    CategoryGrid(
                        categories: categories,
                        selectedCategoryId: $selectedCategoryId
                    )
                    .padding(.vertical, 4)
                }
                
                Section("Details") {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                    
                    DatePicker("Date/Time", selection: $dateSpent, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(modeTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                SeedData.ensureSeeded(modelContext: modelContext)
                hydrateInitialState()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    amountFocused = true
                }
            }
            .onTapGesture {
                amountFocused = false
            }
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .add: return "Add Expense"
        case .edit: return "Edit Expense"
        }
    }
    
    private func hydrateInitialState() {
        switch mode {
        case .add:
            selectedCategoryId = config?.defaultCategoryId ?? SeedData.otherId
            dateSpent = Date()
            note = ""
            amountText = ""
        case .edit(let expense):
            selectedCategoryId = expense.categoryId
            dateSpent = expense.dateSpent
            note = expense.note ?? ""
            amountText = NSDecimalNumber(decimal: MoneyUtils.roundedCurrency(expense.amount)).stringValue
        }
        
        if selectedCategoryId == nil {
            selectedCategoryId = categories.first?.id ?? SeedData.otherId
        }
    }
    
    private func save() {
        guard let amount = parsedAmount, amount > 0 else { return }
        let categoryId = selectedCategoryId ?? SeedData.otherId
        let now = Date()
        
        switch mode {
        case .add:
            let exp = Expense(
                amount: amount,
                currencyCode: currencyCode,
                categoryId: categoryId,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
                dateSpent: dateSpent,
                createdAt: now,
                updatedAt: now,
                isDeleted: false
            )
            modelContext.insert(exp)
        case .edit(let expense):
            expense.amount = amount
            expense.currencyCode = currencyCode
            expense.categoryId = categoryId
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            expense.note = trimmed.isEmpty ? nil : trimmed
            expense.dateSpent = dateSpent
            expense.updatedAt = now
        }
        
        if let config {
            // Helpful default: remember last used category.
            config.defaultCategoryId = categoryId
            config.updatedAt = now
        }
        
        onDone()
        dismiss()
    }
}

struct CategoryGrid: View {
    let categories: [Category]
    @Binding var selectedCategoryId: UUID?
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 92, maximum: 120), spacing: 10, alignment: .top)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(categories) { category in
                let isSelected = category.id == selectedCategoryId
                Button {
                    selectedCategoryId = category.id
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? CategoryColor.selectedBackground(for: category.colorKey) : CategoryColor.subtleBackground(for: category.colorKey))
                                .frame(width: 44, height: 44)
                            Image(systemName: category.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isSelected ? category.accentColor : category.accentColor.opacity(0.8))
                        }
                        Text(category.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(isSelected ? CategoryColor.subtleBackground(for: category.colorKey) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? category.accentColor.opacity(0.4) : Color.secondary.opacity(0.22), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(category.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}


