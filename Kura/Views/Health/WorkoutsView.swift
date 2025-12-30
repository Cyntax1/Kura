//
//  WorkoutsView.swift
//  Kura
//
//  Display workouts from Apple Health
//

import SwiftUI

struct WorkoutsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthKitService = HealthKitService()
    
    @State private var showingPermissionAlert = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            Group {
                if !HealthKitService.isHealthDataAvailable {
                    healthKitUnavailableView
                } else if !healthKitService.isAuthorized {
                    permissionRequestView
                } else {
                    workoutsListView
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkHealthKitAuthorization()
        }
    }
    
    private var healthKitUnavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Apple Health Unavailable")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Apple Health is not available on this device.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Text("Connect Apple Health")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Track your workouts and calories burned automatically")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                PermissionFeature(icon: "figure.run", title: "Workout Data", description: "View your workouts from Apple Health")
                PermissionFeature(icon: "flame.fill", title: "Calories Burned", description: "Track active energy expenditure")
                PermissionFeature(icon: "figure.walk", title: "Activity Metrics", description: "Monitor steps and distance")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: requestHealthKitPermission) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Connect Apple Health")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please allow Kura to access your Apple Health data in Settings.")
        }
    }
    
    private var workoutsListView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                todaySummarySection
                
                // Workouts List
                workoutsSection
            }
            .padding()
        }
        .refreshable {
            healthKitService.refreshTodayData()
        }
    }
    
    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ActivitySummaryCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(Int(healthKitService.todayCaloriesBurned))",
                    unit: "kcal",
                    color: .orange
                )
                
                ActivitySummaryCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(healthKitService.todaySteps)",
                    unit: "",
                    color: .blue
                )
                
                ActivitySummaryCard(
                    icon: "dumbbell.fill",
                    title: "Workouts",
                    value: "\(healthKitService.workouts.count)",
                    unit: "",
                    color: .green
                )
            }
        }
    }
    
    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.semibold)
            
            if healthKitService.workouts.isEmpty {
                emptyWorkoutsView
            } else {
                ForEach(healthKitService.workouts) { workout in
                    WorkoutCard(workout: workout)
                }
            }
        }
    }
    
    private var emptyWorkoutsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No workouts today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start a workout in the Health app or your favorite fitness app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func checkHealthKitAuthorization() {
        guard HealthKitService.isHealthDataAvailable else { return }
        
        healthKitService.requestAuthorization { success, error in
            if success {
                healthKitService.refreshTodayData()
            }
        }
    }
    
    private func requestHealthKitPermission() {
        healthKitService.requestAuthorization { success, error in
            if success {
                healthKitService.refreshTodayData()
            } else {
                showingPermissionAlert = true
            }
        }
    }
}

struct PermissionFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.red)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ActivitySummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WorkoutCard: View {
    let workout: WorkoutData
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: workout.activityIcon)
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.activityName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.startDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Calories
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(Int(workout.caloriesBurned))")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            HStack(spacing: 24) {
                WorkoutStat(icon: "clock.fill", value: workout.formattedDuration, color: .blue)
                
                if !workout.formattedDistance.isEmpty {
                    WorkoutStat(icon: "location.fill", value: workout.formattedDistance, color: .green)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WorkoutStat: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WorkoutsView()
}
