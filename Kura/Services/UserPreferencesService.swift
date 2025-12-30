//
//  UserPreferencesService.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import Foundation
import SwiftData

@Observable
class UserPreferencesService {
    static let shared = UserPreferencesService()
    
    private var modelContext: ModelContext?
    private var _preferences: UserPreferences?
    
    private init() {}
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadPreferences()
    }
    
    var preferences: UserPreferences {
        if let _preferences = _preferences {
            return _preferences
        }
        
        // Create default preferences if none exist
        let defaultPrefs = UserPreferences()
        _preferences = defaultPrefs
        
        if let context = modelContext {
            context.insert(defaultPrefs)
            try? context.save()
        }
        
        return defaultPrefs
    }
    
    private func loadPreferences() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPreferences>()
        let existingPreferences = try? context.fetch(descriptor)
        
        if let first = existingPreferences?.first {
            _preferences = first
        }
    }
    
    func updateUnitSystem(_ unitSystem: UnitSystem) {
        preferences.unitSystem = unitSystem
        preferences.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func updateNotificationSettings(
        notifications: Bool? = nil,
        fasting: Bool? = nil,
        meals: Bool? = nil,
        water: Bool? = nil
    ) {
        if let notifications = notifications {
            preferences.notificationsEnabled = notifications
        }
        if let fasting = fasting {
            preferences.fastingReminders = fasting
        }
        if let meals = meals {
            preferences.mealReminders = meals
        }
        if let water = water {
            preferences.waterReminders = water
        }
        preferences.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func updateAppearanceSettings(
        darkMode: Bool? = nil,
        haptics: Bool? = nil,
        weekStartsMonday: Bool? = nil
    ) {
        if let darkMode = darkMode {
            preferences.darkModeEnabled = darkMode
        }
        if let haptics = haptics {
            preferences.hapticFeedback = haptics
        }
        if let weekStartsMonday = weekStartsMonday {
            preferences.weekStartsOnMonday = weekStartsMonday
        }
        preferences.updatedAt = Date()
        try? modelContext?.save()
    }
    
    // Convenience properties
    var useImperial: Bool {
        return preferences.unitSystem == .imperial
    }
    
    // Convenience methods for unit display
    func displayHeight(_ heightInCm: Double) -> String {
        return preferences.displayHeight(heightInCm)
    }
    
    func displayWeight(_ weightInKg: Double) -> String {
        return preferences.displayWeight(weightInKg)
    }
    
    func convertHeightToMetric(_ value: Double, fromImperial: Bool) -> Double {
        return preferences.convertHeightToMetric(value, fromImperial: fromImperial)
    }
    
    func convertWeightToMetric(_ value: Double, fromImperial: Bool) -> Double {
        return preferences.convertWeightToMetric(value, fromImperial: fromImperial)
    }
}
