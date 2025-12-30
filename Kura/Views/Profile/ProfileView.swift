//
//  ProfileView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    @Query private var streakData: [StreakData]
    @Query private var fastingSessions: [FastingSession]
    @Query private var dietPlans: [DietPlan]
    
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingNotifications = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAchievements = false
    @State private var showingStats = false
    @State private var showingWorkouts = false
    @State private var showingAIChat = false
    @State private var showingCalendar = false
    @State private var showingStrava = false
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsOverviewSection
                    
                    // Health Metrics
                    if let profile = userProfile {
                        healthMetricsSection(profile)
                    }
                    
                    // Streaks Section
                    streaksSection
                    
                    // Achievements
                    achievementsSection
                    
                    // Settings
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: userProfile)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSettingsView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingWorkouts) {
            WorkoutsView()
        }
        .sheet(isPresented: $showingAIChat) {
            AIChatbotView()
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView()
        }
        .sheet(isPresented: $showingStrava) {
            StravaView()
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newValue in
            loadSelectedPhoto(newValue)
        }
        .onAppear {
            createDefaultProfileIfNeeded()
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button(action: { showingImagePicker = true }) {
                if let profile = userProfile,
                   let imageData = profile.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 4)
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
            }
            .overlay(
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: 40, y: 40)
            )
            
            // Profile Info
            VStack(spacing: 4) {
                Text(userProfile?.name ?? "Welcome to Kura")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let profile = userProfile {
                    HStack(spacing: 16) {
                        if let age = profile.age {
                            Text("\(age) years old")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let bmi = profile.bmi {
                            Text("BMI: \(String(format: "%.1f", bmi))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Fasts Completed",
                    value: "\(completedFasts)",
                    subtitle: "total",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Diets",
                    value: "\(activeDiets)",
                    subtitle: "current",
                    icon: "leaf.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Best Streak",
                    value: "\(bestStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
    
    private func healthMetricsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let height = profile.height, let weight = profile.weight {
                    let preferences = UserPreferencesService.shared
                    let useImperial = preferences.useImperial
                    
                    HealthMetricRow(
                        title: "Height",
                        value: useImperial ? 
                            "\(Int(height / 2.54))\"" : 
                            "\(Int(height)) cm",
                        icon: "ruler.fill",
                        color: .blue
                    )
                    
                    HealthMetricRow(
                        title: "Weight",
                        value: useImperial ? 
                            "\(String(format: "%.1f", weight * 2.20462)) lbs" : 
                            "\(String(format: "%.1f", weight)) kg",
                        icon: "scalemass.fill",
                        color: .green
                    )
                    
                    if let bmi = profile.bmi {
                        HealthMetricRow(
                            title: "BMI",
                            value: "\(String(format: "%.1f", bmi)) (\(profile.bmiCategory))",
                            icon: "heart.fill",
                            color: bmiColor(profile.bmiCategory)
                        )
                    }
                    
                    if let targetWeight = profile.targetWeight {
                        let difference = weight - targetWeight
                        HealthMetricRow(
                            title: "Goal Progress",
                            value: difference > 0 ? "\(String(format: "%.1f", difference)) kg to lose" : "Goal achieved!",
                            icon: "target",
                            color: difference > 0 ? .orange : .green
                        )
                    }
                }
                
                HealthMetricRow(
                    title: "Daily Calorie Goal",
                    value: "\(profile.dailyCalorieGoal) cal",
                    icon: "flame.fill",
                    color: .red
                )
                
                HealthMetricRow(
                    title: "Activity Level",
                    value: profile.activityLevel.rawValue,
                    icon: "figure.walk",
                    color: .purple
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Streaks")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(StreakType.allCases, id: \.self) { streakType in
                    let streak = streakData.first { $0.type == streakType }
                    StreakCard(streakData: streak ?? StreakData(type: streakType))
                }
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                AchievementRow(
                    title: "First Fast",
                    description: "Complete your first fasting session",
                    isUnlocked: completedFasts > 0,
                    icon: "star.fill"
                )
                
                AchievementRow(
                    title: "Week Warrior",
                    description: "Maintain a 7-day streak",
                    isUnlocked: bestStreak >= 7,
                    icon: "calendar"
                )
                
                AchievementRow(
                    title: "Dedication",
                    description: "Complete 10 fasting sessions",
                    isUnlocked: completedFasts >= 10,
                    icon: "medal.fill"
                )
                
                AchievementRow(
                    title: "Health Tracker",
                    description: "Log food for 30 days",
                    isUnlocked: false, // Would need to implement tracking
                    icon: "heart.fill"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Notifications",
                    icon: "bell.fill",
                    action: { showingNotifications = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "AI Coach",
                    icon: "brain.head.profile",
                    action: { showingAIChat = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "Calendar",
                    icon: "calendar",
                    action: { showingCalendar = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "Statistics",
                    icon: "chart.bar.fill",
                    action: { showingStats = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "Apple Health",
                    icon: "heart.fill",
                    action: { showingWorkouts = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "Strava",
                    icon: "figure.run",
                    action: { showingStrava = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "All Achievements",
                    icon: "trophy.fill",
                    action: { showingAchievements = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    action: { showingPrivacyPolicy = true }
                )
                
                Divider()
                
                SettingsRow(
                    title: "About Kura",
                    icon: "info.circle.fill",
                    action: { /* Handle about */ }
                )
                
                #if DEBUG
                Divider()
                
                SettingsRow(
                    title: "Reset Onboarding (Debug)",
                    icon: "arrow.counterclockwise",
                    action: { resetOnboarding() }
                )
                #endif
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Debug Methods
    
    #if DEBUG
    private func resetOnboarding() {
        print("🔄 Resetting onboarding...")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        print("✅ Onboarding reset complete. Restart the app to see onboarding again.")
    }
    #endif
    
    // MARK: - Computed Properties
    
    private var completedFasts: Int {
        fastingSessions.filter { $0.isCompleted }.count
    }
    
    private var activeDiets: Int {
        dietPlans.filter { $0.isActive }.count
    }
    
    private var bestStreak: Int {
        streakData.map { $0.longestStreak }.max() ?? 0
    }
    
    // MARK: - Methods
    
    private func createDefaultProfileIfNeeded() {
        if userProfiles.isEmpty {
            let defaultProfile = UserProfile(name: "Kura User")
            modelContext.insert(defaultProfile)
            try? modelContext.save()
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let profile = userProfile {
                await MainActor.run {
                    profile.profileImageData = data
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func bmiColor(_ category: String) -> Color {
        switch category {
        case "Normal": return .green
        case "Underweight": return .blue
        case "Overweight": return .orange
        case "Obese": return .red
        default: return .gray
        }
    }
}

struct HealthMetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

 

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, StreakData.self, FastingSession.self, DietPlan.self])
}
