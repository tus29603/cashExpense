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
    @EnvironmentObject private var reviewManager: ReviewManager
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    @Query(filter: #Predicate<Category> { $0.isArchived == false }, sort: \Category.sortOrder, order: .forward)
    private var categories: [Category]
    
    let mode: AddEditMode
    let onDone: () -> Void
    
    @FocusState private var amountFocused: Bool
    @FocusState private var noteFocused: Bool
    @State private var amountText: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var note: String = ""
    @State private var dateSpent: Date = Date()
    @State private var selectedCurrencyCode: String = ""
    @State private var showNoteField: Bool = false
    
    private var config: AppConfig? { configs.first }
    
    private var defaultCurrencyCode: String {
        config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD")
    }
    
    private var currencyCode: String {
        selectedCurrencyCode.isEmpty ? defaultCurrencyCode : selectedCurrencyCode
    }
    
    private var parsedAmount: Decimal? {
        MoneyUtils.parseDecimal(from: amountText).map { MoneyUtils.roundedCurrency($0) }
    }
    
    private var canSave: Bool {
        guard let parsedAmount, parsedAmount > 0 else { return false }
        return selectedCategoryId != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .center, spacing: 8) {
                        TextField("0.00", text: $amountText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .font(Font.largeTitle.weight(.bold))
                            .focused($amountFocused)
                            .accessibilityLabel("Amount")
                            .onChange(of: amountText) { newValue in
                                // Filter to allow only numbers and decimal separator
                                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                // Ensure only one decimal point
                                let components = filtered.split(separator: ".")
                                let sanitized: String
                                if components.count > 2 {
                                    // More than one decimal point, keep only the first
                                    let first = String(components[0])
                                    let second = components[1...].joined(separator: "")
                                    sanitized = first + "." + second
                                } else {
                                    sanitized = filtered
                                }
                                
                                // Only update if the value actually changed
                                if sanitized != newValue {
                                    amountText = sanitized
                                }
                            }
                        
                        Picker("Currency", selection: $selectedCurrencyCode) {
                            ForEach(SupportedCurrency.allCases) { currency in
                                Text(currency.code).tag(currency.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 70)
                        .labelsHidden()
                        .onChange(of: selectedCurrencyCode) { newValue in
                            // Update global config when currency changes
                            if let config, !newValue.isEmpty {
                                config.selectedCurrencyCode = newValue
                                config.updatedAt = Date()
                            }
                        }
                    }
                    
                    if showNoteField || !note.isEmpty {
                        TextField("Note (optional)", text: $note, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($noteFocused)
                            .onAppear {
                                if showNoteField && note.isEmpty {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        noteFocused = true
                                    }
                                }
                            }
                    } else {
                        Button {
                            withAnimation {
                                showNoteField = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                noteFocused = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "note.text")
                                    .font(.subheadline)
                                Text("Add note")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Amount")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Category") {
                    CategoryGrid(
                        categories: categories,
                        selectedCategoryId: $selectedCategoryId
                    )
                    .padding(.vertical, 4)
                }
                
                Section("Details") {
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
                        .opacity(canSave ? 1.0 : 0.5)
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
            .sheet(isPresented: $reviewManager.showingReviewPrompt) {
                ReviewPromptView(reviewManager: reviewManager)
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
            selectedCurrencyCode = defaultCurrencyCode
        case .edit(let expense):
            selectedCategoryId = expense.categoryId
            dateSpent = expense.dateSpent
            note = expense.note ?? ""
            amountText = NSDecimalNumber(decimal: MoneyUtils.roundedCurrency(expense.amount)).stringValue
            selectedCurrencyCode = expense.currencyCode
            showNoteField = !note.isEmpty
        }
        
        if selectedCategoryId == nil {
            selectedCategoryId = categories.first?.id ?? SeedData.otherId
        }
        
        if selectedCurrencyCode.isEmpty {
            selectedCurrencyCode = defaultCurrencyCode
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
            // Track expense for review prompt
            reviewManager.recordExpenseAdded()
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


