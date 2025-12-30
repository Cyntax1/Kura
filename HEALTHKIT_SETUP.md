# Apple Health (HealthKit) Integration Setup

## Overview
Kura now integrates with Apple Health to track workouts and calories burned, giving you a complete picture of your calorie balance (calories consumed vs calories burned).

## Features
- 🏃 **Workout Tracking**: View all your workouts from Apple Health
- 🔥 **Calories Burned**: See how many calories you've burned from activities
- 📊 **Net Calories**: Automatic calculation of net calories (eaten - burned)
- 👟 **Activity Metrics**: Track steps, distance, and active energy
- 📈 **Workout Types**: Supports all Apple Health workout types (running, cycling, yoga, HIIT, etc.)

## Setup Instructions

### 1. Add HealthKit Capability in Xcode

1. Open your project in Xcode
2. Select your app target (Kura)
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **HealthKit**

### 2. Add Privacy Descriptions to Info.plist

You need to add privacy descriptions explaining why your app needs access to health data.

**Method 1: Using Info.plist file**
1. Open `Info.plist` in Xcode
2. Add the following keys:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Kura needs access to your workout and activity data to calculate calories burned and show your net calorie balance.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Kura may write nutrition data to Apple Health in the future.</string>
```

**Method 2: Using Property List Editor**
1. Open `Info.plist` in Xcode
2. Right-click and select "Add Row"
3. Add these keys:
   - **Key**: `Privacy - Health Share Usage Description`
     **Value**: `Kura needs access to your workout and activity data to calculate calories burned and show your net calorie balance.`
   
   - **Key**: `Privacy - Health Update Usage Description`
     **Value**: `Kura may write nutrition data to Apple Health in the future.`

### 3. Test on Real Device

⚠️ **Important**: HealthKit does NOT work in the iOS Simulator. You must test on a real iPhone or Apple Watch.

## How It Works

### 1. **Permission Flow**
- First time users see a permission request screen
- Tap "Connect Apple Health" to authorize
- Choose which data to share in the iOS Health permissions dialog

### 2. **Calorie Balance Card** (Diet Tab)
Shows your daily calorie equation:
```
Calories Eaten - Calories Burned = Net Calories
```

Example:
- 🍽️ Eaten: 1,800 kcal
- 🔥 Burned: 450 kcal  
- 📊 Net: 1,350 kcal

### 3. **Workouts View** (Profile → Apple Health)
- Today's activity summary (calories, steps, workouts)
- List of all workouts with details:
  - Activity type (running, cycling, etc.)
  - Duration
  - Calories burned
  - Distance (if applicable)
- Pull to refresh for latest data

### 4. **Automatic Updates**
- Data refreshes when you open the Diet tab
- Pull to refresh in Workouts view for latest data
- Real-time sync with Apple Health

## Supported Workout Types

The app recognizes and displays icons for:
- 🏃 Running
- 🚶 Walking  
- 🚴 Cycling
- 🏊 Swimming
- 🧘 Yoga
- 🏋️ Strength Training / Weight Lifting
- 🔥 HIIT (High Intensity Interval Training)
- 🥊 Boxing
- 🕺 Dance
- 🧘‍♀️ Pilates
- ⚽ Soccer
- 🏀 Basketball
- 🎾 Tennis
- ⛳ Golf
- 🏐 Volleyball
- ⚾ Baseball
- ...and many more!

## Privacy & Security

✅ **Your data stays on your device**
- Kura only reads workout data from Apple Health
- No workout data is sent to external servers
- All processing happens locally on your iPhone

✅ **You control access**
- You can revoke HealthKit permissions anytime in iOS Settings
- Go to: Settings → Privacy & Security → Health → Kura

## Troubleshooting

### "Apple Health Unavailable" Message
- HealthKit is only available on iPhone and Apple Watch
- iPad and Mac do not support HealthKit

### No Workouts Showing
1. Make sure you've granted permissions
2. Check that you have workouts logged in Apple Health app
3. Try pull-to-refresh in the Workouts view
4. Restart the app

### Calories Not Updating
1. Open the Workouts view to trigger a refresh
2. Make sure workouts are properly saved in Apple Health
3. Check that permissions include "Active Energy" and "Workouts"

### Permission Denied
1. Go to iOS Settings → Privacy & Security → Health → Kura
2. Enable "Workouts" and "Active Energy Burned"
3. Restart Kura app

## Future Enhancements

Potential features to add:
- Write nutrition data to Apple Health
- Sync water intake with Health app
- Heart rate monitoring during fasting
- Sleep data integration
- Weekly/monthly workout summaries
- Workout goal setting
- Integration with Apple Watch complications

## Technical Details

### Data Types Read
- `HKWorkoutType` - Workout sessions
- `HKQuantityType.activeEnergyBurned` - Calories burned during activity
- `HKQuantityType.basalEnergyBurned` - Resting calories burned
- `HKQuantityType.stepCount` - Daily steps
- `HKQuantityType.distanceWalkingRunning` - Distance traveled
- `HKQuantityType.heartRate` - Heart rate data

### Files Created
- `HealthKitService.swift` - Core HealthKit integration service
- `WorkoutsView.swift` - UI for displaying workouts
- `CalorieBalanceCard.swift` - Calorie balance widget for Diet tab
- `HEALTHKIT_SETUP.md` - This documentation

### Architecture
- Uses `@StateObject` and `@Published` for reactive updates
- Queries are executed asynchronously to avoid blocking UI
- Automatic refresh on view appearance
- Pull-to-refresh support

## Support

If you encounter issues:
1. Check that HealthKit capability is enabled
2. Verify Info.plist has required privacy descriptions
3. Test on a real device (not simulator)
4. Check iOS Settings for Health permissions
5. Make sure you're running iOS 14.0 or later

---

**Enjoy tracking your complete calorie balance with Apple Health integration! 🎉**
