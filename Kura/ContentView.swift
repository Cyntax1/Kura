//
//  ContentView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .onAppear {
                        // Configure services with model context
                        UserPreferencesService.shared.configure(with: modelContext)
                        AchievementService.shared.configure(with: modelContext)
                    }
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, FastingSession.self, FoodEntry.self, DietPlan.self, StreakData.self, UserPreferences.self, Achievement.self, ChatMessage.self], inMemory: true)
}
