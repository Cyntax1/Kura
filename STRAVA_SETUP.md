# 🏃 Strava Setup Instructions

## ✅ **Fix "redirect_uri invalid" Error**

### **Option 1: Add Redirect URI to Strava (Recommended)**

1. **Go to Strava API Settings:**
   - Visit: https://www.strava.com/settings/api
   - Or: https://www.strava.com/settings/api/app/182251

2. **Find "Authorization Callback Domain":**
   - Look for the field labeled **"Authorization Callback Domain"**

3. **Add this value:**
   ```
   localhost
   ```

4. **Click "Update"** to save

### **What to Enter:**

Strava might ask for different formats depending on their UI:

**Try these (one should work):**
- `localhost` (just the domain)
- `http://localhost` (with protocol)
- `localhost,kura` (comma-separated if multiple)

---

## 📱 **How the App Works Now:**

### **Updated Redirect URI:**
```
http://localhost
```

This is a **Strava-approved redirect** for mobile apps. It's simpler and more reliable than custom URL schemes.

### **OAuth Flow:**
```
1. User taps "Connect with Strava"
   ↓
2. Opens Strava login in Safari
   ↓
3. User authorizes Kura
   ↓
4. Strava redirects to: http://localhost?code=XXX
   ↓
5. Safari intercepts the redirect
   ↓
6. App extracts the code
   ↓
7. App exchanges code for tokens
   ↓
8. Connected! ✅
```

---

## 🔧 **Code Changes Made:**

### **1. Updated StravaService.swift:**
```swift
// Changed from:
private let redirectURI = "kura://strava-callback"

// To:
private let redirectURI = "http://localhost"
```

### **2. Updated StravaView.swift:**
```swift
// Now handles both localhost and custom schemes
let isValidRedirect = URL.scheme == "http" && URL.host == "localhost" || URL.scheme == "kura"
```

---

## ✅ **Test It:**

1. **Add `localhost` to Strava API settings** (see above)
2. **Build and run** the app
3. **Go to Profile → Strava**
4. **Tap "Connect with Strava"**
5. **Log in and authorize**
6. Should work now! 🎉

---

## 🆘 **Still Getting Errors?**

### **Error: "redirect_uri invalid"**
- ✅ Add `localhost` to Strava settings (see step-by-step above)
- ✅ Make sure you're editing the correct app (Client ID: 182251)
- ✅ Click "Update" after adding

### **Error: "Application with ID does not exist"**
- ✅ Verify Client ID is correct: 182251
- ✅ Make sure app isn't deleted from Strava

### **Error: "invalid_client"**
- ✅ Check Client Secret is correct
- ✅ Make sure it matches your Strava app

### **Safari closes but nothing happens:**
- ✅ Check console logs for debug info
- ✅ Make sure callback is being intercepted
- ✅ Try restarting the app

---

## 📸 **Strava Settings Screenshot Guide:**

When you go to https://www.strava.com/settings/api, you should see:

```
My API Application

Application Name: [Your App Name]
Category: MobileApp
Website: [Optional]
Application Description: [Optional]

Client ID: 182251
Client Secret: 656b3683c9b6a79143c6f2038647369af17e71e8

Authorization Callback Domain: [ADD: localhost]  ← Enter here!

[Update Button]  ← Click this!
```

---

## 🎯 **Summary:**

**Problem:** Strava rejects `kura://` custom URL scheme
**Solution:** Use `http://localhost` (Strava-approved)
**Action Required:** Add `localhost` to Strava API settings

---

## 📚 **Reference:**

- **Strava API Docs:** https://developers.strava.com/docs/authentication/
- **OAuth Guide:** https://developers.strava.com/docs/getting-started/
- **Your App Settings:** https://www.strava.com/settings/api

---

**After adding `localhost` to Strava, the connection should work perfectly!** 🏃‍♂️✅
