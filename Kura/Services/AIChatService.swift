//
//  AIChatService.swift
//  Kura
//
//  AI Chat Assistant for nutrition and fasting advice
//

import Foundation
import SwiftUI
import SwiftData

class AIChatService: ObservableObject {
    @Published var isLoading = false
    
    private let apiKey: String
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    // Send message with user context - returns AI response
    func sendMessage(_ userMessage: String, context: UserContext, conversationHistory: [ChatMessage]) async -> String {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            let response = try await getAIResponse(userMessage: userMessage, context: context, conversationHistory: conversationHistory)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return response
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return "Sorry, I couldn't process that. Please try again."
        }
    }
    
    private func getAIResponse(userMessage: String, context: UserContext, conversationHistory: [ChatMessage]) async throws -> String {
        // Build context-aware system prompt
        let systemPrompt = """
        You are Kura AI, a personal nutrition and fasting coach. You help users with:
        - Nutrition advice and meal planning
        - Fasting strategies and tips
        - Calorie and macro tracking guidance
        - Health and wellness questions
        
        Current User Context:
        - Daily Calorie Goal: \(context.dailyCalorieGoal) kcal
        - Today's Calories: \(context.caloriesConsumed) kcal consumed
        - Calories Burned: \(context.caloriesBurned) kcal
        - Net Calories: \(context.caloriesConsumed - context.caloriesBurned) kcal
        - Fasting Status: \(context.currentFastingStatus)
        - Active Fast Duration: \(context.currentFastDuration)
        \(context.recentMeals.isEmpty ? "" : "- Recent Meals: \(context.recentMeals.joined(separator: ", "))")
        
        Guidelines:
        - Be encouraging and supportive
        - Give specific, actionable advice
        - Use the user's context to personalize responses
        - Keep responses concise (2-4 paragraphs max)
        - Use emojis occasionally for friendliness
        - If asked about medical conditions, remind them to consult a doctor
        """
        
        // Build conversation with system prompt + history
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        // Add recent conversation history (last 10 messages)
        let recentMessages = conversationHistory.suffix(10)
        for msg in recentMessages {
            if msg.role != .system {
                messages.append(["role": msg.role.rawValue, "content": msg.content])
            }
        }
        
        // Add current message
        messages.append(["role": "user", "content": userMessage])
        
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "AIChatService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response"])
        }
        
        return content
    }
}

// User context for personalized responses
struct UserContext {
    let dailyCalorieGoal: Int
    let caloriesConsumed: Int
    let caloriesBurned: Int
    let currentFastingStatus: String
    let currentFastDuration: String
    let recentMeals: [String]
    let dietType: String
    
    static var empty: UserContext {
        return UserContext(
            dailyCalorieGoal: 2000,
            caloriesConsumed: 0,
            caloriesBurned: 0,
            currentFastingStatus: "Not fasting",
            currentFastDuration: "0h",
            recentMeals: [],
            dietType: "None"
        )
    }
}
