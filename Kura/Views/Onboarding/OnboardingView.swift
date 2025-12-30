//
//  OnboardingView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @StateObject private var onboardingData = OnboardingData()
    
    let totalSteps = 7
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(currentStep), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        WelcomeStepView()
                            .tag(0)
                        
                        PersonalInfoStepView(data: onboardingData)
                            .tag(1)
                        
                        HealthMetricsStepView(data: onboardingData)
                            .tag(2)
                        
                        GoalsStepView(data: onboardingData)
                            .tag(3)
                        
                        PreferencesStepView(data: onboardingData)
                            .tag(4)
                        
                        AppleHealthStepView()
                            .tag(5)
                        
                        CompletionStepView(data: onboardingData) {
                            completeOnboarding()
                        }
                        .tag(6)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if currentStep < 6 {
                            Button("Next") {
                                print("Next button tapped, current step: \(currentStep)")
                                print("Can proceed: \(canProceed)")
                                print("Name: '\(onboardingData.name)'")
                                print("Age: \(onboardingData.age)")
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                            .disabled(!canProceed)
                            .foregroundColor(canProceed ? .blue : .gray)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .dismissKeyboardOnTap()
        .numberPadToolbar()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Welcome screen - always can proceed
        case 1: return true // Personal info - always can proceed
        case 2: return true // Health metrics - always can proceed
        case 3: return true // Goals - always can proceed
        case 4: return true // Preferences - always can proceed
        case 5: return true // Apple Health - always can proceed
        case 6: return true // Completion screen - always can proceed
        default: return true
        }
    }
    
    private func completeOnboarding() {
        print("🎉 Starting onboarding completion...")
        
        // Create user preferences based on onboarding selection
        let preferences = UserPreferences(unitSystem: onboardingData.useImperial ? .imperial : .metric)
        modelContext.insert(preferences)
        print("✅ Created user preferences")
        
        // Create user profile
        let profile = UserProfile(
            name: onboardingData.name,
            age: onboardingData.age,
            height: onboardingData.height,
            weight: onboardingData.weight,
            activityLevel: onboardingData.activityLevel,
            gender: onboardingData.gender,
            dailyCalorieGoal: onboardingData.dailyCalorieGoal,
            dailyWaterGoal: onboardingData.dailyWaterGoal
        )
        
        // Set preferred types
        profile.preferredFastingTypes = [onboardingData.preferredFastingType]
        profile.preferredDietTypes = [onboardingData.preferredDietType]
        
        if let imageData = onboardingData.profileImageData {
            profile.profileImageData = imageData
        }
        
        modelContext.insert(profile)
        print("✅ Created user profile: \(profile.name)")
        
        // Create initial streak data
        let fastingStreak = StreakData(type: .fasting)
        let dietingStreak = StreakData(type: .dieting)
        let calorieStreak = StreakData(type: .calorieGoal)
        let waterStreak = StreakData(type: .waterIntake)
        
        modelContext.insert(fastingStreak)
        modelContext.insert(dietingStreak)
        modelContext.insert(calorieStreak)
        modelContext.insert(waterStreak)
        
        do {
            try modelContext.save()
            print("✅ Saved all data to SwiftData")
        } catch {
            print("❌ Error saving to SwiftData: \(error)")
        }
        
        // Mark onboarding as complete - @AppStorage in ContentView will auto-update
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        print("✅ Set hasCompletedOnboarding = true")
        print("🎉 Onboarding complete! Navigating to main app...")
    }
}

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var gender: Gender = .male
    @Published var height: Double = 0 // in cm
    @Published var weight: Double = 0 // in kg
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var dailyCalorieGoal: Int = 2000
    @Published var dailyWaterGoal: Double = 2.0 // in liters
    @Published var preferredFastingType: FastingType = .intermittent
    @Published var preferredDietType: DietType = .mediterranean
    @Published var profileImageData: Data?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var useImperial: Bool = false // Track user's unit preference
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, StreakData.self])
}
