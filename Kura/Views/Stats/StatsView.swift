//
//  StatsView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fastingSessions: [FastingSession]
    @Query private var foodEntries: [FoodEntry]
    @Query private var streakData: [StreakData]
    @Query private var dietPlans: [DietPlan]
    @Query private var waterIntakes: [WaterIntake]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedStatType: StatType = .fasting
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Stat Type Selector
                    statTypeSelector
                    
                    // Main Chart
                    mainChartSection
                    
                    // Summary Cards
                    summaryCardsSection
                    
                    // Detailed Stats
                    detailedStatsSection
                    
                    // Achievements Progress
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeRange == range ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
        }
    }
    
    private var statTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                ForEach(StatType.allCases, id: \.self) { type in
                    Button(action: { selectedStatType = type }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedStatType == type ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedStatType == type ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
        }
    }
    
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                switch selectedStatType {
                case .fasting:
                    fastingChart
                case .nutrition:
                    calorieChart
                case .water:
                    waterChart
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var fastingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fasting Duration Over Time")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(filteredFastingSessions, id: \.id) { session in
                        BarMark(
                            x: .value("Date", session.startTime, unit: .day),
                            y: .value("Duration", session.actualDuration / 3600) // Convert to hours
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15 and earlier
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var calorieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Calorie Intake")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(dailyCalorieData, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Calories", data.calories)
                        )
                        .foregroundStyle(.green)
                        .symbol(.circle)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let calories = value.as(Int.self) {
                                Text("\(calories)")
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15 and earlier
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var waterChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Water Intake")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(dailyWaterData, id: \.date) { data in
                        BarMark(
                            x: .value("Date", data.date, unit: .day),
                            y: .value("Water", data.amount)
                        )
                        .foregroundStyle(.cyan)
                    }
                    
                    // Daily goal line
                    RuleMark(y: .value("Goal", WaterIntake.dailyGoal))
                        .foregroundStyle(.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let ml = value.as(Double.self) {
                                Text("\(Int(ml))ml")
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15 and earlier
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            switch selectedStatType {
            case .fasting:
                HStack(spacing: 12) {
                    SummaryCard(
                        title: "Total Fasts",
                        value: "\(filteredFastingSessions.count)",
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Avg Duration",
                        value: averageFastingDuration,
                        icon: "timer",
                        color: .orange
                    )
                    
                    SummaryCard(
                        title: "Longest Fast",
                        value: longestFastDuration,
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
            case .nutrition:
                HStack(spacing: 12) {
                    SummaryCard(
                        title: "Avg Calories",
                        value: "\(averageDailyCalories)",
                        icon: "flame.fill",
                        color: .red
                    )
                    
                    SummaryCard(
                        title: "Days Logged",
                        value: "\(daysWithFoodEntries)",
                        icon: "calendar",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Total Meals",
                        value: "\(filteredFoodEntries.count)",
                        icon: "fork.knife",
                        color: .purple
                    )
                }
            case .water:
                HStack(spacing: 12) {
                    SummaryCard(
                        title: "Avg Daily",
                        value: "\(averageDailyWater)ml",
                        icon: "drop.fill",
                        color: .cyan
                    )
                    
                    SummaryCard(
                        title: "Goal Progress",
                        value: "\(waterGoalPercentage)%",
                        icon: "target",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Total Logs",
                        value: "\(filteredWaterIntakes.count)",
                        icon: "list.bullet",
                        color: .mint
                    )
                }
            }
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                switch selectedStatType {
                case .fasting:
                    DetailedStatRow(label: "Completed Fasts", value: "\(completedFasts)")
                    DetailedStatRow(label: "Success Rate", value: "\(successRate)%")
                    DetailedStatRow(label: "Total Fasting Time", value: totalFastingTime)
                    DetailedStatRow(label: "Most Common Type", value: mostCommonFastingType)
                case .nutrition:
                    DetailedStatRow(label: "Average Protein", value: "\(Int(averageProtein))g")
                    DetailedStatRow(label: "Average Carbs", value: "\(Int(averageCarbs))g")
                    DetailedStatRow(label: "Average Fat", value: "\(Int(averageFat))g")
                    DetailedStatRow(label: "Most Logged Meal", value: mostLoggedMealType)
                case .water:
                    DetailedStatRow(label: "Total Water Logged", value: "\(Int(filteredWaterIntakes.reduce(0) { $0 + $1.amount }))ml")
                    DetailedStatRow(label: "Days Logged", value: "\(Set(filteredWaterIntakes.map { Calendar.current.startOfDay(for: $0.timestamp) }).count)")
                    DetailedStatRow(label: "Best Day", value: "\(Int(dailyWaterData.map { $0.amount }.max() ?? 0))ml")
                    DetailedStatRow(label: "Goal Achievement", value: "\(waterGoalPercentage)%")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievement Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                AchievementProgressRow(
                    title: "Fast Master",
                    description: "Complete 50 fasting sessions",
                    current: completedFasts,
                    target: 50,
                    icon: "star.fill",
                    color: .blue
                )
                
                AchievementProgressRow(
                    title: "Streak Legend",
                    description: "Maintain a 30-day streak",
                    current: bestStreak,
                    target: 30,
                    icon: "flame.fill",
                    color: .orange
                )
                
                AchievementProgressRow(
                    title: "Nutrition Tracker",
                    description: "Log 1000 meals",
                    current: foodEntries.count,
                    target: 1000,
                    icon: "heart.fill",
                    color: .red
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredFastingSessions: [FastingSession] {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent, value: -selectedTimeRange.value, to: Date()) ?? Date()
        return fastingSessions.filter { $0.startTime >= cutoffDate }
    }
    
    private var filteredFoodEntries: [FoodEntry] {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent, value: -selectedTimeRange.value, to: Date()) ?? Date()
        return foodEntries.filter { $0.timestamp >= cutoffDate }
    }
    
    private var dailyCalorieData: [DailyCalorieData] {
        let calendar = Calendar.current
        var data: [Date: Int] = [:]
        
        for entry in filteredFoodEntries {
            let day = calendar.startOfDay(for: entry.timestamp)
            data[day, default: 0] += entry.calories
        }
        
        return data.map { DailyCalorieData(date: $0.key, calories: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var averageFastingDuration: String {
        guard !filteredFastingSessions.isEmpty else { return "0h" }
        let average = filteredFastingSessions.reduce(0) { $0 + $1.actualDuration } / Double(filteredFastingSessions.count)
        return "\(Int(average / 3600))h"
    }
    
    private var longestFastDuration: String {
        let longest = filteredFastingSessions.map { $0.actualDuration }.max() ?? 0
        return "\(Int(longest / 3600))h"
    }
    
    private var completedFasts: Int {
        filteredFastingSessions.filter { $0.isCompleted }.count
    }
    
    private var successRate: Int {
        guard !filteredFastingSessions.isEmpty else { return 0 }
        return Int((Double(completedFasts) / Double(filteredFastingSessions.count)) * 100)
    }
    
    private var totalFastingTime: String {
        let total = filteredFastingSessions.reduce(0) { $0 + $1.actualDuration }
        let hours = Int(total / 3600)
        return "\(hours)h"
    }
    
    private var mostCommonFastingType: String {
        let types = filteredFastingSessions.map { $0.type }
        let counts = Dictionary(grouping: types, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.rawValue ?? "None"
    }
    
    private var averageDailyCalories: Int {
        guard !dailyCalorieData.isEmpty else { return 0 }
        return dailyCalorieData.reduce(0) { $0 + $1.calories } / dailyCalorieData.count
    }
    
    private var daysWithFoodEntries: Int {
        Set(filteredFoodEntries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }
    
    private var averageProtein: Double {
        guard !filteredFoodEntries.isEmpty else { return 0 }
        return filteredFoodEntries.reduce(0) { $0 + $1.protein } / Double(filteredFoodEntries.count)
    }
    
    private var averageCarbs: Double {
        guard !filteredFoodEntries.isEmpty else { return 0 }
        return filteredFoodEntries.reduce(0) { $0 + $1.carbs } / Double(filteredFoodEntries.count)
    }
    
    private var averageFat: Double {
        guard !filteredFoodEntries.isEmpty else { return 0 }
        return filteredFoodEntries.reduce(0) { $0 + $1.fat } / Double(filteredFoodEntries.count)
    }
    
    private var mostLoggedMealType: String {
        let types = filteredFoodEntries.map { $0.mealType }
        let counts = Dictionary(grouping: types, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.rawValue ?? "None"
    }
    
    private var bestStreak: Int {
        streakData.map { $0.longestStreak }.max() ?? 0
    }
    
    // Water-related computed properties
    private var filteredWaterIntakes: [WaterIntake] {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.calendarComponent, value: -selectedTimeRange.value, to: Date()) ?? Date()
        return waterIntakes.filter { $0.timestamp >= cutoffDate }
    }
    
    private var dailyWaterData: [DailyWaterData] {
        let calendar = Calendar.current
        var data: [Date: Double] = [:]
        
        for intake in filteredWaterIntakes {
            let day = calendar.startOfDay(for: intake.timestamp)
            data[day, default: 0] += intake.amount
        }
        
        return data.map { DailyWaterData(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var averageDailyWater: Int {
        guard !dailyWaterData.isEmpty else { return 0 }
        let total = dailyWaterData.reduce(0) { $0 + $1.amount }
        return Int(total / Double(dailyWaterData.count))
    }
    
    private var waterGoalPercentage: Int {
        guard averageDailyWater > 0 else { return 0 }
        return Int((Double(averageDailyWater) / WaterIntake.dailyGoal) * 100)
    }
}

// MARK: - Supporting Types and Views

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    
    var value: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .week, .month, .threeMonths: return .day
        case .year: return .day
        }
    }
}

enum StatType: String, CaseIterable {
    case fasting = "Fasting"
    case nutrition = "Nutrition"
    case water = "Water"
    
    var icon: String {
        switch self {
        case .fasting: return "clock.fill"
        case .nutrition: return "leaf.fill"
        case .water: return "drop.fill"
        }
    }
}

struct DailyCalorieData {
    let date: Date
    let calories: Int
}

struct DailyWaterData {
    let date: Date
    let amount: Double
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DetailedStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct AchievementProgressRow: View {
    let title: String
    let description: String
    let current: Int
    let target: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: Double(min(current, target)), total: Double(target))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [FastingSession.self, FoodEntry.self, StreakData.self, DietPlan.self])
}
