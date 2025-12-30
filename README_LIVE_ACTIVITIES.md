# Live Activities for Fasting Timer

## Overview
The Kura app now supports Live Activities, providing real-time fasting progress updates on the lock screen and Dynamic Island (iPhone 14 Pro and later).

## Features

### Lock Screen Widget
- **Real-time countdown timer** showing remaining fasting time
- **Progress bar** indicating completion percentage
- **Fasting type and status** (Active/Paused)
- **Start time and goal duration** for context

### Dynamic Island (iPhone 14 Pro+)
- **Compact display** showing fasting type icon and remaining time
- **Expanded view** with full progress details
- **Status-aware colors** (blue for active, orange for paused)

### Automatic Updates
- **Live progress tracking** updates every 30 seconds
- **Status changes** reflected immediately (pause/resume/stop)
- **Auto-completion** when fasting goal is reached
- **Background support** continues tracking when app is closed

## Implementation Details

### Key Components
1. **FastingLiveActivity.swift** - Widget configuration and UI
2. **LiveActivityService.swift** - Activity management service
3. **FastingAttributes** - Data structure for Live Activity content

### Integration Points
- **Start fasting** - Automatically creates Live Activity
- **Pause/Resume** - Updates activity status and colors
- **Stop/Complete** - Ends activity with appropriate dismissal policy
- **Timer updates** - Periodic activity updates every 30 seconds

### Permissions
- Requires `NSSupportsLiveActivities` in Info.plist
- User must enable Live Activities in Settings > Kura
- Graceful fallback when permissions are disabled

## Usage

### For Users
1. Start any fasting session in the app
2. Live Activity automatically appears on lock screen
3. View progress without opening the app
4. Activity ends when fast is completed or stopped

### For Developers
```swift
// Start Live Activity
LiveActivityService.shared.startLiveActivity(for: session)

// Update Live Activity
LiveActivityService.shared.updateLiveActivity(for: session)

// End Live Activity
LiveActivityService.shared.endLiveActivity(reason: .immediate)
```

## Requirements
- iOS 16.1+ (Live Activities)
- iPhone 14 Pro+ (Dynamic Island features)
- User permission for Live Activities

## Benefits
- **Increased engagement** - Users can track progress without opening app
- **Better UX** - Glanceable information on lock screen
- **Motivation** - Constant visual reminder of fasting progress
- **Convenience** - No need to unlock phone to check progress

## Future Enhancements
- Push notifications for milestone achievements
- Interactive controls (pause/resume from lock screen)
- Multiple simultaneous fasting sessions
- Customizable Live Activity themes
