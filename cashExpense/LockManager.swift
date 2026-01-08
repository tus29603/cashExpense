//
//  LockManager.swift
//  cashExpense

import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class LockManager: ObservableObject {
    @Published private(set) var isLocked: Bool = false
    @Published private(set) var authError: String? = nil
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
        authError = nil
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        let canEval = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        guard canEval else {
            authError = error?.localizedDescription ?? "Biometrics unavailable"
            return
        }
        
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock to access your expenses."
            )
            if ok {
                isLocked = false
                authError = nil
            }
        } catch let err as LAError {
            switch err.code {
            case .userCancel, .appCancel, .systemCancel:
                // User cancelled — keep locked, allow retry
                authError = nil
            case .userFallback:
                // User wants passcode — deviceOwnerAuthentication already handles this
                authError = nil
            default:
                authError = err.localizedDescription
            }
        } catch {
            authError = error.localizedDescription
        }
    }
}

struct LockOverlayView: View {
    @ObservedObject var lockManager: LockManager
    
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
                
                if let error = lockManager.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    Task { await lockManager.unlock() }
                } label: {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
                
                Button("Cancel") {
                    // Allow user to dismiss the overlay and stay on a blurred screen
                    // They won't be able to interact with the app until unlocked.
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding()
        }
    }
}
