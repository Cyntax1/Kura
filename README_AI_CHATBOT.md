# AI Chatbot Assistant - Kura

Your personal AI health coach that knows **everything** about you! 🧠✨

## 🎯 What It Does

The AI chatbot has complete access to ALL your health data and provides personalized advice:

### Data the Chatbot Knows:

#### 📊 Your Profile
- Name, age, weight, height
- Target weight goals
- Gender and activity level
- BMI, BMR, and TDEE calculations
- Daily calorie and water goals
- Preferred fasting and diet types

#### ⏰ Fasting History
- All completed fasting sessions
- Total fasts completed
- Total hours fasted
- Current active fasting session (if any)
- Progress, time remaining, and status
- Recent fasting patterns

#### 🍽️ Nutrition Tracking
- Today's meals and calories
- Complete macro breakdown (protein, carbs, fat)
- Weekly averages
- Most frequently eaten foods
- Meal timing patterns

#### 🎯 Diet Plans
- Current active diet plan
- Diet type and goals
- Daily calorie and macro targets
- Progress and days remaining

## 💬 Example Conversations

### Ask About Your Stats
```
You: "How am I doing today?"

AI: "Great question! 😊 Today you've consumed 1,450 calories out of 
your 2,000 goal. You've had 85g protein (great!), 120g carbs, and 
45g fat. You're currently 18 hours into your intermittent fast with 
only 2 hours to go - you're crushing it! 🎉"
```

### Get Personalized Advice
```
You: "What should I eat for dinner?"

AI: "Based on your goals, you have 550 calories left today and need 
more protein (only 85g of your 150g goal). I'd recommend grilled 
salmon with roasted vegetables - that would give you ~400 cal and 
40g protein, keeping you on track! 🐟"
```

### Ask About Progress
```
You: "Am I losing weight on pace?"

AI: "Let me check! Your current weight is 75kg and target is 70kg. 
Over the last 7 days, you've averaged 1,850 cal/day against your 
2,000 goal. With your TDEE of 2,400 cal, that's a deficit of 550 
cal/day. At this rate, you're on track to lose 0.5kg per week - 
perfect for sustainable weight loss! 🎯"
```

### Get Fasting Tips
```
You: "I'm struggling with hunger during my fast"

AI: "I see you're 14 hours into your 18-hour intermittent fast. 
Here are some tips that work well:
- Drink more water (you're aiming for 2L/day)
- Try herbal tea or black coffee
- Stay busy to avoid thinking about food
- Remember, you've successfully completed 12 fasts before - you can do this! 💪"
```

## 🚀 How to Use

### Access the Chatbot
1. **From Home Screen**: Tap the brain icon (🧠) in the top right
2. The chatbot opens in a full-screen chat interface

### Features

#### 💭 Chat Interface
- Modern chat bubbles (blue for you, gray for AI)
- Timestamps on all messages
- Smooth scrolling and animations
- Loading indicators while AI thinks

#### ⚙️ Menu Options (Top Right)
- **Refresh My Data**: Updates AI with latest health data
- **View My Data**: Shows exactly what data the AI has
- **Clear Chat**: Removes all conversation history

#### 📱 Smart Input
- Multi-line text support
- Auto-scrolls to new messages
- Keyboard dismissal

## 🧠 How It Works

### 1. Data Collection
Every time you send a message, the chatbot:
```swift
1. Fetches your UserProfile
2. Loads all FastingSessions
3. Gets all FoodEntries
4. Retrieves DietPlans
5. Calculates stats and averages
```

### 2. Context Generation
Creates a comprehensive system prompt like:
```
## USER PROFILE:
- Name: John
- Age: 28 years old
- Current Weight: 75.0 kg (165.3 lbs)
- Target Weight: 70.0 kg (154.3 lbs)
- BMI: 24.5 (Normal)
- TDEE: 2,400 calories/day
...

## CURRENT DIET PLAN:
- Type: High Protein
- Daily Goals: 2000 cal, 150g protein, 180g carbs, 60g fat
...

## TODAY'S NUTRITION:
- Calories: 1,450 cal
- Protein: 85g
- Meals Logged: 3
...
```

### 3. AI Response
- Sends to GPT-4o with full context
- AI responds with personalized advice
- Saves conversation to SwiftData

## 🎨 Features

### ✨ Smart Features
- **Context Awareness**: AI knows your entire health journey
- **Personalized Advice**: Recommendations based on YOUR data
- **Real-time Updates**: Always uses latest data
- **Conversation Memory**: Remembers chat history
- **Error Handling**: Graceful failures with helpful messages

### 🔒 Privacy & Transparency
- **View Your Data**: See exactly what the AI knows
- **Local Storage**: Chats saved in SwiftData
- **API Security**: Uses your OpenAI API key
- **Clear Anytime**: Delete chat history whenever you want

## 💡 Pro Tips

### Get Better Responses
1. **Be Specific**: "What should I eat?" vs "What high-protein dinner fits my remaining calories?"
2. **Ask Follow-ups**: The AI remembers the conversation context
3. **Use it Daily**: Check in for motivation and progress tracking
4. **Request Analysis**: "Analyze my eating patterns this week"

### Smart Questions to Ask
- "How many calories can I eat today?"
- "What's my progress toward my goal?"
- "Give me a meal plan for tomorrow"
- "Why am I not losing weight?"
- "Compare this week to last week"
- "What fasting schedule works best for me?"
- "Am I getting enough protein?"

## 📋 Files Created

```
Kura/
├── Models/
│   └── ChatMessage.swift              # Chat conversation model
├── Services/
│   └── AIChatbotService.swift         # AI service with context
└── Views/
    └── AI/
        └── AIChatbotView.swift        # Chat interface
```

## 🔧 Technical Details

### Models
- **ChatMessage**: Stores chat history with roles (user/assistant/system)
- Integrated with SwiftData for persistence

### Service
- **AIChatbotService**: 
  - Generates comprehensive system prompts
  - Manages conversation context
  - Handles API communication
  - Formats dates and statistics

### View
- **AIChatbotView**:
  - Modern chat UI with bubbles
  - Real-time message updates
  - Error handling and loading states
  - Menu for data management

### Integration
- Button in HomeView header (brain icon)
- Sheet presentation for full-screen chat
- SwiftData queries for all health data

## 🚨 Requirements

- OpenAI API key configured in `APIConfig.swift`
- SwiftData models: UserProfile, FastingSession, FoodEntry, DietPlan
- iOS 17+ for SwiftData support

## 💰 API Usage

- Uses GPT-4o model (same as food recognition)
- ~$0.01-0.03 per conversation exchange
- Conversation history included (last 20 messages)
- Token usage tracked (optional)

## 🎉 Benefits

1. **Personalized Coaching**: AI knows YOUR specific situation
2. **24/7 Availability**: Get advice anytime
3. **Data-Driven Insights**: Recommendations based on actual data
4. **Motivational Support**: Encouraging feedback on progress
5. **Educational**: Learn about nutrition, BMI, TDEE, etc.
6. **Convenient**: No need to manually explain your situation

---

**Your health data + GPT-4o = Your personal AI nutritionist, fasting coach, and motivator! 🚀**

Start chatting by tapping the 🧠 icon on your home screen!
