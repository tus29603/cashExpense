//
//  CategoriesView.swift
//  cashExpense

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    
    @State private var showingAdd = false
    
    private var otherCategory: Category? {
        categories.first(where: { $0.id == SeedData.otherId })
    }
    
    private var activeCategories: [Category] {
        categories.filter { !$0.isArchived }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No categories",
                        systemImage: "tag.slash",
                        description: Text("Add a category to continue.")
                    )
                } else {
                    ForEach(categories) { category in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(CategoryColor.subtleBackground(for: category.colorKey))
                                    .frame(width: 24, height: 24)
                                Image(systemName: category.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(category.accentColor)
                            }
                            TextField("Name", text: Binding(get: {
                                category.name
                            }, set: { newValue in
                                category.name = newValue
                            }))
                            
                            Spacer()
                            
                            Toggle(isOn: Binding(get: {
                                category.isArchived
                            }, set: { newValue in
                                if category.id == SeedData.otherId {
                                    category.isArchived = false
                                } else {
                                    category.isArchived = newValue
                                }
                            })) {
                                Text("Archived")
                            }
                            .labelsHidden()
                        }
                    }
                    .onMove(perform: move)
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddCategorySheet()
            }
            .onAppear {
                SeedData.ensureSeeded(modelContext: modelContext)
                // Ensure "Other" is never archived.
                otherCategory?.isArchived = false
            }
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        var copy = categories
        copy.move(fromOffsets: source, toOffset: destination)
        for (idx, cat) in copy.enumerated() {
            cat.sortOrder = idx
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let cat = categories[idx]
            if cat.id == SeedData.otherId { continue } // "Other" cannot be deleted
            modelContext.delete(cat)
        }
        // Re-normalize sort order
        let remaining = categories.filter { $0.modelContext != nil }
        for (idx, cat) in remaining.enumerated() {
            cat.sortOrder = idx
        }
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortOrder, order: .forward) private var categories: [Category]
    
    @State private var name: String = ""
    @State private var icon: String = "tag.fill"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }
                Section("Icon (SF Symbol)") {
                    TextField("tag.fill", text: $icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Text("Preview")
                        Spacer()
                        Image(systemName: icon.isEmpty ? "tag.fill" : icon)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let cat = Category(
                            name: trimmed,
                            icon: icon.isEmpty ? "tag.fill" : icon,
                            colorKey: "gray",
                            sortOrder: (categories.map(\.sortOrder).max() ?? -1) + 1,
                            isDefault: false,
                            isArchived: false
                        )
                        modelContext.insert(cat)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
