# Fix Info.plist Copy Conflict

The exclusion in project.pbxproj might not be working with PBXFileSystemSynchronizedRootGroup.

**Manual Fix in Xcode:**

1. Open the project in Xcode
2. Select the project in the navigator
3. Select the `cashExpense` target
4. Go to **Build Phases** tab
5. Expand **Copy Bundle Resources**
6. If `Info.plist` appears there, select it and click the **minus (-)** button to remove it
7. Select `Info.plist` file in the project navigator
8. In the File Inspector (right panel), under **Target Membership**, **uncheck** the `cashExpense` target
9. Clean Build Folder (Shift+Cmd+K)
10. Build again

The exclusion in project.pbxproj should work, but if it doesn't, this manual fix will resolve it.
