# AdMob Setup Instructions

## Step 1: Add Google Mobile Ads SDK via Swift Package Manager

1. **Open Xcode** and open the `cashExpense.xcodeproj` project
2. **File → Add Package Dependencies...** (or right-click project → Add Package Dependencies...)
3. **Enter the package URL:**
   ```
   https://github.com/googleads/swift-package-manager-google-mobile-ads.git
   ```
4. Click **Add Package**
5. Select **GoogleMobileAds** product (check the checkbox)
6. Make sure **cashExpense** target is selected
7. Click **Add Package**

## Step 2: Verify Package is Linked

1. Select the **cashExpense** project in the navigator
2. Select the **cashExpense** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Verify **GoogleMobileAds** appears in the list
6. If not, click **+** and add it manually

## Step 3: Clean and Rebuild

1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. **Product → Build** (Cmd+B)

## Step 4: Verify App ID in Info.plist

The App ID is already configured in the project settings:
- Key: `GADApplicationIdentifier`
- Value: `ca-app-pub-8853742472105910~7060661899`

To verify:
1. Select **cashExpense** target
2. Go to **Info** tab (or **Build Settings** → search for "INFOPLIST")
3. Look for `GADApplicationIdentifier` in the list

## Step 5: Test

Run the app and check the console for:
- ✅ `AdMob App ID found: ca-app-pub-8853742472105910~7060661899`
- Banner ad should appear at the bottom of the screen

## Troubleshooting

If you still see "Unable to find module dependency":
1. Close Xcode completely
2. Delete `DerivedData` folder: `~/Library/Developer/Xcode/DerivedData`
3. Reopen Xcode
4. Clean Build Folder again
5. Rebuild

