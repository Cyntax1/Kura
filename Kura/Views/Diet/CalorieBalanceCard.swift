//
//  CalorieBalanceCard.swift
//  Kura
//
//  Display calorie balance (consumed - burned)
//

import SwiftUI
import SwiftData

struct CalorieBalanceCard: View {
    @StateObject private var healthKitService = HealthKitService()
    @Query private var foodEntries: [FoodEntry]
    @Query private var dietPlans: [DietPlan]
    
    private var todayFoodEntries: [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: startOfDay) }
    }
    
    private var caloriesConsumed: Int {
        todayFoodEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var caloriesBurned: Int {
        Int(healthKitService.todayCaloriesBurned)
    }
    
    private var netCalories: Int {
        caloriesConsumed - caloriesBurned
    }
    
    private var dailyGoal: Int {
        dietPlans.first?.dailyCalorieGoal ?? 2000
    }
    
    private var remainingCalories: Int {
        dailyGoal - netCalories
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Today's Balance")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if healthKitService.isAuthorized {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Main calorie display
            HStack(spacing: 20) {
                // Consumed
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("\(caloriesConsumed)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Eaten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Minus sign
                Image(systemName: "minus")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Burned
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("\(caloriesBurned)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Burned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Equals
                Image(systemName: "equal")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Net
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("\(netCalories)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Net")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Goal progress
            VStack(spacing: 8) {
                HStack {
                    Text("Goal: \(dailyGoal) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if remainingCalories > 0 {
                        Text("\(remainingCalories) remaining")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else {
                        Text("\(abs(remainingCalories)) over")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                ProgressView(value: Double(netCalories), total: Double(dailyGoal))
                    .tint(remainingCalories >= 0 ? .green : .red)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Workout summary
            if healthKitService.isAuthorized && !healthKitService.workouts.isEmpty {
                workoutSummary
            } else if !healthKitService.isAuthorized {
                connectHealthButton
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            if healthKitService.isAuthorized {
                healthKitService.refreshTodayData()
            }
        }
    }
    
    private var workoutSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
                
                Text("\(healthKitService.workouts.count) workout\(healthKitService.workouts.count == 1 ? "" : "s") today")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                NavigationLink(destination: WorkoutsView()) {
                    Text("View All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var connectHealthButton: some View {
        VStack(spacing: 8) {
            Divider()
            
            NavigationLink(destination: WorkoutsView()) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    
                    Text("Connect Apple Health to track calories burned")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    NavigationView {
        ScrollView {
            CalorieBalanceCard()
                .padding()
        }
    }
    .modelContainer(for: [FoodEntry.self, DietPlan.self])
}
