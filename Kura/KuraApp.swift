//
//  KuraApp.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

@main
struct KuraApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            FastingSession.self,
            FoodEntry.self,
            DietPlan.self,
            StreakData.self,
            UserPreferences.self,
            Achievement.self,
            ChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
