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
import Foundation
import UIKit

// TEMPORARY PLACEHOLDER - Remove this section after adding GoogleMobileAds package
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 4
        
        let label = UILabel()
        label.text = "Ad"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// UNCOMMENT THIS SECTION AFTER ADDING GOOGLE MOBILE ADS PACKAGE:
/*
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        context.coordinator.bannerView = banner
        
        // Find the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
            context.coordinator.rootViewController = rootViewController
        }
        
        let request = GADRequest()
        banner.load(request)
        
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Update root view controller if needed
        if let rootVC = context.coordinator.rootViewController {
            if uiView.rootViewController != rootVC {
                uiView.rootViewController = rootVC
            }
        }
    }
    
    class Coordinator: NSObject {
        weak var bannerView: GADBannerView?
        weak var rootViewController: UIViewController?
    }
}
*/

// Helper to get the correct ad unit ID based on build configuration
enum AdMobConfig {
    static var bannerAdUnitID: String {
        #if DEBUG
        // Test ad unit for development
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        // Production ad unit
        return "ca-app-pub-8853742472105910/4965067318"
        #endif
    }
}
#endif

// Cross-platform wrapper
struct AdBannerView: View {
    #if os(iOS)
    var body: some View {
        BannerAdView(adUnitID: AdMobConfig.bannerAdUnitID)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
    }
    #else
    var body: some View {
        EmptyView()
    }
    #endif
}
