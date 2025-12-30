//
//  NutritionAPIService.swift
//  Kura
//
//  Comprehensive nutrition database service
//

import Foundation

class NutritionAPIService {
    // NO EXTERNAL APIs - GPT provides all nutrition data!
    // This service only provides local fallback data if needed
    
    init() {
        // No API keys needed - GPT handles everything
        print("✅ NutritionAPIService: Using local database only (GPT provides all data)")
    }
    
    func getNutritionData(for foodDescription: String) async throws -> NutritionData? {
        // GPT provides all nutrition data now!
        // This is only used as a fallback if GPT fails
        print("ℹ️ Using local nutrition database for: \(foodDescription)")
        return getLocalNutritionData(for: foodDescription)
    }
    
    // REMOVED - No external APIs needed anymore!
    // GPT provides all nutrition data directly
    
    private func getLocalNutritionData(for foodDescription: String) -> NutritionData? {
        // Local fallback database for common foods
        let localFoods: [String: NutritionData] = [
            "chicken breast": NutritionData(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74, servingSize: "100g", confidence: 0.8),
            "brown rice": NutritionData(calories: 111, protein: 2.6, carbs: 23, fat: 0.9, fiber: 1.8, sugar: 0.4, sodium: 5, servingSize: "100g", confidence: 0.8),
            "broccoli": NutritionData(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5, sodium: 33, servingSize: "100g", confidence: 0.8),
            "salmon": NutritionData(calories: 208, protein: 20, carbs: 0, fat: 12, fiber: 0, sugar: 0, sodium: 59, servingSize: "100g", confidence: 0.8),
            "avocado": NutritionData(calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 0.7, sodium: 7, servingSize: "100g", confidence: 0.8),
            "banana": NutritionData(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12, sodium: 1, servingSize: "100g", confidence: 0.8),
            "eggs": NutritionData(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1, sodium: 124, servingSize: "100g", confidence: 0.8)
        ]
        
        let lowercaseFood = foodDescription.lowercased()
        for (key, nutrition) in localFoods {
            if lowercaseFood.contains(key) {
                return nutrition
            }
        }
        
        return nil
    }
}

// MARK: - Note
// All external API models removed - GPT provides everything now!
// No Edamam, USDA, or other API dependencies
