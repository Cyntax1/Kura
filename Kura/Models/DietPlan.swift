//
//  DietPlan.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import Foundation
import SwiftData

enum DietType: String, CaseIterable, Codable {
    case keto = "Ketogenic"
    case paleo = "Paleo"
    case mediterranean = "Mediterranean"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    case intermittentFasting = "Intermittent Fasting"
    case dash = "DASH"
    case flexitarian = "Flexitarian"
    case whole30 = "Whole30"
    case carnivore = "Carnivore"
    case plantBased = "Plant-Based"
    case glutenFree = "Gluten-Free"
    case custom = "Custom"
    
    var systemImage: String {
        switch self {
        case .keto: return "flame.fill"
        case .paleo: return "leaf.fill"
        case .mediterranean: return "fish.fill"
        case .vegan: return "carrot.fill"
        case .vegetarian: return "leaf.circle.fill"
        case .lowCarb: return "minus.circle.fill"
        case .highProtein: return "dumbbell.fill"
        case .intermittentFasting: return "clock.arrow.circlepath"
        case .dash: return "heart.fill"
        case .flexitarian: return "scale.3d"
        case .whole30: return "30.circle.fill"
        case .carnivore: return "steak"
        case .plantBased: return "tree.fill"
        case .glutenFree: return "checkmark.shield.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var description: String {
        switch self {
        case .keto: return "High fat, very low carb diet"
        case .paleo: return "Whole foods, no processed items"
        case .mediterranean: return "Heart-healthy Mediterranean style"
        case .vegan: return "Plant-based, no animal products"
        case .vegetarian: return "No meat, includes dairy and eggs"
        case .lowCarb: return "Reduced carbohydrate intake"
        case .highProtein: return "Increased protein for muscle building"
        case .intermittentFasting: return "Time-restricted eating windows"
        case .dash: return "Dietary approach to stop hypertension"
        case .flexitarian: return "Mostly vegetarian with occasional meat"
        case .whole30: return "30-day elimination diet"
        case .carnivore: return "Animal products only"
        case .plantBased: return "Whole plant foods focus"
        case .glutenFree: return "No gluten-containing foods"
        case .custom: return "Create your own diet plan"
        }
    }
}

@Model
final class DietPlan {
    var id: UUID
    var type: DietType
    var name: String
    var dietDescription: String
    var dailyCalorieGoal: Int
    var proteinGoal: Int // grams
    var carbGoal: Int // grams
    var fatGoal: Int // grams
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var createdAt: Date
    
    init(type: DietType, name: String, dietDescription: String, dailyCalorieGoal: Int, proteinGoal: Int, carbGoal: Int, fatGoal: Int, startDate: Date = Date(), endDate: Date? = nil) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.dietDescription = dietDescription
        self.dailyCalorieGoal = dailyCalorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.createdAt = Date()
    }
    
    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day
    }
}
