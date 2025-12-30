//
//  UserPreferences.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import Foundation
import SwiftData

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var heightUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "ft/in"
        }
    }
    
    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }
    
    var temperatureUnit: String {
        switch self {
        case .metric: return "°C"
        case .imperial: return "°F"
        }
    }
}

@Model
final class UserPreferences {
    var id: UUID
    var unitSystem: UnitSystem
    var notificationsEnabled: Bool
    var fastingReminders: Bool
    var mealReminders: Bool
    var waterReminders: Bool
    var darkModeEnabled: Bool
    var hapticFeedback: Bool
    var weekStartsOnMonday: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(unitSystem: UnitSystem = .metric) {
        self.id = UUID()
        self.unitSystem = unitSystem
        self.notificationsEnabled = true
        self.fastingReminders = true
        self.mealReminders = true
        self.waterReminders = true
        self.darkModeEnabled = false
        self.hapticFeedback = true
        self.weekStartsOnMonday = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Unit conversion helpers
    func displayHeight(_ heightInCm: Double) -> String {
        guard heightInCm > 0 else { return "0" }
        
        switch unitSystem {
        case .metric:
            return String(format: "%.0f cm", heightInCm)
        case .imperial:
            let totalInches = heightInCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }
    
    func displayWeight(_ weightInKg: Double) -> String {
        guard weightInKg > 0 else { return "0" }
        
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", weightInKg)
        case .imperial:
            let lbs = weightInKg * 2.20462
            return String(format: "%.1f lbs", lbs)
        }
    }
    
    func convertHeightToMetric(_ value: Double, fromImperial: Bool) -> Double {
        if fromImperial {
            return value * 2.54 // inches to cm
        }
        return value // already in cm
    }
    
    func convertWeightToMetric(_ value: Double, fromImperial: Bool) -> Double {
        if fromImperial {
            return value / 2.20462 // lbs to kg
        }
        return value // already in kg
    }
}
