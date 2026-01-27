//
//  SettingsView.swift
//  cashExpense

import SwiftUI
import SwiftData
#if os(iOS)
import StoreKit
import MessageUI
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var lockManager: LockManager
    #if DEBUG
    @EnvironmentObject private var reviewManager: ReviewManager
    #endif
    
    @Query(sort: \AppConfig.createdAt, order: .forward) private var configs: [AppConfig]
    
    @State private var showingCategories = false
    @State private var showingExport = false
    @State private var showingCurrencyPicker = false
    #if os(iOS)
    @State private var showingMailComposer = false
    @State private var showingShareSheet = false
    #endif
    #if DEBUG
    @State private var showingDebugReviewPrompt = false
    #endif
    
    private var config: AppConfig? { configs.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingCurrencyPicker = true
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(config?.selectedCurrencyCode ?? deviceCurrencyCode)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
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
                    
                    NavigationLink {
                        DefaultCategoryPickerView()
                    } label: {
                        HStack {
                            Text("Default category")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        showingCategories = true
                    } label: {
                        HStack {
                            Text("Manage categories")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Categories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("All data is stored locally on your device.")
                        Text("No account required.")
                        Text("No data is collected.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    
                    LabeledContent("Version", value: appVersionString)
                    
                    #if os(iOS)
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            showingMailComposer = true
                        } label: {
                            Text("Contact Support")
                        }
                    } else {
                        Link("Contact Support", destination: mailtoURL)
                    }
                    
                    Button {
                        requestReview()
                    } label: {
                        Text("Rate this app")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Text("Share app")
                    }
                    #else
                    Link("Contact Support", destination: mailtoURL)
                    #endif
                    
                    Text("For personal tracking only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                #if DEBUG
                Section {
                    Button {
                        print("🔍 [DEBUG] Force Review Prompt button tapped")
                        showingDebugReviewPrompt = true
                    } label: {
                        Text("Force Review Prompt (Debug)")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Debug")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
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
            #if os(iOS)
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView(
                    subject: "Cash Expense Support",
                    body: mailBody
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            #endif
            #if DEBUG
            .sheet(isPresented: $showingDebugReviewPrompt) {
                DebugReviewPromptView()
            }
            #endif
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
    
    #if os(iOS)
    private var mailBody: String {
        let version = appVersionString
        let iosVersion = UIDevice.current.systemVersion
        return """
        App Version: \(version)
        iOS Version: \(iosVersion)
        
        Please describe your issue or question below:
        
        
        """
    }
    
    private var mailtoURL: URL {
        let version = appVersionString
        let iosVersion = UIDevice.current.systemVersion
        let body = mailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subject = "Cash Expense Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:support@example.com?subject=\(subject)&body=\(body)") ?? URL(string: "mailto:support@example.com")!
    }
    
    private var shareItems: [Any] {
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Cash Expense"
        let appStoreURL = "https://apps.apple.com/app/id\(Bundle.main.bundleIdentifier ?? "")"
        return ["Check out \(appName): \(appStoreURL)"]
    }
    
    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    #endif
}

// MARK: - Debug Review Prompt

#if DEBUG
struct DebugReviewPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("If this app has been helpful, would you mind rating it? It really helps.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button {
                        print("🔍 [DEBUG] Rate Now tapped - requesting review")
                        requestReview()
                        dismiss()
                    } label: {
                        Text("Rate Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        print("🔍 [DEBUG] Not Now tapped - dismissing")
                        dismiss()
                    } label: {
                        Text("Not Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .navigationTitle("Rate App")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .interactiveDismissDisabled()
            .onAppear {
                print("🔍 [DEBUG] Debug review prompt view appeared")
            }
        }
        .presentationDetents([.height(220)])
    }
    
    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            print("🔍 [DEBUG] Calling SKStoreReviewController.requestReview(in: windowScene)")
            SKStoreReviewController.requestReview(in: windowScene)
            print("🔍 [DEBUG] Review request completed")
        } else {
            print("🔍 [DEBUG] ERROR: Could not get UIWindowScene")
        }
    }
}
#endif

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
            #if os(iOS)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search currencies")
            #else
            .searchable(text: $searchText, prompt: "Search currencies")
            #endif
            .navigationTitle("Currency")
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

// MARK: - Mail Compose View

#if os(iOS)
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
