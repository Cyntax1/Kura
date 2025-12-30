//
//  FoodEntry.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID
    var name: String
    var calories: Int
    var protein: Double // grams
    var carbs: Double // grams
    var fat: Double // grams
    var fiber: Double // grams
    var sugar: Double // grams
    var sodium: Double // mg
    var quantity: Double
    var unit: String
    var mealType: MealType
    var timestamp: Date
    var imageData: Data?
    var isAIRecognized: Bool
    var confidence: Double // AI recognition confidence 0-1
    var notes: String
    
    init(name: String, calories: Int, protein: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double = 0, sugar: Double = 0, sodium: Double = 0, quantity: Double = 1, unit: String = "serving", mealType: MealType = .other, imageData: Data? = nil, isAIRecognized: Bool = false, confidence: Double = 0, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.quantity = quantity
        self.unit = unit
        self.mealType = mealType
        self.timestamp = Date()
        self.imageData = imageData
        self.isAIRecognized = isAIRecognized
        self.confidence = confidence
        self.notes = notes
    }
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"
    
    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        case .other: return "fork.knife"
        }
    }
}
