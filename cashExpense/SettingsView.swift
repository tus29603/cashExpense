//
//  SettingsView.swift
//  cashExpense

import SwiftUI
import SwiftData

struct SettingsView: View {
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

// MARK: - Currency Picker

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCode: String
    
    @State private var searchText: String = ""
    
    private var filteredCurrencies: [SupportedCurrency] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return SupportedCurrency.allCases }
        return SupportedCurrency.allCases.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }
    
    private var commonCodes: [SupportedCurrency] {
        [.usd, .eur, .gbp, .cad, .aud]
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Common") {
                        ForEach(commonCodes) { c in
                            currencyRow(c)
                        }
                    }
                    
                    Section("All") {
                        ForEach(SupportedCurrency.allCases.filter { !commonCodes.contains($0) }) { c in
                            currencyRow(c)
                        }
                    }
                } else {
                    ForEach(filteredCurrencies) { c in
                        currencyRow(c)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search currencies")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func currencyRow(_ c: SupportedCurrency) -> some View {
        Button {
            selectedCode = c.code
            dismiss()
        } label: {
            HStack {
                Text("\(c.code) — \(c.name)")
                Spacer()
                if selectedCode == c.code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(c.name), \(selectedCode == c.code ? "selected" : "not selected")")
    }
}

// MARK: - Supported Currencies

enum SupportedCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case etb = "ETB"
    case jpy = "JPY"
    case inr = "INR"
    case cny = "CNY"
    case krw = "KRW"
    case mxn = "MXN"
    case brl = "BRL"
    case chf = "CHF"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"
    case nzd = "NZD"
    case sgd = "SGD"
    case hkd = "HKD"
    case zar = "ZAR"
    case aed = "AED"
    case php = "PHP"
    case thb = "THB"
    case myr = "MYR"
    case idr = "IDR"
    case pln = "PLN"
    case czk = "CZK"
    case huf = "HUF"
    case ils = "ILS"
    case ngn = "NGN"
    case kes = "KES"
    case egp = "EGP"
    case pkr = "PKR"
    case bdt = "BDT"
    case vnd = "VND"
    
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
        case .inr: return "Indian Rupee"
        case .cny: return "Chinese Yuan"
        case .krw: return "South Korean Won"
        case .mxn: return "Mexican Peso"
        case .brl: return "Brazilian Real"
        case .chf: return "Swiss Franc"
        case .sek: return "Swedish Krona"
        case .nok: return "Norwegian Krone"
        case .dkk: return "Danish Krone"
        case .nzd: return "New Zealand Dollar"
        case .sgd: return "Singapore Dollar"
        case .hkd: return "Hong Kong Dollar"
        case .zar: return "South African Rand"
        case .aed: return "UAE Dirham"
        case .php: return "Philippine Peso"
        case .thb: return "Thai Baht"
        case .myr: return "Malaysian Ringgit"
        case .idr: return "Indonesian Rupiah"
        case .pln: return "Polish Zloty"
        case .czk: return "Czech Koruna"
        case .huf: return "Hungarian Forint"
        case .ils: return "Israeli Shekel"
        case .ngn: return "Nigerian Naira"
        case .kes: return "Kenyan Shilling"
        case .egp: return "Egyptian Pound"
        case .pkr: return "Pakistani Rupee"
        case .bdt: return "Bangladeshi Taka"
        case .vnd: return "Vietnamese Dong"
        }
    }
}
