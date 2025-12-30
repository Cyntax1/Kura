//
//  OfflineFoodRecognitionService.swift
//  Kura
//
//  Open-source, offline food recognition using CoreML and Vision
//

import Foundation
import UIKit
import Vision
import CoreML

class OfflineFoodRecognitionService: ObservableObject {
    private var foodClassifier: VNCoreMLModel?
    private let nutritionDatabase = OfflineNutritionDatabase()
    
    init() {
        setupFoodClassifier()
    }
    
    func recognizeFood(from image: UIImage) async throws -> [RecognizedFoodItem] {
        // Step 1: Use Vision + CoreML for food classification
        let classifiedFoods = try await classifyFoodsWithVision(image: image)
        
        // Step 2: Get nutrition data from local database
        var recognizedItems: [RecognizedFoodItem] = []
        
        for classification in classifiedFoods {
            if let nutritionData = nutritionDatabase.getNutritionData(for: classification.identifier) {
                let item = RecognizedFoodItem(
                    name: classification.displayName,
                    nutrition: nutritionData,
                    estimatedWeight: estimatePortionSize(for: classification, in: image),
                    boundingBox: classification.boundingBox
                )
                recognizedItems.append(item)
            }
        }
        
        return recognizedItems
    }
    
    private func setupFoodClassifier() {
        // Try to load a food classification model
        // You can use Apple's built-in food classifier or train your own
        
        // Option 1: Use built-in Vision food classifier (iOS 15+)
        if #available(iOS 15.0, *) {
            // Vision framework has built-in food recognition
            // We'll use this in the classification method
        }
        
