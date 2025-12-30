# How to Reset Onboarding

## Problem
Onboarding doesn't show because `hasCompletedOnboarding` is stored in UserDefaults and persists between app runs.

## Solutions

### Option 1: Delete & Reinstall App (Quickest)
1. Delete the app from your simulator/device
2. Clean build folder: **Cmd+Shift+K** in Xcode
3. Build and run again

### Option 2: Reset Simulator
1. In Simulator menu: **Device → Erase All Content and Settings**
2. Rebuild and run the app

### Option 3: Add Debug Reset (For Development)
Add a button in your app to manually reset onboarding for testing purposes.
