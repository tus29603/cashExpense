//
//  LockManager.swift
//  cashExpense
//

import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class LockManager: ObservableObject {
    @Published private(set) var isLocked: Bool = false
    private var isEnabled: Bool = false
    
    func syncConfig(_ config: AppConfig?) {
        isEnabled = config?.isAppLockEnabled ?? false
        if isEnabled {
            // Lock on app open / immediately after enabling.
            isLocked = true
        } else {
            isLocked = false
        }
    }
    
    func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isEnabled else { return }
        switch phase {
        case .background:
            isLocked = true
        default:
            break
        }
    }
    
    func shouldShowLockOverlay(config: AppConfig?) -> Bool {
        guard let config else { return false }
        guard config.isAppLockEnabled, config.hasPro else { return false }
        return isLocked
    }
    
    func unlock() async {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        let canEval = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        guard canEval else { return }
        
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock to access your expenses."
            )
            if ok {
                isLocked = false
            }
        } catch {
            // user cancelled / auth failed -> stay locked
        }
    }
}

struct LockOverlayView: View {
    let onUnlock: () async -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .bold))
                Text("Locked")
                    .font(.title.weight(.bold))
                Text("Authenticate to continue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    Task { await onUnlock() }
                } label: {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding()
        }
    }
}


