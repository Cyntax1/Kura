//
//  AIChatbotService.swift
//  Kura
//
//  AI Chatbot that knows everything about the user
//

import Foundation
import SwiftData

class AIChatbotService: ObservableObject {
    private let apiKey: String
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    // Generate comprehensive system prompt with ALL user data
    func generateSystemPrompt(
        userProfile: UserProfile?,
        fastingSessions: [FastingSession],
        foodEntries: [FoodEntry],
        dietPlans: [DietPlan]
    ) -> String {
        var prompt = """
        You are Kura AI, a personal health and wellness assistant. You have complete access to the user's health data and are here to provide personalized advice, answer questions, and help them achieve their health goals.
        
        BE CONVERSATIONAL, FRIENDLY, AND SUPPORTIVE. Use emojis when appropriate 😊
        
        """
        
        // USER PROFILE DATA
        if let profile = userProfile {
            prompt += """
            
            ## USER PROFILE:
            - Name: \(profile.name)
            """
            
            if let age = profile.age {
                prompt += "\n- Age: \(age) years old"
            }
            
            if let weight = profile.weight {
                prompt += "\n- Current Weight: \(String(format: "%.1f", weight)) kg (\(String(format: "%.1f", weight * 2.20462)) lbs)"
            }
            
            if let targetWeight = profile.targetWeight {
                prompt += "\n- Target Weight: \(String(format: "%.1f", targetWeight)) kg (\(String(format: "%.1f", targetWeight * 2.20462)) lbs)"
            }
            
            if let height = profile.height {
                prompt += "\n- Height: \(String(format: "%.1f", height)) cm (\(String(format: "%.1f", height / 2.54)) inches)"
            }
            
            if let gender = profile.gender {
                prompt += "\n- Gender: \(gender.rawValue)"
            }
            
            prompt += "\n- Activity Level: \(profile.activityLevel.rawValue) - \(profile.activityLevel.description)"
            prompt += "\n- Daily Calorie Goal: \(profile.dailyCalorieGoal) calories"
            prompt += "\n- Daily Water Goal: \(String(format: "%.1f", profile.dailyWaterGoal)) liters"
            
            if let bmi = profile.bmi {
                prompt += "\n- BMI: \(String(format: "%.1f", bmi)) (\(profile.bmiCategory))"
            }
            
            if let bmr = profile.bmr {
                prompt += "\n- BMR (Basal Metabolic Rate): \(String(format: "%.0f", bmr)) calories/day"
            }
            
            if let tdee = profile.tdee {
                prompt += "\n- TDEE (Total Daily Energy Expenditure): \(String(format: "%.0f", tdee)) calories/day"
            }
            
            if !profile.preferredFastingTypes.isEmpty {
                prompt += "\n- Preferred Fasting Types: \(profile.preferredFastingTypes.map { $0.rawValue }.joined(separator: ", "))"
            }
            
            if !profile.preferredDietTypes.isEmpty {
                prompt += "\n- Preferred Diet Types: \(profile.preferredDietTypes.map { $0.rawValue }.joined(separator: ", "))"
            }
        } else {
            prompt += "\n## USER PROFILE: Not set up yet - encourage them to complete their profile!"
        }
        
        // ACTIVE DIET PLAN
        let activeDiet = dietPlans.first { $0.isActive }
        if let diet = activeDiet {
            prompt += """
            
            
            ## CURRENT DIET PLAN:
            - Type: \(diet.type.rawValue)
            - Name: \(diet.name)
            - Description: \(diet.dietDescription)
            - Daily Calorie Goal: \(diet.dailyCalorieGoal) calories
            - Macro Goals: \(diet.proteinGoal)g protein, \(diet.carbGoal)g carbs, \(diet.fatGoal)g fat
            - Started: \(formatDate(diet.startDate))
            """
            
            if let daysRemaining = diet.daysRemaining {
                prompt += "\n- Days Remaining: \(daysRemaining) days"
            }
        }
        
        // FASTING HISTORY & STATS
        if !fastingSessions.isEmpty {
            let completedFasts = fastingSessions.filter { $0.isCompleted }
            let activeFast = fastingSessions.first { $0.isActive }
            let totalFasts = completedFasts.count
            let totalHoursFasted = completedFasts.reduce(0.0) { $0 + $1.actualDuration } / 3600
            
            prompt += """
            
            
            ## FASTING HISTORY:
            - Total Fasts Completed: \(totalFasts)
            - Total Hours Fasted: \(String(format: "%.1f", totalHoursFasted)) hours
            """
            
            if let activeFast = activeFast {
                let hoursElapsed = activeFast.currentDuration / 3600
                let hoursRemaining = activeFast.remainingTime / 3600
                let progressPercent = activeFast.progressPercentage * 100
                
                prompt += """
                
                - CURRENTLY FASTING: \(activeFast.type.rawValue)
                  - Status: \(activeFast.status.rawValue)
                  - Hours Elapsed: \(String(format: "%.1f", hoursElapsed))h
                  - Hours Remaining: \(String(format: "%.1f", hoursRemaining))h
                  - Progress: \(String(format: "%.1f", progressPercent))%
                  - Started: \(formatTime(activeFast.startTime))
                """
                
                if !activeFast.notes.isEmpty {
                    prompt += "\n  - Notes: \(activeFast.notes)"
                }
            }
            
            // Recent fasting sessions (last 5)
            let recentFasts = completedFasts.sorted { $0.startTime > $1.startTime }.prefix(5)
            if !recentFasts.isEmpty {
                prompt += "\n\nRecent Fasts:"
                for fast in recentFasts {
                    let hours = fast.actualDuration / 3600
                    prompt += "\n  - \(formatDate(fast.startTime)): \(fast.type.rawValue) - \(String(format: "%.1f", hours))h"
                }
            }
        }
        
        // FOOD & NUTRITION TRACKING
        if !foodEntries.isEmpty {
            let today = Calendar.current.startOfDay(for: Date())
            let todaysFoods = foodEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
            
            let todaysCalories = todaysFoods.reduce(0) { $0 + $1.calories }
            let todaysProtein = todaysFoods.reduce(0.0) { $0 + $1.protein }
            let todaysCarbs = todaysFoods.reduce(0.0) { $0 + $1.carbs }
            let todaysFat = todaysFoods.reduce(0.0) { $0 + $1.fat }
            
            prompt += """
            
            
            ## TODAY'S NUTRITION:
            - Calories Consumed: \(todaysCalories) cal
            - Protein: \(String(format: "%.1f", todaysProtein))g
            - Carbs: \(String(format: "%.1f", todaysCarbs))g
            - Fat: \(String(format: "%.1f", todaysFat))g
            - Meals Logged: \(todaysFoods.count)
            """
            
            if !todaysFoods.isEmpty {
                prompt += "\n\nToday's Meals:"
                for food in todaysFoods.sorted(by: { $0.timestamp < $1.timestamp }) {
                    prompt += "\n  - \(formatTime(food.timestamp)) - \(food.mealType.rawValue): \(food.name) (\(food.calories) cal)"
                }
            }
            
            // Weekly averages
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let weeklyFoods = foodEntries.filter { $0.timestamp >= weekAgo }
            
            if !weeklyFoods.isEmpty {
                let daysWithFood = Set(weeklyFoods.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
                let avgCalories = weeklyFoods.reduce(0) { $0 + $1.calories } / max(1, daysWithFood)
                let avgProtein = weeklyFoods.reduce(0.0) { $0 + $1.protein } / Double(max(1, daysWithFood))
                
                prompt += """
                
                
                ## WEEKLY AVERAGES (Last 7 Days):
                - Average Daily Calories: \(avgCalories) cal
                - Average Daily Protein: \(String(format: "%.1f", avgProtein))g
                - Days Tracked: \(daysWithFood)/7
                """
            }
            
            // Most common foods
            let foodCounts = Dictionary(grouping: foodEntries, by: { $0.name })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(5)
            
            if !foodCounts.isEmpty {
                prompt += "\n\nMost Frequently Eaten Foods:"
                for (food, count) in foodCounts {
                    prompt += "\n  - \(food) (\(count) times)"
                }
            }
        }
        
        prompt += """
        
        
        ## YOUR ROLE:
        - Answer questions about their health data
        - Provide personalized nutrition and fasting advice
        - Offer encouragement and motivation
        - Suggest healthy recipes and meal ideas
        - Help them stay on track with their goals
        - Explain their metrics (BMI, BMR, TDEE, etc.)
        - Be supportive, not judgmental
        - Use their actual data when giving advice
        
        IMPORTANT: Always reference their specific data when relevant. Make your responses personal and actionable!
        """
        
        return prompt
    }
    
    // Send message to GPT with full context
    func sendMessage(
        userMessage: String,
        conversationHistory: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        
        // Build messages array with system prompt + history + new message
        var messages: [[String: Any]] = []
        
        // Add system prompt
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Add conversation history (last 20 messages to avoid token limits)
        let recentHistory = conversationHistory.suffix(20)
        for message in recentHistory {
            messages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        // Add new user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: URL(string: APIConfig.Endpoints.openAI)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        // Check for errors
        if let httpResponse = httpResponse as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                throw ChatbotError.invalidAPIKey
            case 429:
                throw ChatbotError.rateLimitExceeded
            case 400...499:
                throw ChatbotError.apiError("Client error: \(httpResponse.statusCode)")
            case 500...599:
                throw ChatbotError.apiError("Server error: \(httpResponse.statusCode)")
            default:
                break
            }
        }
        
        let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw ChatbotError.noResponse
        }
        
        return content
    }
    
    // Helper functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Response Models

struct OpenAIChatResponse: Codable {
    let choices: [ChatChoice]
    
    struct ChatChoice: Codable {
        let message: ChatMessageContent
        
        struct ChatMessageContent: Codable {
            let content: String
        }
    }
}

enum ChatbotError: Error, LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case noResponse
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI configuration."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .noResponse:
            return "No response from AI. Please try again."
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError:
            return "Network error. Check your internet connection."
        }
    }
}
