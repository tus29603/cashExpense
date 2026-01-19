//
//  BannerAdView.swift
//  cashExpense
//
//  Google AdMob Banner Ad Component (iOS only)
//
//  IMPORTANT: Before this will compile, you MUST add Google Mobile Ads SDK:
//  1. File → Add Package Dependencies...
//  2. URL: https://github.com/googleads/swift-package-manager-google-mobile-ads.git
//  3. Add to cashExpense target
//  4. Then uncomment the code below and remove the placeholder section
//

import SwiftUI

#if os(iOS)
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        context.coordinator.bannerView = banner
        
        // Find the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
            context.coordinator.rootViewController = rootViewController
        }
        
        let request = Request()
        banner.load(request)
        
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // Update root view controller if needed
        if let rootVC = context.coordinator.rootViewController {
            if uiView.rootViewController != rootVC {
                uiView.rootViewController = rootVC
            }
        }
    }
    
    class Coordinator: NSObject {
        weak var bannerView: BannerView?
        weak var rootViewController: UIViewController?
    }
}

// Helper to get the production ad unit ID
enum AdMobConfig {
    static var bannerAdUnitID: String {
        // Production banner ad unit ID
        return "ca-app-pub-8853742472105910/1126690814"
    }
}
#endif

// Cross-platform wrapper
struct AdBannerView: View {
    #if os(iOS)
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.separator))
            BannerAdView(adUnitID: AdMobConfig.bannerAdUnitID)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
        }
    }
    #else
    var body: some View {
        EmptyView()
    }
    #endif
}
