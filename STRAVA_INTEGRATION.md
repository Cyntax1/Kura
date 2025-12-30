# 🏃 Strava Integration Guide

## ✅ **Strava Connected!**

Your Kura app now integrates with Strava to automatically track workouts, calories burned, and exercise stats!

---

## 📱 **How to Use**

### **Step 1: Connect Your Strava Account**
```
1. Open Kura app
2. Go to Profile tab (👤)
3. Tap "Strava" in More section
4. Tap "Connect with Strava"
5. Log in to Strava
6. Authorize Kura
7. Done! ✅
```

### **Step 2: View Your Workouts**
Once connected, Kura automatically:
- ✅ Syncs all your recent activities
- ✅ Shows calories burned per workout
- ✅ Displays distance, duration, heart rate
- ✅ Updates in real-time

### **Step 3: Track Weekly Stats**
See your weekly summary:
- **Total Workouts** - Number of activities this week
- **Calories Burned** - Total kcal from all workouts
- **Distance** - Total kilometers covered
- **Active Time** - Total workout duration

---

## 🎯 **What Gets Tracked**

### **Supported Activity Types:**
- 🏃 **Running** - Distance, pace, calories, heart rate
- 🚴 **Cycling** - Distance, speed, elevation, calories
- 🏊 **Swimming** - Distance, duration, calories
- 🚶 **Walking** - Steps, distance, calories
- 🥾 **Hiking** - Distance, elevation gain, calories
- 🏋️ **Weight Training** - Duration, calories
- 🧘 **Yoga** - Duration, calories
- 💪 **Workouts** - All general fitness activities

### **Data Synced:**
```
✅ Activity name
✅ Activity type (run, ride, swim, etc.)
✅ Distance (meters → km)
✅ Duration (moving time & elapsed time)
✅ Calories burned
✅ Average & max speed
✅ Heart rate (average & max)
✅ Elevation gain
✅ Start date/time
```

---

## 🔐 **API Credentials**

### **Your Strava App:**
```
Category: MobileApp
Club: Kura Fitness Tracker

Client ID: 182251
Client Secret: 656b3683c9b6a79143c6f2038647369af17e71e8

OAuth Redirect: kura://strava-callback
Scope: read, activity:read
```

### **Token Management:**
- **Access Token**: Automatically refreshed
- **Refresh Token**: Stored securely in UserDefaults
- **Expires**: Tokens auto-refresh 5 minutes before expiry
- **Secure**: No tokens exposed in UI

---

## 🛠️ **Technical Implementation**

### **Files Created:**
1. **StravaService.swift** - Core API integration
   - OAuth authentication
   - Token management & refresh
   - Activity fetching
   - Weekly stats calculation

2. **StravaView.swift** - User interface
   - Connection flow
   - Athlete profile display
   - Recent activities list
   - Weekly stats cards
   - Disconnect option

3. **Info.plist** - Updated with URL scheme
   - `kura://strava-callback` for OAuth

4. **ProfileView.swift** - Updated
   - Added Strava option in More section

---

## 🔄 **How Authentication Works**

### **OAuth 2.0 Flow:**
```
1. User taps "Connect with Strava"
   ↓
2. Opens Strava authorization in Safari
   ↓
3. User logs in to Strava
   ↓
4. User grants permissions to Kura
   ↓
5. Strava redirects to: kura://strava-callback?code=XXX
   ↓
6. Kura exchanges code for access token
   ↓
7. Token saved securely
   ↓
8. Recent activities fetched
   ↓
9. Connected! ✅
```

### **Token Refresh:**
```swift
// Automatic refresh before expiry
if tokenExpiresAt <= now + 5 minutes {
    refreshToken()
}
```

---

## 📊 **UI Features**

### **1. Connection Screen** (Not Connected)
- Strava logo with gradient
- Feature list
- "Connect with Strava" button
- Opens Safari for secure OAuth

### **2. Dashboard** (Connected)
- **Athlete Card**
  - Profile photo
  - Full name
  - Connection status

- **Weekly Stats**
  - 4 stat cards (workouts, calories, distance, time)
  - Color-coded icons
  - Real-time data

- **Recent Activities**
  - Last 10 activities
  - Activity type icon & color
  - Distance & duration
  - Calories burned
  - Heart rate (if available)
  - Time ago ("2 hours ago")

### **3. Pull to Refresh**
- Swipe down to sync latest activities
- Shows loading indicator
- Updates all stats

---

## 🎨 **Activity Display**

### **Each Activity Shows:**
```
┌─────────────────────────────────┐
│  🏃 Morning Run                 │  ← Icon & name
│  2 hours ago                    │  ← Relative time
│                         389 kcal│  ← Calories
├─────────────────────────────────┤
│  📍 5.2 km  ⏱️ 32m  ❤️ 145 bpm │  ← Stats
└─────────────────────────────────┘
```

