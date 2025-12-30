//
//  HomeView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fastingSessions: [FastingSession]
    @Query private var dietPlans: [DietPlan]
    @Query private var streakData: [StreakData]
    @Query private var userProfiles: [UserProfile]
    
    @State private var showingProfile = false
    @State private var showingAIChatbot = false
    
    private var activeFastingSession: FastingSession? {
        fastingSessions.first { $0.isActive || $0.isPaused }
    }
    
    private var activeDietPlan: DietPlan? {
        dietPlans.first { $0.isActive }
    }
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with greeting and profile
                    headerSection
                    
                    // Quick Stats Cards
                    quickStatsSection
                    
                    // Active Fasting Session
                    if let activeSession = activeFastingSession {
                        activeFastingCard(activeSession)
                    } else {
                        startFastingCard
                    }
                    
                    // Active Diet Plan
                    if let activeDiet = activeDietPlan {
                        activeDietCard(activeDiet)
                    } else {
                        startDietCard
                    }
                    
                    // Streaks Section
                    streaksSection
                    
                    // Quick Actions
                    QuickActionsView()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingAIChatbot) {
            AIChatbotView()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(userProfile?.name ?? "Welcome to Kura")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // AI Chatbot Button
            Button(action: { showingAIChatbot = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: { showingProfile = true }) {
                if let imageData = userProfile?.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.top)
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Fasting Streak",
                value: "\(fastingStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Diet Streak",
                value: "\(dietStreak)",
                subtitle: "days",
                icon: "leaf.fill",
                color: .green
            )
            
            StatCard(
                title: "Total Fasts",
                value: "\(completedFasts)",
                subtitle: "completed",
                icon: "checkmark.circle.fill",
                color: .blue
            )
        }
    }
    
    private func activeFastingCard(_ session: FastingSession) -> some View {
        NavigationLink(destination: FastingDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: session.type.systemImage)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.type.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(session.isPaused ? "Paused" : "Active")
                            .font(.caption)
                            .foregroundColor(session.isPaused ? .orange : .green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDuration(session.currentDuration))
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("of \(formatDuration(session.plannedDuration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ProgressView(value: session.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var startFastingCard: some View {
        NavigationLink(destination: StartFastingView()) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Fasting")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Begin your fasting journey")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func activeDietCard(_ diet: DietPlan) -> some View {
        NavigationLink(destination: DietDetailView(dietPlan: diet)) {
            HStack {
                Image(systemName: diet.type.systemImage)
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(diet.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let daysRemaining = diet.daysRemaining {
                        Text("\(daysRemaining) days remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ongoing")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(diet.dailyCalorieGoal)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("cal goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var startDietCard: some View {
        NavigationLink(destination: StartDietView()) {
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Diet Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Choose your nutrition journey")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Streaks")
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
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                NavigationLink(destination: FoodLogView()) {
                    QuickActionButton(
                        title: "Log Food",
                        icon: "camera.fill",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: CalendarView()) {
                    QuickActionButton(
                        title: "Calendar",
                        icon: "calendar",
                        color: .purple
                    )
                }
                
                NavigationLink(destination: StatsView()) {
                    QuickActionButton(
                        title: "Stats",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
    
    private var fastingStreak: Int {
        streakData.first { $0.type == .fasting }?.currentStreak ?? 0
    }
    
    private var dietStreak: Int {
        streakData.first { $0.type == .dieting }?.currentStreak ?? 0
    }
    
    private var completedFasts: Int {
        fastingSessions.filter { $0.isCompleted }.count
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

 

struct StreakCard: View {
    let streakData: StreakData
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: streakData.type.systemImage)
                .font(.title2)
                .foregroundColor(colorForType(streakData.type))
            
            Text("\(streakData.currentStreak)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(streakData.type.rawValue)
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
    
    private func colorForType(_ type: StreakType) -> Color {
        switch type {
        case .fasting: return .blue
        case .dieting: return .green
        case .calorieGoal: return .orange
        case .waterIntake: return .cyan
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [FastingSession.self, DietPlan.self, StreakData.self, UserProfile.self, FoodEntry.self])
}
