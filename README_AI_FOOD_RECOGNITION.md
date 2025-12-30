# AI Food Recognition Setup Guide for Kura

This guide will help you implement CalAI-style photo-based calorie and macro tracking in your Kura app.

## 🚀 What's Been Added

### Core Features
- **Real AI Food Recognition** using OpenAI Vision API
- **Comprehensive Nutrition Database** with Edamam and USDA APIs
- **Enhanced Camera Interface** with CalAI-style UI features
- **Portion Size Estimation** with visual portion guides
- **Food Editing Interface** for correcting AI results
- **Multi-photo Support** for complex meals

### New Files Created
```
Kura/
├── Services/
│   ├── AIFoodRecognitionService.swift     # Main AI recognition service
│   └── NutritionAPIService.swift          # Nutrition data fetching
├── Views/Diet/
│   ├── EnhancedFoodCameraView.swift       # CalAI-style camera interface
│   └── FoodEditView.swift                 # Food editing and correction
└── Config/
    └── APIConfig.swift                    # API configuration
```

## 🔧 Setup Instructions

### Step 1: API Keys Setup

#### OpenAI API (Primary - Required)
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. In `APIConfig.swift`, replace:
   ```swift
   static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
   ```
4. **Cost**: ~$0.01-0.03 per image analysis

#### USDA FoodData Central (Free - Recommended)
1. Go to [USDA FDC API](https://fdc.nal.usda.gov/api-guide.html)
2. Sign up for a free API key
3. Replace in `APIConfig.swift`:
   ```swift
   static let usdaAPIKey = "your-usda-key-here"
   ```
4. **Cost**: Free with rate limits

#### Edamam Nutrition API (Optional - Enhanced)
1. Go to [Edamam Developer](https://developer.edamam.com/edamam-nutrition-api)
2. Sign up for free tier (1,000 requests/month)
3. Get App ID and App Key
4. Replace in `APIConfig.swift`:
   ```swift
   static let edamamAppID = "your-app-id"
   static let edamamAppKey = "your-app-key"
   ```

### Step 2: Update Xcode Project

1. **Add new files to Xcode project**:
   - Drag the new Swift files into your Xcode project
   - Ensure they're added to your target

2. **Update Info.plist** for camera permissions:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Kura uses the camera to recognize food and automatically calculate nutrition information.</string>
   ```

3. **Add required imports** to existing files if needed

### Step 3: Integration Points

The enhanced camera is already integrated into:
- `FoodLogView.swift` - Updated to use `EnhancedFoodCameraView`
- `HomeView.swift` - Quick action buttons link to camera
- `MainTabView.swift` - Diet tab includes camera access

## 📱 How It Works

### 1. Photo Capture
- **CalAI-style interface** with crop guides and tips
- **Multiple photo support** for complex meals
- **Real-time preview** with captured images carousel

### 2. AI Recognition Process
```
Photo → OpenAI GPT-4o Vision → Food Identification → Nutrition Database → Results
```

### 3. Nutrition Data Flow
1. **OpenAI Vision** identifies foods and estimates portions
2. **Nutrition APIs** fetch detailed macro/calorie data
3. **Local database** provides fallback for common foods
4. **User editing** allows corrections and adjustments

### 4. User Experience
- **Confidence indicators** show AI certainty
- **Portion size adjustment** with visual guides
- **Edit interface** for corrections
- **Batch adding** for multiple foods

## 🎯 Key Features Matching CalAI

### ✅ Implemented
- [x] Photo-based food recognition
- [x] Real-time nutrition calculation
- [x] Portion size estimation
- [x] Multiple food detection per image
- [x] Confidence scoring
- [x] Food editing and correction
- [x] Comprehensive macro tracking
- [x] Modern, intuitive UI

### 🔄 Enhanced Beyond CalAI
- **Multiple API fallbacks** for better accuracy
- **Offline food database** for basic functionality
- **Integration with fasting tracking**
- **Diet plan goal tracking**
- **Streak and habit tracking**

## 💡 Usage Tips

### For Best Results
1. **Good lighting** - Natural light works best
2. **Clear view** - Center food in frame
3. **Size reference** - Include hand or utensil for scale
4. **Separate dishes** - Individual photos for mixed meals
5. **Multiple angles** - Take 2-3 photos for complex dishes

### Cost Optimization
- Start with **USDA API only** (free) for basic functionality
- Add **OpenAI API** when ready for advanced recognition
- Use **local database** for common foods to reduce API calls

## 🚨 Important Notes

### Security
- **Never commit API keys** to version control
- Consider using **environment variables** or **secure storage**
- **Validate API responses** before processing

### Performance
- **Cache nutrition data** for frequently logged foods
- **Implement retry logic** for failed API calls
- **Show loading states** during processing

### User Experience
- **Always allow manual editing** of AI results
- **Provide confidence indicators** for transparency
- **Offer manual entry** as fallback option

## 🔧 Troubleshooting

### Common Issues
1. **"No food recognized"** - Check lighting and food visibility
2. **Incorrect nutrition data** - Use edit interface to correct
3. **API errors** - Verify keys and check rate limits
4. **Camera permission denied** - Guide user to settings

### Debug Mode
Enable detailed logging in `AIFoodRecognitionService.swift` to troubleshoot recognition issues.

## 📈 Next Steps

### Potential Enhancements
- **Barcode scanning** for packaged foods
- **Recipe recognition** for home-cooked meals
- **Meal planning integration**
- **Social sharing** of meals
- **Advanced analytics** and insights

### Performance Monitoring
- Track **API usage and costs**
- Monitor **recognition accuracy**
- Collect **user feedback** on results
- Optimize **caching strategies**

---

Your Kura app now has CalAI-level food recognition capabilities! The system is designed to be robust, user-friendly, and cost-effective while providing accurate nutrition tracking through AI-powered photo analysis.