### **Activity Type Colors:**
- 🏃 Running → Orange
- 🚴 Cycling → Blue
- 🏊 Swimming → Cyan
- 🚶 Walking → Green
- 🥾 Hiking → Brown
- 🏋️ Weights → Purple
- 🧘 Yoga → Pink

---

## 💡 **Usage Scenarios**

### **Scenario 1: Daily Tracking**
```
Morning:
1. Go for a run (tracked in Strava)
2. Open Kura → Profile → Strava
3. See calories burned: 450 kcal
4. Go to Food tab
5. Log breakfast: 600 kcal
6. Net calories: 600 - 450 = 150 kcal ✅
```

### **Scenario 2: Weekly Review**
```
Sunday:
1. Open Profile → Strava
2. Check weekly stats:
   - 5 workouts
   - 2,500 calories burned
   - 35 km covered
   - 4h 20m active time
3. Celebrate progress! 🎉
```

### **Scenario 3: Fasting + Exercise**
```
During 16:8 Fast:
1. Morning workout (Strava tracks)
2. Kura shows calories burned
3. Break fast with proper nutrition
4. Balance intake vs. expenditure
```

---

## 🔧 **Customization Options**

### **Disconnect Strava:**
```
Profile → Strava → "Disconnect Strava" (red button)
```
- Removes all tokens
- Clears activity data
- Can reconnect anytime

### **Reconnect:**
```
Profile → Strava → "Connect with Strava"
```
- Fresh OAuth flow
- Gets new tokens
- Syncs latest data

---

## 🚀 **Future Enhancements**

### **Phase 2 Features:**
- Auto-sync every hour
- Activity notifications
- Calorie goal adjustments based on workouts
- Export workout data
- Custom activity filtering
- Monthly/yearly stats
- Streak tracking
- Social features (compare with friends)

### **Phase 3 Features:**
- Workout recommendations
- AI-powered training plans
- Recovery time suggestions
- Nutrition timing (pre/post workout meals)
- Integration with diet plans

---

## 📈 **Benefits for Kura Users**

### **1. Complete Calorie Picture**
```
Calories Consumed (Food) - Calories Burned (Strava) = Net Calories
```

### **2. Better Goal Tracking**
- Daily calorie goal: 2000 kcal
- Food logged: 2200 kcal
- Workout burned: 400 kcal
- Net intake: 1800 kcal ✅ (Under goal!)

### **3. Motivation**
- See workout progress
- Track consistency
- Celebrate achievements
- Stay accountable

### **4. Time Savings**
- Auto-sync workouts
- No manual entry
- Real-time updates
- One-tap refresh

---

## 🛡️ **Privacy & Security**

### **Data Privacy:**
- ✅ Only reads activity data (no write access)
- ✅ Tokens stored locally (UserDefaults)
- ✅ No data sent to external servers
- ✅ Can disconnect anytime
- ✅ Follows Strava's privacy policy

### **Permissions Required:**
```
Strava Scopes:
- read: Basic profile info
- activity:read: Read workout data
```

### **What Kura CANNOT Do:**
- ❌ Modify your Strava activities
- ❌ Post on your behalf
- ❌ Access private messages
- ❌ Share data with others
- ❌ Delete activities

---

## 🆘 **Troubleshooting**

### **Problem: "Not connected" after authorization**
**Solution:**
1. Make sure you completed OAuth in Safari
2. Check internet connection
3. Try disconnecting and reconnecting

### **Problem: Activities not showing**
**Solution:**
1. Pull down to refresh
2. Check if activities exist in Strava app
3. Verify you have activities in last 30 days

### **Problem: Calories showing as 0**
**Solution:**
- Some activities may not have calorie data from Strava
- Depends on activity type and device used
- Heart rate monitor improves calorie accuracy

### **Problem: Token expired**
**Solution:**
- App automatically refreshes tokens
- If issue persists, disconnect and reconnect

---

## 📞 **Strava API Info**

### **API Documentation:**
https://developers.strava.com/docs/reference/

### **Rate Limits:**
- 100 requests per 15 minutes
- 1,000 requests per day
- Kura stays well under these limits

### **Endpoints Used:**
```
POST /oauth/token           - Get access token
GET  /athlete/activities    - Fetch workouts
```

---

## ✅ **Setup Complete!**

Your Kura app now has full Strava integration:
- ✅ OAuth authentication
- ✅ Activity syncing
- ✅ Calorie tracking
- ✅ Weekly stats
- ✅ Beautiful UI
- ✅ Auto token refresh
- ✅ Pull to refresh
- ✅ Secure storage

**Ready to use!** Go to **Profile → Strava** to connect! 🎉

---

## 🎯 **Quick Start**

```
1. Profile tab → Strava
2. Connect with Strava
3. Authorize in Safari
4. View your workouts
5. Track calories burned
6. Balance with food intake
7. Achieve your goals! 💪
```

**Happy tracking!** 🏃‍♂️💪🔥
