//
//  AchievementsView.swift
//  Kura
//
//  Complete achievements and awards system
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var fastingSessions: [FastingSession]
    @Query private var foodEntries: [FoodEntry]
    @Query private var streakData: [StreakData]
    @Query private var waterIntakes: [WaterIntake]
    
    private var achievements: [AchievementItem] {
        AchievementItem.allAchievements(
            completedFasts: completedFasts,
            bestStreak: bestStreak,
            totalMealsLogged: foodEntries.count,
            totalWaterLogged: waterIntakes.count
        )
    }
    
    private var completedFasts: Int {
        fastingSessions.filter { $0.isCompleted }.count
    }
    
    private var bestStreak: Int {
        streakData.map { $0.longestStreak }.max() ?? 0
    }
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Header
                    achievementProgressHeader
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 16) {
                        achievementCategory(
                            title: "Fasting Milestones",
                            icon: "flame.fill",
                            color: .orange,
                            achievements: achievements.filter { $0.category == .fasting }
                        )
                        
                        achievementCategory(
                            title: "Streaks & Consistency",
                            icon: "calendar",
                            color: .blue,
                            achievements: achievements.filter { $0.category == .streak }
                        )
                        
                        achievementCategory(
                            title: "Nutrition Tracking",
                            icon: "leaf.fill",
                            color: .green,
                            achievements: achievements.filter { $0.category == .nutrition }
                        )
                        
                        achievementCategory(
                            title: "Hydration Hero",
                            icon: "drop.fill",
                            color: .cyan,
                            achievements: achievements.filter { $0.category == .water }
                        )
                        
                        achievementCategory(
                            title: "Special Awards",
                            icon: "star.fill",
                            color: .yellow,
                            achievements: achievements.filter { $0.category == .special }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var achievementProgressHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(achievements.count))
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 36, weight: .bold))
                    Text("of \(achievements.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Achievements Unlocked")
                .font(.headline)
            
            Text("Keep going to unlock more!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func achievementCategory(title: String, icon: String, color: Color, achievements: [AchievementItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ForEach(achievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progress, total: 1.0)
                        .tint(achievement.color)
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Text("+\(achievement.points)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(achievement.color.opacity(0.2))
                    .foregroundColor(achievement.color)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Achievement Item Model (for display)
struct AchievementItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let category: AchievementCategory
    let requirement: Int
    var currentValue: Int
    let points: Int
    
    var isUnlocked: Bool {
        currentValue >= requirement
    }
    
    var progress: Double {
        min(Double(currentValue) / Double(requirement), 1.0)
    }
    
    enum AchievementCategory {
        case fasting, streak, nutrition, water, special
    }
    
    static func allAchievements(completedFasts: Int, bestStreak: Int, totalMealsLogged: Int, totalWaterLogged: Int) -> [AchievementItem] {
        [
            // Fasting
            AchievementItem(title: "First Fast", description: "Complete your first fasting session", icon: "star.fill", color: .orange, category: .fasting, requirement: 1, currentValue: completedFasts, points: 10),
            AchievementItem(title: "Fast Five", description: "Complete 5 fasting sessions", icon: "flame.fill", color: .orange, category: .fasting, requirement: 5, currentValue: completedFasts, points: 25),
            AchievementItem(title: "Dedicated Faster", description: "Complete 10 fasting sessions", icon: "bolt.fill", color: .orange, category: .fasting, requirement: 10, currentValue: completedFasts, points: 50),
            AchievementItem(title: "Fasting Master", description: "Complete 25 fasting sessions", icon: "crown.fill", color: .yellow, category: .fasting, requirement: 25, currentValue: completedFasts, points: 100),
            AchievementItem(title: "Legend", description: "Complete 50 fasting sessions", icon: "trophy.fill", color: .yellow, category: .fasting, requirement: 50, currentValue: completedFasts, points: 250),
            
            // Streaks
            AchievementItem(title: "Consistency", description: "Maintain a 3-day streak", icon: "calendar", color: .blue, category: .streak, requirement: 3, currentValue: bestStreak, points: 15),
            AchievementItem(title: "Week Warrior", description: "Maintain a 7-day streak", icon: "calendar.badge.clock", color: .blue, category: .streak, requirement: 7, currentValue: bestStreak, points: 30),
            AchievementItem(title: "Two Week Champion", description: "Maintain a 14-day streak", icon: "flame.circle.fill", color: .purple, category: .streak, requirement: 14, currentValue: bestStreak, points: 75),
            AchievementItem(title: "Monthly Dedication", description: "Maintain a 30-day streak", icon: "medal.fill", color: .purple, category: .streak, requirement: 30, currentValue: bestStreak, points: 150),
            
            // Nutrition
            AchievementItem(title: "Food Logger", description: "Log your first meal", icon: "leaf.fill", color: .green, category: .nutrition, requirement: 1, currentValue: totalMealsLogged, points: 10),
            AchievementItem(title: "Tracking Pro", description: "Log 10 meals", icon: "chart.bar.fill", color: .green, category: .nutrition, requirement: 10, currentValue: totalMealsLogged, points: 25),
            AchievementItem(title: "Nutrition Tracker", description: "Log 50 meals", icon: "heart.fill", color: .green, category: .nutrition, requirement: 50, currentValue: totalMealsLogged, points: 75),
            AchievementItem(title: "Diet Master", description: "Log 100 meals", icon: "sparkles", color: .mint, category: .nutrition, requirement: 100, currentValue: totalMealsLogged, points: 150),
            
            // Water
            AchievementItem(title: "Hydration Start", description: "Log water for the first time", icon: "drop.fill", color: .cyan, category: .water, requirement: 1, currentValue: totalWaterLogged, points: 10),
            AchievementItem(title: "Water Warrior", description: "Log water 10 times", icon: "drop.circle.fill", color: .cyan, category: .water, requirement: 10, currentValue: totalWaterLogged, points: 20),
            AchievementItem(title: "Hydrated", description: "Log water 50 times", icon: "waterbottle.fill", color: .cyan, category: .water, requirement: 50, currentValue: totalWaterLogged, points: 50),
            AchievementItem(title: "Hydration Master", description: "Log water 100 times", icon: "cloud.rain.fill", color: .blue, category: .water, requirement: 100, currentValue: totalWaterLogged, points: 100),
            
            // Special
            AchievementItem(title: "Early Adopter", description: "One of the first Kura users", icon: "star.circle.fill", color: .yellow, category: .special, requirement: 1, currentValue: 1, points: 50),
        ]
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [FastingSession.self, FoodEntry.self, StreakData.self, WaterIntake.self])
}
