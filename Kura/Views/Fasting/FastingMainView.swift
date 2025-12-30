//
//  FastingMainView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData
import ActivityKit

enum TimerStyle: String, CaseIterable {
    case modern = "Modern"
    case minimalist = "Minimalist"
    case classic = "Classic"
}

// Helper class for triggering UI updates
class ObservableObjectWrapper: ObservableObject {
    func send() {
        objectWillChange.send()
    }
}

struct FastingMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fastingSessions: [FastingSession]
    @Query private var streakData: [StreakData]
    @Query private var userProfiles: [UserProfile]
    @StateObject private var updateTrigger = ObservableObjectWrapper()
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showingStartFasting = false
    @State private var showingFastingHistory = false
    @State private var showingProfile = false
    @State private var currentTime = Date()
    @State private var timerStyle: TimerStyle = .modern
    
    private var activeFastingSession: FastingSession? {
        fastingSessions.first { $0.isActive || $0.isPaused }
    }
    
    private var fastingStreak: StreakData? {
        streakData.first { $0.type == .fasting }
    }
    
    private var completedFasts: [FastingSession] {
        fastingSessions.filter { $0.isCompleted }
    }
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with profile
                    headerSection
                    
                    // Active Fasting Session or Start New Fast
                    if let activeSession = activeFastingSession {
                        activeFastingSection(activeSession)
                    } else {
                        startFastingSection
                    }
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Fasting Types Quick Access
                    fastingTypesSection
                    
                    // Recent Fasting History
                    recentHistorySection
                    
                    // Achievements
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Fasting")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if activeFastingSession != nil {
                        Menu {
                            ForEach(TimerStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    withAnimation(.spring(response: 0.5)) {
                                        timerStyle = style
                                    }
                                }) {
                                    HStack {
                                        Text(style.rawValue)
                                        if timerStyle == style {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "timer")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfile = true }) {
                        if let imageData = userProfile?.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartFasting) {
            StartFastingView()
        }
        .sheet(isPresented: $showingFastingHistory) {
            FastingHistoryPlaceholderView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .onReceive(timer) { time in
            currentTime = time
            
            // Check for session completion and update UI
            if let activeSession = activeFastingSession {
                // Check if session should be completed
                if activeSession.isActive && activeSession.currentDuration >= activeSession.plannedDuration {
                    completeSession(activeSession)
                }
                
                // Force UI updates for active sessions
                if activeSession.isActive || activeSession.isPaused {
                    // Trigger UI refresh by updating a state variable
                    updateTrigger.send()
                    
                    // Update Live Activity every 30 seconds to avoid too frequent updates
                    let seconds = Int(time.timeIntervalSinceReferenceDate)
                    if seconds % 30 == 0 {
                        LiveActivityService.shared.updateLiveActivity(for: activeSession)
                    }
                }
            }
        }
        .onAppear {
            // Check for any sessions that should have completed while app was backgrounded
            checkForCompletedSessions()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Fasting Journey")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let streak = fastingStreak {
                Text("\(streak.currentStreak) day streak 🔥")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func activeFastingSection(_ session: FastingSession) -> some View {
        VStack(spacing: 20) {
            // Timer Display (switchable styles)
            Group {
                switch timerStyle {
                case .modern:
                    ModernFastingTimer(session: session)
                case .minimalist:
                    MinimalistFastingTimer(session: session)
                case .classic:
                    CircularFastingClock(session: session)
                }
            }
            
            // Session Details
            VStack(spacing: 12) {
                Text(session.type.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 20) {
                    FastingMetric(
                        title: "Elapsed",
                        value: formatDuration(session.currentDuration),
                        color: .blue
                    )
                    
                    FastingMetric(
                        title: "Remaining",
                        value: formatDuration(session.remainingTime),
                        color: .orange
                    )
                    
                    FastingMetric(
                        title: "Progress",
                        value: "\(Int(session.progressPercentage * 100))%",
                        color: .green
                    )
                }
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                if session.isActive {
                    Button(action: { pauseFasting(session) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Pause")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3), value: session.isActive)
                } else if session.isPaused {
                    Button(action: { resumeFasting(session) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Resume")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3), value: session.isPaused)
                }
                
                Button(action: { stopFasting(session) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("End Fast")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var startFastingSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Ready to Start Fasting?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose from various fasting types and begin your journey to better health.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingStartFasting = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start New Fast")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Fasts",
                    value: "\(fastingSessions.count)",
                    subtitle: "completed",
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(successRate)%",
                    subtitle: "completion",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Duration",
                    value: averageDuration,
                    subtitle: "hours",
                    icon: "timer",
                    color: .orange
                )
            }
        }
    }
    
    private var fastingTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fasting Types")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    showingStartFasting = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([FastingType.twentyFourHour, .intermittent, .custom, .water], id: \.self) { type in
                        NavigationLink(destination: FastingTypeDetailView(fastingType: type)) {
                            FastingTypeQuickCard(type: type) {
                                // This action is now handled by NavigationLink
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Fasts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingFastingHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if completedFasts.isEmpty {
                Text("No completed fasts yet. Start your first fast to see your history here!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(completedFasts.prefix(3)), id: \.id) { session in
                        FastingHistoryRow(session: session)
                    }
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
                    isUnlocked: !completedFasts.isEmpty,
                    icon: "star.fill"
                )
                
                AchievementRow(
                    title: "Week Warrior",
                    description: "Maintain a 7-day fasting streak",
                    isUnlocked: (fastingStreak?.currentStreak ?? 0) >= 7,
                    icon: "flame.fill"
                )
                
                AchievementRow(
                    title: "Fast Master",
                    description: "Complete 10 fasting sessions",
                    isUnlocked: completedFasts.count >= 10,
                    icon: "trophy.fill"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Computed Properties
    
    private var successRate: Int {
        guard !fastingSessions.isEmpty else { return 0 }
        let completed = completedFasts.count
        return Int((Double(completed) / Double(fastingSessions.count)) * 100)
    }
    
    private var averageDuration: String {
        guard !completedFasts.isEmpty else { return "0" }
        let average = completedFasts.reduce(0) { $0 + $1.actualDuration } / Double(completedFasts.count)
        return "\(Int(average / 3600))"
    }
    
    // MARK: - Methods
    
    private func pauseFasting(_ session: FastingSession) {
        session.status = .paused
        session.pausedTime = Date()
        try? modelContext.save()
        
        // Update Live Activity
        LiveActivityService.shared.updateLiveActivity(for: session)
    }
    
    private func resumeFasting(_ session: FastingSession) {
        if let pausedTime = session.pausedTime {
            session.totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        session.status = .active
        session.pausedTime = nil
        try? modelContext.save()
        
        // Update Live Activity
        LiveActivityService.shared.updateLiveActivity(for: session)
    }
    
    private func stopFasting(_ session: FastingSession) {
        session.status = .stopped
        session.endTime = Date()
        session.actualDuration = session.currentDuration
        try? modelContext.save()
        
        // End Live Activity
        LiveActivityService.shared.endLiveActivity(reason: .immediate)
    }
    
    private func completeSession(_ session: FastingSession) {
        session.status = .completed
        session.endTime = Date()
        session.actualDuration = session.currentDuration
        
        // Update streak
        if let streak = fastingStreak {
            streak.updateStreak()
        } else {
            let newStreak = StreakData(type: .fasting)
            newStreak.updateStreak()
            modelContext.insert(newStreak)
        }
        
        try? modelContext.save()
        
        // End Live Activity with completion
        LiveActivityService.shared.endLiveActivity(reason: .after(Date().addingTimeInterval(5)))
    }
    
    private func checkForCompletedSessions() {
        // Check all active sessions to see if any should be completed
        let activeSessions = fastingSessions.filter { $0.isActive }
        for session in activeSessions {
            if session.currentDuration >= session.plannedDuration {
                completeSession(session)
            }
        }
    }
    
    private func startQuickFast(type: FastingType) {
        let duration: TimeInterval
        switch type {
        case .twentyFourHour:
            duration = 24 * 3600
        case .intermittent:
            duration = 16 * 3600
        case .water:
            duration = 24 * 3600
        default:
            showingStartFasting = true
            return
        }
        
        let session = FastingSession(type: type, plannedDuration: duration)
        modelContext.insert(session)
        
        try? modelContext.save()
        
        // Start Live Activity
        LiveActivityService.shared.startLiveActivity(for: session)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views

struct CircularFastingClock: View {
    let session: FastingSession
    @State private var currentTime = Date()
    @State private var animationProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .stroke(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 220, height: 220)
                .blur(radius: 4)
            
            // Background circle with subtle gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 12
                )
                .frame(width: 200, height: 200)
            
            // Progress circle with enhanced gradient
            Circle()
                .trim(from: 0, to: session.progressPercentage)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: session.progressPercentage)
                .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
            
            // Animated pulse effect for active sessions
            if session.isActive {
                Circle()
                    .stroke(gradientColors.first?.opacity(0.2) ?? .clear, lineWidth: 2)
                    .frame(width: 200 + animationProgress * 20, height: 200 + animationProgress * 20)
                    .opacity(1 - animationProgress)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: animationProgress)
            }
            
            // Center content with enhanced styling
            VStack(spacing: 6) {
                Text(formatTime(session.currentDuration))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .monospacedDigit()
                
                Text(session.isPaused ? "PAUSED" : "ACTIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(session.isPaused ? .orange : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((session.isPaused ? Color.orange : Color.green).opacity(0.1))
                    )
                
                Text("of \(formatTime(session.plannedDuration))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Enhanced clock hands with smooth animation
            if !session.isPaused {
                ModernClockHands(progress: session.progressPercentage)
            }
        }
        .onAppear {
            currentTime = Date()
            if session.isActive {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                    animationProgress = 1.0
                }
            }
        }
        .onChange(of: session.isActive) { _, isActive in
            if isActive {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 0
            }
        }
    }
    
    private var gradientColors: [Color] {
        if session.isPaused {
            return [.orange, .yellow]
        } else if session.progressPercentage > 0.8 {
            return [.green, .cyan]
        } else {
            return [.blue, .cyan]
        }
    }
    
    private func formatTime(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct ModernClockHands: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // Hour hand with gradient
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 45)
                .offset(y: -22.5)
                .rotationEffect(.degrees(progress * 360))
                .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Minute hand with gradient
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [.mint, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 65)
                .offset(y: -32.5)
                .rotationEffect(.degrees(progress * 360 * 12))
                .shadow(color: .mint.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Center dot with glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .blue],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
    }
}

struct FastingMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct FastingTypeQuickCard: View {
    let type: FastingType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FastingHistoryRow: View {
    let session: FastingSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: session.type.systemImage)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(dateFormatter.string(from: session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.actualDuration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                
                Text("\(Int(session.progressPercentage * 100))% complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
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

// MARK: - Placeholder Views

struct FastingHistoryPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Fasting History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your fasting history will appear here once you complete your first fast.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FastingMainView()
        .modelContainer(for: [FastingSession.self, StreakData.self, UserProfile.self])
}
