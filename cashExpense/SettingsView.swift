//
//  SettingsView.swift
//  cashExpense
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var lockManager: LockManager
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    @State private var showingCategories = false
    @State private var showingExport = false
    
    private var config: AppConfig? { configs.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Picker("Currency", selection: Binding(get: {
                        config?.selectedCurrencyCode ?? (Locale.current.currency?.identifier ?? "USD")
                    }, set: { newValue in
                        guard let config else { return }
                        config.selectedCurrencyCode = newValue
                        config.updatedAt = Date()
                    })) {
                        ForEach(SupportedCurrency.allCases) { c in
                            Text("\(c.code) — \(c.name)").tag(c.code)
                        }
                    }
                    
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
                }
                
                // Temporary: makes it possible to test Pro flows without StoreKit.
                Section("Developer") {
                    Toggle("Pro unlocked (debug)", isOn: Binding(get: {
                        config?.hasPro ?? false
                    }, set: { newValue in
                        guard let config else { return }
                        config.hasPro = newValue
                        config.updatedAt = Date()
                    }))
                }
                
                Section("About") {
                    LabeledContent("Version", value: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—")
                    Text("Privacy: No data collected.")
                        .foregroundStyle(.secondary)
                    Link("Contact", destination: URL(string: "mailto:support@example.com")!)
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
        }
    }
}

enum SupportedCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case etb = "ETB"
    case jpy = "JPY"
    
    var id: String { rawValue }
    var code: String { rawValue }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .etb: return "Ethiopian Birr"
        case .jpy: return "Japanese Yen"
        }
    }
}


