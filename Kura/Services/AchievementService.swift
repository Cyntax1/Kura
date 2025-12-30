//
//  AchievementService.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import Foundation
import SwiftData

@Observable
class AchievementService {
    static let shared = AchievementService()
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        initializeAchievements()
    }
    
    private func initializeAchievements() {
        guard let context = modelContext else { return }
        
        // Check if achievements already exist
        let descriptor = FetchDescriptor<Achievement>()
        let existingAchievements = try? context.fetch(descriptor)
        
        if existingAchievements?.isEmpty == true {
            // Create all achievement types
            for type in AchievementType.allCases {
                let achievement = Achievement(type: type, maxProgress: getMaxProgress(for: type))
                context.insert(achievement)
            }
            try? context.save()
        }
    }
    
    private func getMaxProgress(for type: AchievementType) -> Int {
        switch type {
        case .firstFast: return 1
        case .weekStreak: return 7
        case .monthStreak: return 30
        case .hundredDays: return 100
        case .perfectWeek: return 7
        case .earlyBird: return 10
        case .nightOwl: return 10
        case .hydrationHero: return 7
        case .mealLogger: return 50
        case .consistentFaster: return 12 // 3 times per week for 4 weeks
        }
    }
    
    func checkFastingAchievements(session: FastingSession) {
        // First Fast
        updateAchievementProgress(.firstFast, increment: 1)
        
        // Early Bird / Night Owl
        let hour = Calendar.current.component(.hour, from: session.startTime)
        if hour < 8 {
            updateAchievementProgress(.earlyBird, increment: 1)
        } else if hour >= 20 {
            updateAchievementProgress(.nightOwl, increment: 1)
        }
        
        // Check streaks and consistency
        checkFastingStreaks()
    }
    
    func checkMealLogging() {
        updateAchievementProgress(.mealLogger, increment: 1)
    }
    
    func checkWaterGoal() {
        updateAchievementProgress(.hydrationHero, increment: 1)
    }
    
    private func checkFastingStreaks() {
        guard let context = modelContext else { return }
        
        // Get completed fasting sessions
        let descriptor = FetchDescriptor<FastingSession>(
            sortBy: [SortDescriptor(\FastingSession.startTime, order: .reverse)]
        )
        
        guard let sessions = try? context.fetch(descriptor) else { return }
        
        // Filter completed sessions and calculate current streak
        let completedSessions = sessions.filter { session in
            if case .completed = session.status {
                return true
            }
            return false
        }
        let currentStreak = calculateCurrentStreak(sessions: completedSessions)
        
        // Update streak achievements
        if currentStreak >= 7 {
            updateAchievementProgress(.weekStreak, setTo: min(currentStreak, 7))
        }
        if currentStreak >= 30 {
            updateAchievementProgress(.monthStreak, setTo: min(currentStreak, 30))
        }
        
        // Update total days
        updateAchievementProgress(.hundredDays, setTo: completedSessions.count)
    }
    
    private func calculateCurrentStreak(sessions: [FastingSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for session in sessions {
            let sessionDate = calendar.startOfDay(for: session.startTime)
            
            if calendar.dateInterval(of: .day, for: sessionDate)?.contains(currentDate) == true {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if sessionDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    private func updateAchievementProgress(_ type: AchievementType, increment: Int = 0, setTo: Int? = nil) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Achievement>()
        
        guard let achievement = try? context.fetch(descriptor).first(where: { $0.type == type }) else { return }
        
        if let setTo = setTo {
            achievement.updateProgress(setTo)
        } else {
            achievement.updateProgress(achievement.progress + increment)
        }
        
        try? context.save()
        
        // Show achievement notification if unlocked
        if achievement.isUnlocked && achievement.progress == achievement.maxProgress {
            showAchievementNotification(achievement)
        }
    }
    
    private func showAchievementNotification(_ achievement: Achievement) {
        // Post notification for UI to show achievement popup
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\Achievement.unlockedAt, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor).filter { $0.isUnlocked }) ?? []
    }
    
    func getTotalPoints() -> Int {
        return getUnlockedAchievements().reduce(0) { $0 + $1.type.points }
    }
}

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
