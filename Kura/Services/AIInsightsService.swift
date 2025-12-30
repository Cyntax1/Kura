//
//  AIInsightsService.swift
//  Kura
//
//  AI-powered insights and recommendations
//

import Foundation

struct AIInsight: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let category: InsightCategory
    let priority: Priority
    let actionable: Bool
    let timestamp: Date
    
    enum InsightCategory: String, Codable {
        case nutrition = "Nutrition"
        case fasting = "Fasting"
        case progress = "Progress"
        case suggestion = "Suggestion"
        case achievement = "Achievement"
        case warning = "Warning"
    }
    
    enum Priority: String, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
    
    var icon: String {
        switch category {
        case .nutrition: return "fork.knife"
        case .fasting: return "clock.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .suggestion: return "lightbulb.fill"
        case .achievement: return "trophy.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch category {
        case .nutrition: return "green"
        case .fasting: return "blue"
        case .progress: return "purple"
        case .suggestion: return "orange"
        case .achievement: return "yellow"
        case .warning: return "red"
        }
    }
}

class AIInsightsService {
    private let apiKey: String
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    // Generate weekly insights
    func generateWeeklyInsights(analysisData: UserAnalysisData) async throws -> [AIInsight] {
        print("📊 Generating weekly insights...")
        
        let prompt = """
        Analyze this user's health data from the past week and provide 3-5 personalized insights.
        
        User Data:
        - Average daily calories: \(analysisData.avgDailyCalories) kcal (Goal: \(analysisData.dailyCalorieGoal))
        - Average protein: \(String(format: "%.1f", analysisData.avgProtein))g
        - Average carbs: \(String(format: "%.1f", analysisData.avgCarbs))g
        - Average fat: \(String(format: "%.1f", analysisData.avgFat))g
        - Fasting sessions completed: \(analysisData.fastingSessionsCompleted)
        - Current fasting streak: \(analysisData.currentStreak) days
        - Days over calorie goal: \(analysisData.daysOverGoal) / 7
        - Workouts completed: \(analysisData.workoutsCompleted)
        - Average calories burned: \(analysisData.avgCaloriesBurned) kcal
        - Most eaten foods: \(analysisData.topFoods.joined(separator: ", "))
        
        Return ONLY a JSON array of insights:
        [
          {
            "title": "Short Title",
            "message": "Detailed message with specific advice (2-3 sentences)",
            "category": "nutrition|fasting|progress|suggestion|achievement|warning",
            "priority": "high|medium|low",
            "actionable": true
          }
        ]
        
        Guidelines:
        - Focus on actionable, specific advice
        - Celebrate achievements
        - Identify patterns and trends
        - Suggest improvements for areas below target
        - Be encouraging and supportive
        - Provide 3-5 insights (most important ones)
        - Return ONLY the JSON array, no other text
        """
        
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 1000,
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
            throw NSError(domain: "AIInsightsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response"])
        }
        
        print("📝 AI Insights Response received")
        
        return try parseInsights(from: content)
    }
    
    // Get quick meal suggestion
    func suggestMeal(caloriesRemaining: Int, timeOfDay: String, dietType: String) async throws -> MealSuggestion {
        let prompt = """
        Suggest a meal for \(timeOfDay) with approximately \(caloriesRemaining) calories, suitable for a \(dietType) diet.
        
        Return ONLY this JSON format:
        {
          "name": "Meal Name",
          "description": "Brief description",
          "calories": \(caloriesRemaining),
          "protein": 30.0,
          "carbs": 40.0,
          "fat": 15.0,
          "ingredients": ["ingredient 1", "ingredient 2"],
          "prep_time_minutes": 15
        }
        """
        
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 400,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "AIInsightsService", code: 0)
        }
        
        return try parseMealSuggestion(from: content)
    }
    
    private func parseInsights(from jsonString: String) throws -> [AIInsight] {
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw NSError(domain: "AIInsightsService", code: 1)
        }
        
        struct InsightJSON: Codable {
            let title: String
            let message: String
            let category: String
            let priority: String
            let actionable: Bool
        }
        
        let insights = try JSONDecoder().decode([InsightJSON].self, from: data)
        
        return insights.map { json in
            AIInsight(
                id: UUID(),
                title: json.title,
                message: json.message,
                category: AIInsight.InsightCategory(rawValue: json.category) ?? .suggestion,
                priority: AIInsight.Priority(rawValue: json.priority) ?? .medium,
                actionable: json.actionable,
                timestamp: Date()
            )
        }
    }
    
    private func parseMealSuggestion(from jsonString: String) throws -> MealSuggestion {
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw NSError(domain: "AIInsightsService", code: 1)
        }
        
        return try JSONDecoder().decode(MealSuggestion.self, from: data)
    }
}

// MARK: - Models

struct UserAnalysisData {
    let avgDailyCalories: Int
    let dailyCalorieGoal: Int
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let fastingSessionsCompleted: Int
    let currentStreak: Int
    let daysOverGoal: Int
    let workoutsCompleted: Int
    let avgCaloriesBurned: Int
    let topFoods: [String]
}

struct MealSuggestion: Codable {
    let name: String
    let description: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let ingredients: [String]
    let prep_time_minutes: Int
    
    var prepTimeFormatted: String {
        "\(prep_time_minutes) min"
    }
}
