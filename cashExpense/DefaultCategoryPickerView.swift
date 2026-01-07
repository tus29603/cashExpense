//
//  DefaultCategoryPickerView.swift
//  cashExpense
//

import SwiftUI
import SwiftData

struct DefaultCategoryPickerView: View {
    @Query(filter: #Predicate<Category> { $0.isArchived == false }, sort: \Category.sortOrder, order: .forward)
    private var categories: [Category]
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    private var config: AppConfig? { configs.first }
    
    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    guard let config else { return }
                    config.defaultCategoryId = category.id
                    config.updatedAt = Date()
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .frame(width: 22)
                            .foregroundStyle(.secondary)
                        Text(category.name)
                        Spacer()
                        if config?.defaultCategoryId == category.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Default category")
        .navigationBarTitleDisplayMode(.inline)
    }
}


