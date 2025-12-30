//
//  OnboardingSteps.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import PhotosUI

// MARK: - Step Views

struct WelcomeStepView: View {
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [
                    Color.green.opacity(0.1),
                    Color.mint.opacity(0.05),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Hero section with clean green styling
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Welcome to Kura")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Your journey to better health starts here")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Clean feature cards
                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "timer.circle.fill",
                            title: "Smart Fasting",
                            description: "Intelligent fasting timers with personalized guidance",
                            color: .green
                        )
                        
                        FeatureCard(
                            icon: "fork.knife.circle.fill",
                            title: "Nutrition Tracking",
                            description: "AI-powered food recognition and meal logging",
                            color: .mint
                        )
                        
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            title: "Progress Insights",
                            description: "Detailed analytics to track your wellness journey",
                            color: .teal
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 80)
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct PersonalInfoStepView: View {
    @ObservedObject var data: OnboardingData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Personal Information")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tell us a bit about yourself")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 24) {
                    // Profile Image
                    VStack(spacing: 12) {
                        if let imageData = data.profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        PhotosPicker(selection: $data.selectedPhotoItem, matching: .images) {
                            Text("Add Photo")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .onChange(of: data.selectedPhotoItem) { _, newItem in
                            Task {
                                if let newItem = newItem,
                                   let data = try? await newItem.loadTransferable(type: Data.self) {
                                    self.data.profileImageData = data
                                }
                            }
                        }
                    }
                    
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter your name", text: $data.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Age input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DismissibleNumberField("Age", value: $data.age, placeholder: "Enter your age")
                    }
                    
                    // Gender selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Button(action: {
                                    data.gender = gender
                                }) {
                                    Text(gender.rawValue.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(data.gender == gender ? .white : .primary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(data.gender == gender ? Color.blue : Color(.systemGray6))
                                        .cornerRadius(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct HealthMetricsStepView: View {
    @ObservedObject var data: OnboardingData
    @State private var useImperial = false
    @State private var displayHeight: Double = 0
    @State private var displayWeight: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Health Metrics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("These help us calculate your daily needs")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Unit toggle
                HStack {
                    Text("Metric")
                        .foregroundColor(useImperial ? .secondary : .primary)
                    
                    Toggle("", isOn: $useImperial)
                        .labelsHidden()
                    
                    Text("Imperial")
                        .foregroundColor(useImperial ? .primary : .secondary)
                }
                .padding(.horizontal)
            
            VStack(spacing: 24) {
                // Height input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        DismissibleDecimalField("Height", value: $displayHeight, placeholder: "Enter height")
                            .onChange(of: displayHeight) { _, newValue in
                                // Always store in metric (cm)
                                if useImperial {
                                    data.height = newValue * 2.54 // inches to cm
                                } else {
                                    data.height = newValue // already in cm
                                }
                            }
                        Text(useImperial ? "inches" : "cm")
                    }
                }
                
                // Weight input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        DismissibleDecimalField("Weight", value: $displayWeight, placeholder: "Enter weight")
                            .onChange(of: displayWeight) { _, newValue in
                                // Always store in metric (kg)
                                if useImperial {
                                    data.weight = newValue / 2.20462 // lbs to kg
                                } else {
                                    data.weight = newValue // already in kg
                                }
                            }
                        
                        Text(useImperial ? "lbs" : "kg")
                    }
                }
                
                // Activity level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Text("Selected: \(data.activityLevel.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Button(action: {
                                print("Activity level button tapped: \(level.rawValue)")
                                print("Current activity level: \(data.activityLevel.rawValue)")
                                data.activityLevel = level
                                print("New activity level: \(data.activityLevel.rawValue)")
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(level.rawValue)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(data.activityLevel == level ? .white : .primary)
                                        
                                        Text(level.displayDescription)
                                            .font(.caption)
                                            .foregroundColor(data.activityLevel == level ? .white.opacity(0.8) : .secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if data.activityLevel == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    } else {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                    }
                                }
                                .padding()
                                .background(data.activityLevel == level ? Color.blue : Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(data.activityLevel == level ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .onAppear {
            // Initialize display values from stored metric values
            updateDisplayValues()
        }
        .onChange(of: useImperial) { _, imperial in
            // Convert existing display values when toggling units
            if imperial {
                // Converting to imperial
                if displayHeight > 0 {
                    displayHeight = displayHeight / 2.54 // cm to inches
                }
                if displayWeight > 0 {
                    displayWeight = displayWeight * 2.20462 // kg to lbs
                }
            } else {
                // Converting to metric
                if displayHeight > 0 {
                    displayHeight = displayHeight * 2.54 // inches to cm
                }
                if displayWeight > 0 {
                    displayWeight = displayWeight / 2.20462 // lbs to kg
                }
            }
            data.useImperial = imperial
        }
    }
    
    private func updateDisplayValues() {
        // Sync with onboarding data preference
        data.useImperial = useImperial
        
        // Initialize display values based on current unit preference
        // Only set if display values are not already set (to avoid overwriting user input)
        if displayHeight == 0 && displayWeight == 0 {
            if useImperial {
                // Convert from metric to imperial for display
                if data.height > 0 {
                    displayHeight = data.height / 2.54 // cm to inches
                }
                if data.weight > 0 {
                    displayWeight = data.weight * 2.20462 // kg to lbs
                }
            } else {
                // Display metric values directly
                displayHeight = data.height
                displayWeight = data.weight
            }
        }
    }
}

struct GoalsStepView: View {
    @ObservedObject var data: OnboardingData
    
    private var calculatedCalories: Int {
        // Simple BMR calculation using Mifflin-St Jeor equation
        guard data.weight > 0 && data.height > 0 && data.age > 0 else {
            return 2000 // Default fallback
        }
        
        let bmr: Double
        if data.gender == .male {
            bmr = 88.362 + (13.397 * data.weight) + (4.799 * data.height) - (5.677 * Double(data.age))
        } else {
            bmr = 447.593 + (9.247 * data.weight) + (3.098 * data.height) - (4.330 * Double(data.age))
        }
        
        let multiplier = data.activityLevel.multiplier
        return Int(bmr * multiplier)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Your Goals")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Set your daily targets for optimal health")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            
            VStack(spacing: 24) {
                // Calorie goal
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Calorie Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Use Calculated") {
                            let calculated = calculatedCalories
                            print("Calculated calories: \(calculated)")
                            data.dailyCalorieGoal = calculated
                            print("Calorie goal set to: \(data.dailyCalorieGoal)")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    HStack {
                        DismissibleNumberField("Calories", value: $data.dailyCalorieGoal, placeholder: "Enter calorie goal")
                        
                        Text("cal/day")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Calculated: \(calculatedCalories) cal/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Water goal
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Water Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        Text("Current: \(data.dailyWaterGoal, specifier: "%.1f") liters")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        HStack {
                            Text("1.0L")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $data.dailyWaterGoal, in: 1.0...5.0, step: 0.25) {
                                Text("Water Goal")
                            } minimumValueLabel: {
                                Text("1.0")
                                    .font(.caption2)
                            } maximumValueLabel: {
                                Text("5.0")
                                    .font(.caption2)
                            }
                            .accentColor(.blue)
                            .onChange(of: data.dailyWaterGoal) { _, newValue in
                                print("Water goal changed to: \(newValue)")
                            }
                            
                            Text("5.0L")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Recommended: 2.0-3.0 liters per day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct PreferencesStepView: View {
    @ObservedObject var data: OnboardingData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Your Preferences")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose your preferred fasting and diet styles")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            
            VStack(spacing: 24) {
                // Preferred fasting type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Fasting Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Selected: \(data.preferredFastingType.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([FastingType.intermittent, .custom, .juice, .water], id: \.self) { type in
                                OnboardingFastingTypeCard(
                                    type: type,
                                    isSelected: data.preferredFastingType == type
                                ) {
                                    print("Fasting type button tapped: \(type.rawValue)")
                                    print("Current fasting type: \(data.preferredFastingType.rawValue)")
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.preferredFastingType = type
                                    }
                                    print("New fasting type: \(data.preferredFastingType.rawValue)")
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                
                // Preferred diet type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Diet Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Selected: \(data.preferredDietType.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([DietType.mediterranean, .keto, .paleo, .vegan, .vegetarian], id: \.self) { type in
                                OnboardingDietTypeCard(
                                    type: type,
                                    isSelected: data.preferredDietType == type
                                ) {
                                    print("Diet type button tapped: \(type.rawValue)")
                                    print("Current diet type: \(data.preferredDietType.rawValue)")
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        data.preferredDietType = type
                                    }
                                    print("New diet type: \(data.preferredDietType.rawValue)")
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct CompletionStepView: View {
    @ObservedObject var data: OnboardingData
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    // Success animation
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 12) {
                        Text("All Set!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your profile has been created successfully")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Profile summary
                VStack(spacing: 16) {
                    ProfileSummaryRow(label: "Name", value: data.name)
                    ProfileSummaryRow(label: "Age", value: "\(data.age) years")
                    ProfileSummaryRow(label: "Height", value: data.useImperial ? 
                        String(format: "%.0f\"", data.height / 2.54) : 
                        String(format: "%.0f cm", data.height))
                    ProfileSummaryRow(label: "Weight", value: data.useImperial ? 
                        String(format: "%.1f lbs", data.weight * 2.20462) : 
                        String(format: "%.1f kg", data.weight))
                    ProfileSummaryRow(label: "Activity", value: data.activityLevel.rawValue.capitalized)
                    ProfileSummaryRow(label: "Calorie Goal", value: "\(data.dailyCalorieGoal) kcal")
                    ProfileSummaryRow(label: "Water Goal", value: String(format: "%.1f L", data.dailyWaterGoal))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Bottom button
                VStack(spacing: 16) {
                    Button(action: {
                        print("👆 'Start Your Journey' button tapped!")
                        onComplete()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Start Your Journey")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Text("You can always update your profile later in settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct ProfileSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(level.displayDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityLevelSelectionButton: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(level.displayDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OnboardingFastingTypeCard: View {
    let type: FastingType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .frame(width: 100, height: 90)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OnboardingDietTypeCard: View {
    let type: DietType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .frame(width: 100, height: 90)
            .background(isSelected ? Color.green : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OnboardingSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct CompactSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Extensions

extension ActivityLevel {
    var displayDescription: String {
        switch self {
        case .sedentary:
            return "Little to no exercise"
        case .light:
            return "Light exercise 1-3 days/week"
        case .moderate:
            return "Moderate exercise 3-5 days/week"
        case .very:
            return "Heavy exercise 6-7 days/week"
        case .extra:
            return "Very heavy exercise, physical job"
        }
    }
}
