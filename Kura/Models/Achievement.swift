//
//  Achievement.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import Foundation
import SwiftData
import UIKit

enum AchievementType: String, CaseIterable, Codable {
    case firstFast = "first_fast"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case hundredDays = "hundred_days"
    case perfectWeek = "perfect_week"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case hydrationHero = "hydration_hero"
    case mealLogger = "meal_logger"
    case consistentFaster = "consistent_faster"
    
    var title: String {
        switch self {
        case .firstFast: return "First Fast"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Month Master"
        case .hundredDays: return "Centurion"
        case .perfectWeek: return "Perfect Week"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .hydrationHero: return "Hydration Hero"
        case .mealLogger: return "Food Logger"
        case .consistentFaster: return "Consistency King"
        }
    }
    
    var description: String {
        switch self {
        case .firstFast: return "Complete your first fasting session"
        case .weekStreak: return "Fast for 7 consecutive days"
        case .monthStreak: return "Fast for 30 consecutive days"
        case .hundredDays: return "Reach 100 total fasting days"
        case .perfectWeek: return "Complete all planned fasts in a week"
        case .earlyBird: return "Start 10 fasts before 8 AM"
        case .nightOwl: return "Start 10 fasts after 8 PM"
        case .hydrationHero: return "Meet water goals for 7 days straight"
        case .mealLogger: return "Log 50 meals with photos"
        case .consistentFaster: return "Fast at least 3 times per week for a month"
        }
    }
    
    var icon: String {
        switch self {
        case .firstFast: return "star.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "crown.fill"
        case .hundredDays: return "trophy.fill"
        case .perfectWeek: return "checkmark.seal.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .hydrationHero: return "drop.fill"
        case .mealLogger: return "camera.fill"
        case .consistentFaster: return "calendar.badge.checkmark"
        }
    }
    
    var points: Int {
        switch self {
        case .firstFast: return 10
        case .weekStreak: return 50
        case .monthStreak: return 200
        case .hundredDays: return 500
        case .perfectWeek: return 100
        case .earlyBird: return 75
        case .nightOwl: return 75
        case .hydrationHero: return 100
        case .mealLogger: return 150
        case .consistentFaster: return 300
        }
    }
}

@Model
final class Achievement {
    var id: UUID
    var type: AchievementType
    var unlockedAt: Date
    var progress: Int
    var maxProgress: Int
    var isUnlocked: Bool
    
    init(type: AchievementType, maxProgress: Int = 1) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = Date()
        self.progress = 0
        self.maxProgress = maxProgress
        self.isUnlocked = false
    }
    
    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(maxProgress))
    }
    
    func updateProgress(_ newProgress: Int) {
        progress = min(newProgress, maxProgress)
        if progress >= maxProgress && !isUnlocked {
            unlock()
        }
    }
    
    private func unlock() {
        isUnlocked = true
        unlockedAt = Date()
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}
