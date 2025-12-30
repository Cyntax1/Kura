//
//  StreakData.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import Foundation
import SwiftData

@Model
final class StreakData {
    var id: UUID
    var type: StreakType
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    var totalActivities: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(type: StreakType) {
        self.id = UUID()
        self.type = type
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActivityDate = nil
        self.totalActivities = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastDate = lastActivityDate {
            let daysDifference = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDifference > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If daysDifference == 0, it's the same day, don't change streak
        } else {
            // First activity
            currentStreak = 1
        }
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        lastActivityDate = today
        totalActivities += 1
        updatedAt = Date()
    }
    
    func resetStreak() {
        currentStreak = 0
        updatedAt = Date()
    }
    
    var isActiveToday: Bool {
        guard let lastDate = lastActivityDate else { return false }
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }
}

enum StreakType: String, CaseIterable, Codable {
    case fasting = "Fasting"
    case dieting = "Dieting"
    case calorieGoal = "Calorie Goal"
    case waterIntake = "Water Intake"
    
    var systemImage: String {
        switch self {
        case .fasting: return "clock.fill"
        case .dieting: return "leaf.fill"
        case .calorieGoal: return "target"
        case .waterIntake: return "drop.fill"
        }
    }
    
    var color: String {
        switch self {
        case .fasting: return "blue"
        case .dieting: return "green"
        case .calorieGoal: return "orange"
        case .waterIntake: return "cyan"
        }
    }
}
