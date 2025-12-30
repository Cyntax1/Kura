//
//  DietDetailView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData

struct DietDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let dietPlan: DietPlan
    @Query private var foodEntries: [FoodEntry]
    
    @State private var showingEndDietAlert = false
    
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: Date()) }
    }
    
    private var todayCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var todayProtein: Double {
        todayEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var todayCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.carbs }
    }
    
    private var todayFat: Double {
        todayEntries.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: dietPlan.type.systemImage)
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(dietPlan.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(dietPlan.dietDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Progress Overview
                progressOverviewSection
                
                // Today's Progress
                todaysProgressSection
                
                // Macro Breakdown
                macroBreakdownSection
                
                // Diet Information
                dietInfoSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("End Diet Plan?", isPresented: $showingEndDietAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Diet", role: .destructive) {
                endDiet()
            }
        } message: {
            Text("Are you sure you want to end your diet plan? Your progress will be saved.")
        }
    }
    
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Days Active",
                    value: "\(daysActive)",
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                OverviewCard(
                    title: "Days Remaining",
                    value: dietPlan.daysRemaining != nil ? "\(dietPlan.daysRemaining!)" : "∞",
                    icon: "clock.fill",
                    color: .orange
                )
                
                OverviewCard(
                    title: "Avg Calories",
                    value: "\(averageDailyCalories)",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Calorie Progress
            VStack(spacing: 12) {
                HStack {
                    Text("Calories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(todayCalories) / \(dietPlan.dailyCalorieGoal)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(todayCalories > dietPlan.dailyCalorieGoal ? .red : .blue)
                }
                
                ProgressView(value: Double(todayCalories), total: Double(dietPlan.dailyCalorieGoal))
                    .progressViewStyle(LinearProgressViewStyle(tint: todayCalories > dietPlan.dailyCalorieGoal ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("\(dietPlan.dailyCalorieGoal - todayCalories) calories remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var macroBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MacroProgressRow(
                    title: "Protein",
                    current: Int(todayProtein),
                    goal: dietPlan.proteinGoal,
                    unit: "g",
                    color: .red
                )
                
                MacroProgressRow(
                    title: "Carbs",
                    current: Int(todayCarbs),
                    goal: dietPlan.carbGoal,
                    unit: "g",
                    color: .orange
                )
                
                MacroProgressRow(
                    title: "Fat",
                    current: Int(todayFat),
                    goal: dietPlan.fatGoal,
                    unit: "g",
                    color: .yellow
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var dietInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diet Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(label: "Diet Type", value: dietPlan.type.rawValue)
                InfoRow(label: "Started", value: formatDate(dietPlan.startDate))
                
                if let endDate = dietPlan.endDate {
                    InfoRow(label: "Target End", value: formatDate(endDate))
                }
                
                InfoRow(label: "Status", value: dietPlan.isActive ? "Active" : "Inactive")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: FoodLogView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Food")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingEndDietAlert = true }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("End Diet Plan")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var daysActive: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: dietPlan.startDate, to: Date()).day ?? 0
    }
    
    private var averageDailyCalories: Int {
        let activeDays = max(1, daysActive)
        let totalCalories = foodEntries.reduce(0) { $0 + $1.calories }
        return totalCalories / activeDays
    }
    
    // MARK: - Methods
    
    private func endDiet() {
        dietPlan.isActive = false
        try? modelContext.save()
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct OverviewCard: View {
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

struct MacroProgressRow: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current) / \(goal)\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(current > goal ? .red : color)
            }
            
            ProgressView(value: Double(current), total: Double(goal))
                .progressViewStyle(LinearProgressViewStyle(tint: current > goal ? .red : color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

struct InfoRow: View {
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

#Preview {
    let dietPlan = DietPlan(
        type: .keto,
        name: "Keto Diet Plan",
        dietDescription: "High fat, low carb ketogenic diet",
        dailyCalorieGoal: 2000,
        proteinGoal: 100,
        carbGoal: 25,
        fatGoal: 150
    )
    
    return DietDetailView(dietPlan: dietPlan)
        .modelContainer(for: [DietPlan.self, FoodEntry.self])
}
