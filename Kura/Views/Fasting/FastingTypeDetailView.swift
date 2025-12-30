//
//  FastingTypeDetailView.swift
//  Kura
//
//  Created by Rishith Chennupati on 10/5/25.
//

import SwiftUI
import SwiftData

struct FastingTypeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var streakData: [StreakData]
    
    let fastingType: FastingType
    @State private var selectedDuration: Double = 16
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with fasting type info
                    headerSection
                    
                    // Detailed description
                    descriptionSection
                    
                    // Duration selector with modern slider
                    durationSection
                    
                    // Benefits section
                    benefitsSection
                    
                    // Notes section
                    notesSection
                    
                    // Start button
                    startButton
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setDefaultDuration()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: fastingType.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(fastingType.rawValue)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(fastingType.description)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About This Fast")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(detailedDescription)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Recommended: \(recommendedDurationText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ModernDurationSlider(
                duration: $selectedDuration,
                range: durationRange,
                step: 0.5
            )
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefits")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(benefits, id: \.self) { benefit in
                    BenefitCard(benefit: benefit)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Add any notes about your fast...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var startButton: some View {
        Button(action: startFasting) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start \(fastingType.rawValue)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .cyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: selectedDuration)
    }
    
    // MARK: - Computed Properties
    
    private var detailedDescription: String {
        switch fastingType {
        case .intermittent:
            return "Intermittent fasting involves cycling between periods of eating and fasting. The most popular method is 16:8, where you fast for 16 hours and eat within an 8-hour window. This approach can help with weight management, metabolic health, and cellular repair processes."
            
        case .twentyFourHour:
            return "A 24-hour fast involves abstaining from food for a full day, typically from dinner to dinner the next day. This extended fasting period can promote autophagy, improve insulin sensitivity, and provide mental clarity. It's recommended to start with shorter fasts before attempting 24-hour fasts."
            
        case .water:
            return "Water fasting involves consuming only water for the duration of the fast. This is one of the most traditional forms of fasting and can provide deep metabolic benefits. During water fasting, your body enters ketosis and begins using stored fat for energy while promoting cellular cleanup."
            
        case .juice:
            return "Juice fasting allows the consumption of fresh fruit and vegetable juices while avoiding solid foods. This provides some nutrients while still giving your digestive system a rest. It's often used as a gentler introduction to fasting or for detoxification purposes."
            
        case .dry:
            return "Dry fasting involves abstaining from both food and water. This is the most intensive form of fasting and should only be attempted by experienced fasters under proper guidance. It can provide rapid results but requires careful monitoring and should not exceed 24-48 hours."
            
        case .custom:
            return "Create your own fasting schedule tailored to your specific needs and goals. Custom fasting allows you to experiment with different durations and find what works best for your lifestyle, schedule, and health objectives."
        }
    }
    
    private var recommendedDurationText: String {
        switch fastingType {
        case .intermittent:
            return "16h"
        case .twentyFourHour:
            return "24h"
        case .juice, .water:
            return "24-48h"
        case .dry:
            return "16-24h"
        case .custom:
            return "Varies"
        }
    }
    
    private var durationRange: ClosedRange<Double> {
        switch fastingType {
        case .intermittent:
            return 12...20
        case .twentyFourHour:
            return 20...30
        case .juice, .water:
            return 12...72
        case .dry:
            return 12...48
        case .custom:
            return 1...168
        }
    }
    
    private var benefits: [String] {
        switch fastingType {
        case .intermittent:
            return ["Weight Loss", "Improved Focus", "Better Sleep", "Metabolic Health"]
        case .twentyFourHour:
            return ["Autophagy", "Mental Clarity", "Discipline", "Reset Habits"]
        case .water:
            return ["Deep Cleansing", "Ketosis", "Cellular Repair", "Spiritual Growth"]
        case .juice:
            return ["Gentle Detox", "Nutrient Boost", "Energy Increase", "Digestive Rest"]
        case .dry:
            return ["Rapid Results", "Intense Focus", "Discipline", "Quick Reset"]
        case .custom:
            return ["Flexibility", "Personalized", "Adaptable", "Goal-Oriented"]
        }
    }
    
    // MARK: - Methods
    
    private func setDefaultDuration() {
        switch fastingType {
        case .intermittent:
            selectedDuration = 16
        case .twentyFourHour:
            selectedDuration = 24
        case .juice, .water, .dry:
            selectedDuration = 24
        case .custom:
            selectedDuration = 16
        }
    }
    
    private func startFasting() {
        let session = FastingSession(
            type: fastingType,
            plannedDuration: selectedDuration * 3600, // Convert hours to seconds
            notes: notes
        )
        
        modelContext.insert(session)
        
        // Update or create fasting streak
        if let existingStreak = streakData.first(where: { $0.type == .fasting }) {
            existingStreak.updateStreak()
        } else {
            let newStreak = StreakData(type: .fasting)
            newStreak.updateStreak()
            modelContext.insert(newStreak)
        }
        
        do {
            try modelContext.save()
            
            // Start Live Activity (with error handling)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                LiveActivityService.shared.startLiveActivity(for: session)
            }
            
            dismiss()
        } catch {
            print("Failed to save fasting session: \(error)")
        }
    }
}

struct BenefitCard: View {
    let benefit: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            Text(benefit)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    FastingTypeDetailView(fastingType: .intermittent)
        .modelContainer(for: [FastingSession.self, StreakData.self])
}
