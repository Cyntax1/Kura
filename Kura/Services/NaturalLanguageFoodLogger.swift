//
//  NaturalLanguageFoodLogger.swift
//  Kura
//
//  Parse natural language food descriptions into food entries
//

import Foundation

class NaturalLanguageFoodLogger {
    private let apiKey: String
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
    }
    
    // Parse natural language into food items
    func parseFood(from text: String) async throws -> [ParsedFoodItem] {
        print("🗣️ Parsing: \"\(text)\"")
        
        let prompt = """
        Parse this food description into structured food items with nutrition data:
        "\(text)"
        
        Return ONLY a JSON array of food items:
        [
          {
            "name": "Food Name",
            "quantity": 1.0,
            "unit": "serving/cup/oz/slice/piece",
            "estimated_grams": 150,
            "calories": 250,
            "protein": 20.0,
            "carbs": 30.0,
            "fat": 8.0,
            "fiber": 3.0,
            "sugar": 5.0,
            "sodium": 200
          }
        ]
        
        Examples:
        Input: "2 eggs and toast"
        Output: [
          {"name": "Scrambled Eggs", "quantity": 2, "unit": "eggs", "estimated_grams": 100, "calories": 180, "protein": 12.6, "carbs": 1.2, "fat": 12.0, "fiber": 0, "sugar": 0.5, "sodium": 140},
          {"name": "Toast with Butter", "quantity": 1, "unit": "slice", "estimated_grams": 40, "calories": 120, "protein": 3.0, "carbs": 15.0, "fat": 5.0, "fiber": 1.0, "sugar": 2.0, "sodium": 180}
        ]
        
        Input: "chipotle burrito bowl with chicken"
        Output: [{"name": "Chipotle Chicken Burrito Bowl", "quantity": 1, "unit": "bowl", "estimated_grams": 400, "calories": 650, "protein": 42.0, "carbs": 68.0, "fat": 18.0, "fiber": 10.0, "sugar": 4.0, "sodium": 1200}]
        
        Requirements:
        - Parse all food items mentioned
        - Include quantities if specified
        - Estimate weights in grams
        - Provide accurate nutrition data per 100g USDA database
        - Calculate total nutrition based on actual quantity/weight
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
            "max_tokens": 800,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw FoodLoggerError.noResponse
        }
        
        print("📝 AI Response: \(content)")
        
        return try parseFoodItems(from: content)
    }
    
    private func parseFoodItems(from jsonString: String) throws -> [ParsedFoodItem] {
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw FoodLoggerError.jsonParsingFailed
        }
        
        let items = try JSONDecoder().decode([ParsedFoodItemJSON].self, from: data)
        
        return items.map { json in
            ParsedFoodItem(
                name: json.name,
                quantity: json.quantity,
                unit: json.unit,
                estimatedGrams: json.estimated_grams,
                calories: json.calories,
                protein: json.protein,
                carbs: json.carbs,
                fat: json.fat,
                fiber: json.fiber,
                sugar: json.sugar,
                sodium: json.sodium
            )
        }
    }
}

// MARK: - Models

struct ParsedFoodItem {
    let name: String
    let quantity: Double
    let unit: String
    let estimatedGrams: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    
    var displayQuantity: String {
        if quantity == 1.0 {
            return "1 \(unit)"
        }
        return "\(String(format: "%.1f", quantity)) \(unit)\(quantity > 1 ? "s" : "")"
    }
}

struct ParsedFoodItemJSON: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let estimated_grams: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

enum FoodLoggerError: Error, LocalizedError {
    case noResponse
    case jsonParsingFailed
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from AI service"
        case .jsonParsingFailed:
            return "Failed to parse food items"
        case .noFoodDetected:
            return "No food items detected in your description"
        }
    }
}
