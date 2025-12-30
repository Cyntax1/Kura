//
//  WeeklyInsightsView.swift
//  Kura
//
//  AI-powered weekly insights and recommendations
//

import SwiftUI
import SwiftData

struct WeeklyInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var foodEntries: [FoodEntry]
    @Query private var fastingSessions: [FastingSession]
    @Query private var streakData: [StreakData]
    @Query private var userProfiles: [UserProfile]
    @Query private var waterIntakes: [WaterIntake]
    
    @State private var insights: [AIInsight] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let insightsService = AIInsightsService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Weekly stats summary
                    weeklyStatsSection
                    
                    // AI Insights
                    if isLoading {
                        loadingView
                    } else if insights.isEmpty {
                        emptyInsightsView
                    } else {
                        insightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: generateInsights) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Refresh")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            if insights.isEmpty {
                generateInsights()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Your Week in Review")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-powered analysis of your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var weeklyStatsSection: some View {
        let stats = calculateWeeklyStats()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeeklyStatCard(title: "Avg Calories", value: "\(stats.avgCalories)", icon: "flame.fill", color: .orange)
                WeeklyStatCard(title: "Fasts Completed", value: "\(stats.fastsCompleted)", icon: "clock.fill", color: .blue)
                WeeklyStatCard(title: "Current Streak", value: "\(stats.currentStreak) days", icon: "flame.fill", color: .red)
                WeeklyStatCard(title: "Days Logged", value: "\(stats.daysLogged)/7", icon: "calendar", color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights) { insight in
                AIInsightCard(insight: insight)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var emptyInsightsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Generate AI Insights")
                .font(.headline)
            
            Text("Tap the refresh button to get personalized insights based on your data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: generateInsights) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Insights")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func generateInsights() {
        isLoading = true
        
        let analysisData = prepareAnalysisData()
        
        Task {
            do {
                let generatedInsights = try await insightsService.generateWeeklyInsights(analysisData: analysisData)
                
                await MainActor.run {
                    insights = generatedInsights
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func prepareAnalysisData() -> UserAnalysisData {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let weekEntries = foodEntries.filter { $0.timestamp >= weekAgo }
        let weekSessions = fastingSessions.filter { $0.startTime >= weekAgo }
        
        let avgCalories = weekEntries.isEmpty ? 0 : weekEntries.reduce(0) { $0 + $1.calories } / 7
        let avgProtein = weekEntries.isEmpty ? 0.0 : weekEntries.reduce(0.0) { $0 + $1.protein } / 7.0
        let avgCarbs = weekEntries.isEmpty ? 0.0 : weekEntries.reduce(0.0) { $0 + $1.carbs } / 7.0
        let avgFat = weekEntries.isEmpty ? 0.0 : weekEntries.reduce(0.0) { $0 + $1.fat } / 7.0
        
        let daysWithEntries = Set(weekEntries.map { calendar.startOfDay(for: $0.timestamp) }).count
        let profile = userProfiles.first
        let daysOverGoal = weekEntries.filter { entry in
            let dayEntries = weekEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: entry.timestamp) }
            let dayTotal = dayEntries.reduce(0) { $0 + $1.calories }
            return dayTotal > (profile?.dailyCalorieGoal ?? 2000)
        }.count
        
        let fastingStreak = streakData.first { $0.type == .fasting }
        
        // Top foods
        var foodCounts: [String: Int] = [:]
        for entry in weekEntries {
            foodCounts[entry.name, default: 0] += 1
        }
        let topFoods = foodCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        return UserAnalysisData(
            avgDailyCalories: avgCalories,
            dailyCalorieGoal: profile?.dailyCalorieGoal ?? 2000,
            avgProtein: avgProtein,
            avgCarbs: avgCarbs,
            avgFat: avgFat,
            fastingSessionsCompleted: weekSessions.filter { $0.isCompleted }.count,
            currentStreak: fastingStreak?.currentStreak ?? 0,
            daysOverGoal: daysOverGoal,
            workoutsCompleted: 0, // Can integrate HealthKit later
            avgCaloriesBurned: 0, // Can integrate HealthKit later
            topFoods: topFoods
        )
    }
    
    private func calculateWeeklyStats() -> (avgCalories: Int, fastsCompleted: Int, currentStreak: Int, daysLogged: Int) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let weekEntries = foodEntries.filter { $0.timestamp >= weekAgo }
        let weekSessions = fastingSessions.filter { $0.startTime >= weekAgo && $0.isCompleted }
        
        let avgCalories = weekEntries.isEmpty ? 0 : weekEntries.reduce(0) { $0 + $1.calories } / 7
        let daysLogged = Set(weekEntries.map { calendar.startOfDay(for: $0.timestamp) }).count
        let fastingStreak = streakData.first { $0.type == .fasting }
        
        return (avgCalories, weekSessions.count, fastingStreak?.currentStreak ?? 0, daysLogged)
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForCategory.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: insight.icon)
                    .font(.title3)
                    .foregroundColor(colorForCategory)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if insight.actionable {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(colorForCategory)
                            .font(.caption)
                    }
                }
                
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Category badge
                HStack(spacing: 4) {
                    Text(insight.category.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForCategory)
                    
                    if insight.priority == .high {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var colorForCategory: Color {
        switch insight.category {
        case .nutrition: return .green
        case .fasting: return .blue
        case .progress: return .purple
        case .suggestion: return .orange
        case .achievement: return .yellow
        case .warning: return .red
        }
    }
}

struct WeeklyStatCard: View {
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    WeeklyInsightsView()
        .modelContainer(for: [FoodEntry.self, FastingSession.self, StreakData.self, UserProfile.self, WaterIntake.self])
}
