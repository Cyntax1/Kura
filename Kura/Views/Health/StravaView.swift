//
//  StravaView.swift
//  Kura
//
//  Strava workout tracking and calories
//

import SwiftUI
import SafariServices

struct StravaView: View {
    @StateObject private var stravaService = StravaService.shared
    @State private var showingSafari = false
    @State private var isRefreshing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if stravaService.isConnected {
                    connectedView
                } else {
                    disconnectedView
                }
            }
            .navigationTitle("Strava")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Connected View
    
    private var connectedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Athlete Card
                if let athlete = stravaService.athlete {
                    athleteCard(athlete)
                }
                
                // Weekly Stats
                weeklyStatsSection
                
                // Recent Activities
                recentActivitiesSection
                
                // Disconnect Button
                Button(action: {
                    stravaService.disconnect()
                }) {
                    HStack {
                        Image(systemName: "link.badge.minus")
                        Text("Disconnect Strava")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private func athleteCard(_ athlete: StravaAthlete) -> some View {
        VStack(spacing: 16) {
            // Profile Image
            if let profileURL = athlete.profile_medium {
                AsyncImage(url: URL(string: profileURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            }
            
            VStack(spacing: 4) {
                Text("\(athlete.firstname) \(athlete.lastname)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Connected to Strava")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Stats
    
    private var weeklyStatsSection: some View {
        let stats = stravaService.getWeeklyStats()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Workouts",
                    value: "\(stats.totalActivities)",
                    subtitle: "this week",
                    icon: "figure.run",
                    color: .orange
                )
                
                StatCard(
                    title: "Calories",
                    value: "\(stats.totalCalories)",
                    subtitle: "burned",
                    icon: "flame.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f km", stats.totalDistance),
                    subtitle: "covered",
                    icon: "map.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Time",
                    value: formatTime(stats.totalTime),
                    subtitle: "active",
                    icon: "clock.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Recent Activities
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if stravaService.recentActivities.isEmpty {
                Text("No activities yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(stravaService.recentActivities.prefix(10)) { activity in
                    ActivityCard(activity: activity)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Disconnected View
    
    private var disconnectedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Strava Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Connect to Strava")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Track your workouts and calories burned automatically")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                StravaFeatureRow(icon: "figure.mixed.cardio", text: "Sync all your workouts")
                StravaFeatureRow(icon: "flame.fill", text: "Track calories burned")
                StravaFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "View detailed activity stats")
                StravaFeatureRow(icon: "bolt.fill", text: "Real-time syncing")
            }
            .padding(.horizontal, 32)
            .padding(.vertical)
            
            Button(action: connectStrava) {
                HStack {
                    Image(systemName: "link")
                    Text("Connect with Strava")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .sheet(isPresented: $showingSafari) {
            if let url = stravaService.getAuthorizationURL() {
                SafariView(url: url) { code in
                    handleStravaCallback(code: code)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    // MARK: - Actions
    
    private func connectStrava() {
        showingSafari = true
    }
    
    private func handleStravaCallback(code: String) {
        Task {
            do {
                try await stravaService.handleAuthorizationCallback(code: code)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        do {
            try await stravaService.fetchRecentActivities()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        isRefreshing = false
    }
}

// MARK: - Subviews

struct StravaFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
}

struct ActivityCard: View {
    let activity: StravaActivity
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(activity.activityColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: activity.activityIcon)
                        .font(.title3)
                        .foregroundColor(activity.activityColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let date = activity.startDate {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let calories = activity.calories {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(calories)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Text("kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Divider()
            
            HStack(spacing: 20) {
                ActivityStat(icon: "map", value: activity.formattedDistance)
                ActivityStat(icon: "clock", value: activity.formattedDuration)
                
                if let avgHR = activity.average_heartrate {
                    ActivityStat(icon: "heart.fill", value: "\(Int(avgHR)) bpm")
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onCallback: (String) -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.delegate = context.coordinator
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCallback: onCallback)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onCallback: (String) -> Void
        
        init(onCallback: @escaping (String) -> Void) {
            self.onCallback = onCallback
        }
        
        func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
            // Handle both localhost and kura:// redirects
            let isValidRedirect = URL.scheme == "http" && URL.host == "localhost" || URL.scheme == "kura"
            
            if isValidRedirect,
               let components = URLComponents(url: URL, resolvingAgainstBaseURL: false),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                onCallback(code)
                controller.dismiss(animated: true)
            }
        }
    }
}

#Preview {
    StravaView()
}
