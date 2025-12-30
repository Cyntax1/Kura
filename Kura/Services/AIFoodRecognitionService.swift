//
//  AIFoodRecognitionService.swift
//  Kura
//
//  Enhanced AI Food Recognition Service
//

import Foundation
import UIKit

struct NutritionData {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let servingSize: String
    let confidence: Double
}

struct RecognizedFoodItem {
    let id = UUID()
    let name: String
    let nutrition: NutritionData
    let estimatedWeight: Double // in grams
    let boundingBox: CGRect? // for multi-food detection
}

class AIFoodRecognitionService: ObservableObject {
    private let apiKey: String
    private let nutritionAPI: NutritionAPIService
    
    init(apiKey: String = APIConfig.openAIAPIKey) {
        self.apiKey = apiKey
        // Only using OpenAI API - no other services
        self.nutritionAPI = NutritionAPIService()
    }
    
    // TWO-STEP PROCESS:
    // Step 1: Identify what food is in the photo
    // Step 2: Get simplified nutrition data (food name + calories)
    
    func recognizeFood(from image: UIImage) async throws -> [RecognizedFoodItem] {
        print("🚀 STEP 1: Identifying food in image...")
        
        // Step 1: Identify the food
        let identifiedFoodNames = try await identifyFoodInImage(image: image)
        
        print("✅ STEP 1 COMPLETE: Found \(identifiedFoodNames.count) food(s)")
        identifiedFoodNames.forEach { print("   - \($0)") }
        
        print("🚀 STEP 2: Getting calorie data for each food...")
        
        // Step 2: Get calories for each identified food with actual portion
        var recognizedItems: [RecognizedFoodItem] = []
        
        for (foodName, estimatedWeight) in identifiedFoodNames {
            do {
                let nutritionPer100g = try await getNutritionData(for: foodName)
                
                // Calculate nutrition for actual portion size
                let multiplier = estimatedWeight / 100.0
                let actualNutrition = NutritionData(
                    calories: Int(Double(nutritionPer100g.calories) * multiplier),
                    protein: nutritionPer100g.protein * multiplier,
                    carbs: nutritionPer100g.carbs * multiplier,
                    fat: nutritionPer100g.fat * multiplier,
                    fiber: nutritionPer100g.fiber * multiplier,
                    sugar: nutritionPer100g.sugar * multiplier,
                    sodium: nutritionPer100g.sodium * multiplier,
                    servingSize: "\(Int(estimatedWeight))g",
                    confidence: nutritionPer100g.confidence
                )
                
                print("✅ \(foodName) (~\(Int(estimatedWeight))g): \(actualNutrition.calories) cal")
                
                let item = RecognizedFoodItem(
                    name: foodName,
                    nutrition: actualNutrition,
                    estimatedWeight: estimatedWeight,
                    boundingBox: nil
                )
                recognizedItems.append(item)
            } catch {
                print("⚠️ Failed to get nutrition for \(foodName): \(error)")
                // Continue with other foods
            }
        }
        
        print("✅ STEP 2 COMPLETE: Got data for \(recognizedItems.count) foods")
        return recognizedItems
    }
    
    // STEP 1: Simple food identification from image with portion estimation
    private func identifyFoodInImage(image: UIImage) async throws -> [(name: String, weight: Double)] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Look at this food photo and identify what food items you see, including estimated portion sizes.
        
        Return ONLY a JSON array with food names and estimated weight in grams:
        [{"name": "Food Name", "weight_grams": 250}]
        
        Examples:
        [{"name": "Grilled Chicken Breast", "weight_grams": 150}, {"name": "Brown Rice", "weight_grams": 200}]
        [{"name": "Caesar Salad", "weight_grams": 300}]
        [{"name": "Slice of Pepperoni Pizza", "weight_grams": 120}]
        [{"name": "Large Pizza (whole)", "weight_grams": 900}]
        
