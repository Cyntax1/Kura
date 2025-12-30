//
//  MainTabView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var selectedTab = 0
    @State private var showingProfile = false
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Dashboard overview
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Fasting Tab - Timer & sessions
            FastingMainView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Fasting")
                }
                .tag(1)
            
            // Diet Tab - Food logging (camera, text, manual)
            DietMainView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Food")
                }
                .tag(2)
            
            // Insights Tab - Weekly AI analysis
            WeeklyInsightsView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Insights")
                }
                .tag(3)
            
            // Profile Tab - Settings, stats, AI coach, calendar
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            createDefaultProfileIfNeeded()
        }
    }
    
    private func createDefaultProfileIfNeeded() {
        if userProfiles.isEmpty {
            let defaultProfile = UserProfile(name: "Kura User")
            modelContext.insert(defaultProfile)
            try? modelContext.save()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, FastingSession.self, DietPlan.self, FoodEntry.self, StreakData.self])
}
