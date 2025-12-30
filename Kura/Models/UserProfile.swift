//
//  UserProfile.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var age: Int?
    var height: Double? // in cm
    var weight: Double? // in kg
    var targetWeight: Double? // in kg
    var activityLevel: ActivityLevel
    var gender: Gender?
    var dailyCalorieGoal: Int
    var dailyWaterGoal: Double // in liters
    var preferredFastingTypes: [FastingType]
    var preferredDietTypes: [DietType]
    var createdAt: Date
    var updatedAt: Date
    var profileImageData: Data?
    var notificationsEnabled: Bool
    var reminderTimes: [Date]
    
    init(name: String, age: Int? = nil, height: Double? = nil, weight: Double? = nil, targetWeight: Double? = nil, activityLevel: ActivityLevel = .moderate, gender: Gender? = nil, dailyCalorieGoal: Int = 2000, dailyWaterGoal: Double = 2.0) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.activityLevel = activityLevel
        self.gender = gender
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyWaterGoal = dailyWaterGoal
        self.preferredFastingTypes = []
        self.preferredDietTypes = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.profileImageData = nil
        self.notificationsEnabled = true
        self.reminderTimes = []
    }
    
    var bmi: Double? {
        guard let height = height, let weight = weight, height > 0 else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        guard let bmi = bmi else { return "Unknown" }
        
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    var bmr: Double? {
        guard let age = age, let height = height, let weight = weight, let gender = gender else { return nil }
        
        // Mifflin-St Jeor Equation
        switch gender {
        case .male:
            return 10 * weight + 6.25 * height - 5 * Double(age) + 5
        case .female:
            return 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
    }
    
    var tdee: Double? {
        guard let bmr = bmr else { return nil }
        return bmr * activityLevel.multiplier
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case very = "Very Active"
    case extra = "Extra Active"
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .very: return 1.725
        case .extra: return 1.9
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .very: return "Hard exercise 6-7 days/week"
        case .extra: return "Very hard exercise, physical job"
        }
    }
}

enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
}
