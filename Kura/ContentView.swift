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
                        print("✅ Showing MainTabView - Onboarding completed")
                        // Configure services with model context
                        UserPreferencesService.shared.configure(with: modelContext)
                        AchievementService.shared.configure(with: modelContext)
                    }
            } else {
                OnboardingView()
                    .onAppear {
                        print("🎓 Showing OnboardingView - hasCompletedOnboarding: \(hasCompletedOnboarding)")
                    }
            }
        }
        .onChange(of: hasCompletedOnboarding) { oldValue, newValue in
            print("🔄 hasCompletedOnboarding changed: \(oldValue) -> \(newValue)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
