//
//  DefaultCategoryPickerView.swift
//  cashExpense

import SwiftUI
import SwiftData

struct DefaultCategoryPickerView: View {
    @Query(filter: #Predicate<Category> { $0.isArchived == false }, sort: \Category.sortOrder, order: .forward)
    private var categories: [Category]
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    private var config: AppConfig? { configs.first }
    
    var body: some View {
        List {
            if categories.isEmpty {
                ContentUnavailableView(
                    "No categories",
                    systemImage: "tag.slash",
                    description: Text("Add a category to continue.")
                )
            } else {
                ForEach(categories) { category in
                    let isSelected = config?.defaultCategoryId == category.id
                    
                    Button {
                        guard let config else { return }
                        config.defaultCategoryId = category.id
                        config.updatedAt = Date()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(CategoryColor.subtleBackground(for: category.colorKey))
                                    .frame(width: 28, height: 28)
                                Image(systemName: category.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(category.accentColor)
                            }
                            Text(category.name)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(category.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(category.name), \(isSelected ? "selected" : "not selected")")
                }
            }
        }
        .navigationTitle("Default category")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
