//
//  NewSettingsView.swift
//  cashExpense
//
//  New Settings view with full-screen layout
//

import SwiftUI
import SwiftData

struct NewSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var lockManager: LockManager
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    @State private var showingCategories = false
    @State private var showingExport = false
    @State private var showingCurrencyPicker = false
    
    private var config: AppConfig? { configs.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Button {
                        showingCurrencyPicker = true
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(config?.selectedCurrencyCode ?? deviceCurrencyCode)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Picker("Week starts on", selection: Binding(get: {
                        config?.weekStart ?? .monday
                    }, set: { newValue in
                        guard let config else { return }
                        config.weekStart = newValue
                        config.updatedAt = Date()
                    })) {
                        ForEach(WeekStart.allCases) { ws in
                            Text(ws.title).tag(ws)
                        }
                    }
                    
                    NavigationLink("Default category") {
                        DefaultCategoryPickerView()
                    }
                }
                
                Section("Categories") {
                    Button("Manage categories") {
                        showingCategories = true
                    }
                }
                
                #if false
                // Hidden for now - can be re-enabled by changing #if false to #if true
                Section("Pro") {
                    Button("Export CSV") {
                        guard let config else { return }
                        if config.hasPro {
                            showingExport = true
                        } else {
                            toastManager.show("Pro required")
                        }
                    }
                    
                    Toggle("App Lock", isOn: Binding(get: {
                        config?.isAppLockEnabled ?? false
                    }, set: { newValue in
                        guard let config else { return }
                        if newValue && !config.hasPro {
                            toastManager.show("Pro required")
                            return
                        }
                        config.isAppLockEnabled = newValue
                        config.updatedAt = Date()
                        lockManager.syncConfig(config)
                    }))
                    
                    #if DEBUG
                    // Only show in Debug builds until StoreKit IAP is fully implemented
                    Button("Restore Purchases") {
                        // Placeholder: In production, call StoreKit to restore.
                        toastManager.show("Restore not implemented yet")
                    }
                    #endif
                }
                #endif
                
                #if false
                // Hidden for now - can be re-enabled by changing #if false to #if true
                Section("Developer") {
                    Toggle("Pro unlocked (debug)", isOn: Binding(get: {
                        config?.hasPro ?? false
                    }, set: { newValue in
                        guard let config else { return }
                        config.hasPro = newValue
                        config.updatedAt = Date()
                    }))
                }
                #endif
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("All data is stored locally on your device.")
                        Text("No account required.")
                        Text("No data is collected.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    
                    LabeledContent("Version", value: appVersionString)
                    
                    Link("Contact Support", destination: URL(string: "mailto:support@example.com")!)
                    
                    Text("For personal tracking only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                SeedData.ensureSeeded(modelContext: modelContext)
            }
            .sheet(isPresented: $showingCategories) {
                CategoriesView()
            }
            .sheet(isPresented: $showingExport) {
                ExportCSVView()
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView(selectedCode: Binding(get: {
                    config?.selectedCurrencyCode ?? deviceCurrencyCode
                }, set: { newValue in
                    guard let config else { return }
                    config.selectedCurrencyCode = newValue
                    config.updatedAt = Date()
                }))
            }
        }
    }
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }
    
    private var deviceCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