        // Option 2: Load custom CoreML model (if you have one)
        // loadCustomFoodModel()
    }
    
    private func classifyFoodsWithVision(image: UIImage) async throws -> [FoodClassification] {
        guard let cgImage = image.cgImage else {
            throw OfflineRecognitionError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use Vision's built-in image classifier
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Filter for food-related classifications
                let foodClassifications = observations
                    .filter { $0.confidence > 0.3 && self.isFoodRelated($0.identifier) }
                    .prefix(5) // Top 5 results
                    .map { observation in
                        FoodClassification(
                            identifier: observation.identifier,
                            displayName: self.cleanFoodName(observation.identifier),
                            confidence: Double(observation.confidence),
                            boundingBox: nil // Vision classification doesn't provide bounding boxes
                        )
                    }
                
                continuation.resume(returning: Array(foodClassifications))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func isFoodRelated(_ identifier: String) -> Bool {
        let foodKeywords = [
            "food", "meal", "dish", "fruit", "vegetable", "meat", "chicken", "beef", "fish",
            "bread", "rice", "pasta", "pizza", "sandwich", "salad", "soup", "burger",
            "apple", "banana", "orange", "tomato", "potato", "carrot", "broccoli",
            "cheese", "milk", "egg", "yogurt", "cereal", "cookie", "cake", "pie"
        ]
        
        let lowerIdentifier = identifier.lowercased()
        return foodKeywords.contains { lowerIdentifier.contains($0) }
    }
    
    private func cleanFoodName(_ identifier: String) -> String {
        // Convert Vision identifiers to readable food names
        let cleaned = identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
        
        // Map common Vision identifiers to better food names
        let mappings: [String: String] = [
            "Granny Smith": "Green Apple",
            "Golden Delicious": "Yellow Apple",
            "French Fries": "French Fries",
            "Hamburger": "Burger",
            "Hot Dog": "Hot Dog",
            "Pizza": "Pizza Slice"
        ]
        
        return mappings[cleaned] ?? cleaned
    }
    
    private func estimatePortionSize(for classification: FoodClassification, in image: UIImage) -> Double {
        // Simple portion size estimation based on food type
        // In a real app, you might use object detection to measure relative size
        
        let baseSizes: [String: Double] = [
            "apple": 150,      // grams
            "banana": 120,
            "orange": 130,
            "chicken": 100,    // 100g serving
            "beef": 100,
            "fish": 100,
            "bread": 30,       // 1 slice
            "rice": 150,       // cooked cup
            "pasta": 100,      // dry weight
            "pizza": 200,      // 2 slices
            "salad": 85        // 1 cup
        ]
        
        let foodType = classification.identifier.lowercased()
        
        for (key, size) in baseSizes {
            if foodType.contains(key) {
                // Adjust size based on confidence (lower confidence = more conservative estimate)
                return size * (0.7 + (classification.confidence * 0.3))
            }
        }
        
        return 100 // Default 100g serving
    }
}

// MARK: - Supporting Types

struct FoodClassification {
    let identifier: String
    let displayName: String
    let confidence: Double
    let boundingBox: CGRect?
}

enum OfflineRecognitionError: Error {
    case imageProcessingFailed
    case modelLoadingFailed
    case classificationFailed
}

// MARK: - Offline Nutrition Database

class OfflineNutritionDatabase {
    private let nutritionData: [String: NutritionData]
    
    init() {
        // Load comprehensive nutrition database from local JSON
        self.nutritionData = Self.loadNutritionDatabase()
    }
    
    func getNutritionData(for foodIdentifier: String) -> NutritionData? {
        let cleanIdentifier = foodIdentifier.lowercased()
        
        // Direct lookup
        if let data = nutritionData[cleanIdentifier] {
            return data
        }
        
        // Fuzzy matching for similar foods
        for (key, data) in nutritionData {
            if cleanIdentifier.contains(key) || key.contains(cleanIdentifier) {
                return data
            }
        }
        
        return nil
    }
    
    private static func loadNutritionDatabase() -> [String: NutritionData] {
        // Comprehensive nutrition database for common foods
        // This would normally be loaded from a JSON file or Core Data
        
        return [
            // Fruits
            "apple": NutritionData(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, sugar: 10, sodium: 1, servingSize: "100g", confidence: 0.95),
            "banana": NutritionData(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, sugar: 12, sodium: 1, servingSize: "100g", confidence: 0.95),
            "orange": NutritionData(calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4, sugar: 9, sodium: 0, servingSize: "100g", confidence: 0.95),
            "grapes": NutritionData(calories: 62, protein: 0.6, carbs: 16, fat: 0.2, fiber: 0.9, sugar: 16, sodium: 2, servingSize: "100g", confidence: 0.95),
            
            // Vegetables
            "broccoli": NutritionData(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, sugar: 1.5, sodium: 33, servingSize: "100g", confidence: 0.95),
            "carrot": NutritionData(calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, sugar: 4.7, sodium: 69, servingSize: "100g", confidence: 0.95),
            "tomato": NutritionData(calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, sugar: 2.6, sodium: 5, servingSize: "100g", confidence: 0.95),
            "lettuce": NutritionData(calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3, sugar: 0.8, sodium: 28, servingSize: "100g", confidence: 0.95),
            
            // Proteins
            "chicken": NutritionData(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74, servingSize: "100g", confidence: 0.9),
            "beef": NutritionData(calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0, sugar: 0, sodium: 72, servingSize: "100g", confidence: 0.9),
            "fish": NutritionData(calories: 206, protein: 22, carbs: 0, fat: 12, fiber: 0, sugar: 0, sodium: 59, servingSize: "100g", confidence: 0.9),
            "salmon": NutritionData(calories: 208, protein: 20, carbs: 0, fat: 12, fiber: 0, sugar: 0, sodium: 59, servingSize: "100g", confidence: 0.9),
            "egg": NutritionData(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sugar: 1.1, sodium: 124, servingSize: "100g", confidence: 0.95),
            
            // Grains & Starches
            "rice": NutritionData(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sugar: 0.1, sodium: 1, servingSize: "100g", confidence: 0.9),
            "bread": NutritionData(calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7, sugar: 5, sodium: 491, servingSize: "100g", confidence: 0.9),
            "pasta": NutritionData(calories: 131, protein: 5, carbs: 25, fat: 1.1, fiber: 1.8, sugar: 0.6, sodium: 1, servingSize: "100g", confidence: 0.9),
            "potato": NutritionData(calories: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2, sugar: 0.8, sodium: 6, servingSize: "100g", confidence: 0.95),
            
            // Dairy
            "milk": NutritionData(calories: 42, protein: 3.4, carbs: 5, fat: 1, fiber: 0, sugar: 5, sodium: 44, servingSize: "100ml", confidence: 0.95),
            "cheese": NutritionData(calories: 113, protein: 7, carbs: 1, fat: 9, fiber: 0, sugar: 1, sodium: 621, servingSize: "100g", confidence: 0.9),
            "yogurt": NutritionData(calories: 59, protein: 10, carbs: 3.6, fat: 0.4, fiber: 0, sugar: 3.2, sodium: 36, servingSize: "100g", confidence: 0.9),
            
            // Fast Food / Common Items
            "pizza": NutritionData(calories: 266, protein: 11, carbs: 33, fat: 10, fiber: 2.3, sugar: 3.6, sodium: 598, servingSize: "100g", confidence: 0.85),
            "burger": NutritionData(calories: 295, protein: 17, carbs: 23, fat: 16, fiber: 2, sugar: 3, sodium: 497, servingSize: "100g", confidence: 0.85),
            "french fries": NutritionData(calories: 365, protein: 4, carbs: 63, fat: 17, fiber: 4, sugar: 0.3, sodium: 246, servingSize: "100g", confidence: 0.85),
            "sandwich": NutritionData(calories: 250, protein: 12, carbs: 30, fat: 8, fiber: 3, sugar: 4, sodium: 450, servingSize: "100g", confidence: 0.8),
            
            // Snacks & Desserts
            "cookie": NutritionData(calories: 502, protein: 5.9, carbs: 64, fat: 25, fiber: 2.4, sugar: 40, sodium: 386, servingSize: "100g", confidence: 0.8),
            "cake": NutritionData(calories: 399, protein: 4.9, carbs: 63, fat: 15, fiber: 1.4, sugar: 45, sodium: 337, servingSize: "100g", confidence: 0.8),
            "ice cream": NutritionData(calories: 207, protein: 3.5, carbs: 24, fat: 11, fiber: 0.7, sugar: 21, sodium: 80, servingSize: "100g", confidence: 0.8)
        ]
    }
}