        Requirements:
        - Be specific (e.g., "grilled chicken breast" not just "chicken")
        - Include preparation method if visible
        - ESTIMATE the actual portion size visible in the photo (not standard serving)
        - Consider: 1 slice pizza ~120g, whole pizza ~900g, chicken breast ~150g, burger ~200g
        - If it's a slice/piece, estimate that slice weight
        - If it's a whole item, estimate the whole weight
        - List all visible foods
        - Return ONLY the JSON array, no other text
        """
        
        print("🤖 Using OpenAI model: \(APIConfig.visionModel)")
        
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 200
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = httpResponse as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                throw AIError.invalidAPIKey
            case 429:
                throw AIError.rateLimitExceeded
            case 400...499:
                throw AIError.apiKeyMissing
            case 500...599:
                throw AIError.networkError
            default:
                break
            }
        }
        
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw AIError.noResponse
        }
        
        // Parse food names and weights from JSON array
        return try parseFoodNamesWithWeights(from: content)
    }
    
    // STEP 2: Get nutrition data for identified food
    private func getNutritionData(for foodName: String) async throws -> NutritionData {
        let prompt = """
        For the food "\(foodName)", provide calorie and nutrition information.
        
        Return ONLY this JSON format, no other text:
        {
          "calories": 165,
          "protein": 31.0,
          "carbs": 0.0,
          "fat": 3.6,
          "fiber": 0.0,
          "sugar": 0.0,
          "sodium": 74
        }
        
        All values should be per 100 grams.
        Use accurate, research-based nutrition data.
        """
        
        let requestBody: [String: Any] = [
            "model": APIConfig.visionModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 200
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401:
                throw AIError.invalidAPIKey
            case 429:
                throw AIError.rateLimitExceeded
            case 400...499:
                throw AIError.apiKeyMissing
            case 500...599:
                throw AIError.networkError
            default:
                break
            }
        }
        
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw AIError.noResponse
        }
        
        return try parseNutritionData(from: content)
    }
    
    // Parse food names and weights from Step 1 response
    private func parseFoodNamesWithWeights(from jsonString: String) throws -> [(name: String, weight: Double)] {
        // Extract JSON from response (handle markdown formatting)
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw AIError.jsonParsingFailed
        }
        
        struct FoodItem: Codable {
            let name: String
            let weight_grams: Double
        }
        
        let foodItems = try JSONDecoder().decode([FoodItem].self, from: data)
        
        if foodItems.isEmpty {
            throw AIError.noFoodDetected
        }
        
        return foodItems.map { (name: $0.name, weight: $0.weight_grams) }
    }
    
    // Parse nutrition data from Step 2 response
    private func parseNutritionData(from jsonString: String) throws -> NutritionData {
        let cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw AIError.jsonParsingFailed
        }
        
        let nutrition = try JSONDecoder().decode(NutritionJSON.self, from: data)
        
        return NutritionData(
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
            fiber: nutrition.fiber,
            sugar: nutrition.sugar,
            sodium: nutrition.sodium,
            servingSize: "100g",
            confidence: 0.85 // Default confidence for nutrition lookup
        )
    }
}

// MARK: - Supporting Types

struct FoodDescription {
    let name: String
    let estimatedWeight: Double
    let confidence: Double
    let preparation: String?
    let description: String
    let nutrition: NutritionData
    let boundingBox: CGRect?
}

struct FoodDescriptionJSON: Codable {
    let name: String
    let estimated_weight_grams: Double
    let confidence: Double
    let preparation: String?
    let description: String
    let nutrition: NutritionJSON
}

struct NutritionJSON: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
}

enum AIError: Error, LocalizedError {
    case imageProcessingFailed
    case noResponse
    case jsonParsingFailed
    case networkError
    case apiKeyMissing
    case invalidAPIKey
    case rateLimitExceeded
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again with a different photo."
        case .noResponse:
            return "No response from AI service. Check your internet connection."
        case .jsonParsingFailed:
            return "Failed to parse AI response. The service may be temporarily unavailable."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .apiKeyMissing:
            return "OpenAI API key is missing. Please configure your API key in settings."
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key configuration."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again in a few minutes."
        case .noFoodDetected:
            return "No food items were detected in the image. Try taking a clearer photo with better lighting."
        }
    }
}
