//
//  StartFastingView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData
import ActivityKit

struct StartFastingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var streakData: [StreakData]
    
    @State private var selectedFastingType: FastingType = .twentyFourHour
    @State private var customDuration: Double = 16 // hours
    @State private var notes: String = ""
    @State private var showingCustomDurationPicker = false
    @State private var showingModernSlider = false
    @State private var showDurationSlider = true // Always show duration slider
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Start Your Fast")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose your fasting type and begin your journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Fasting Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fasting Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(FastingType.allCases, id: \.self) { type in
                                NavigationLink(destination: FastingTypeDetailView(fastingType: type)) {
                                    FastingTypeCard(
                                        type: type,
                                        isSelected: selectedFastingType == type,
                                        action: {
                                            selectedFastingType = type
                                            // Set default duration based on type
                                            switch type {
                                            case .intermittent:
                                                customDuration = 16
                                            case .twentyFourHour:
                                                customDuration = 24
                                            case .custom:
                                                // Keep current duration
                                                break
                                            case .juice, .water, .dry:
                                                customDuration = 24
                                            }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Duration Slider (now universal for all types)
                    durationSliderSection
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Add any notes about your fast...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Start Button
                    Button(action: startFasting) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Fasting")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCustomDurationPicker) {
            CustomDurationPicker(duration: $customDuration)
        }
        .sheet(isPresented: $showingModernSlider) {
            ModernSliderSheet(duration: $customDuration)
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                
                Text(durationText)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                if selectedFastingType == .custom {
                    Button("Adjust") {
                        showingModernSlider = true
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var durationSliderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Duration")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Recommended: \(defaultDurationText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ModernDurationSlider(
                duration: $customDuration,
                range: durationRange,
                step: 0.5
            )
            
            // Quick preset buttons for all types
            HStack(spacing: 8) {
                Text("Quick presets:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(presetDurations, id: \.self) { preset in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            customDuration = preset
                        }
                    }) {
                        Text(formatPresetDuration(preset))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(customDuration == preset ? .white : .blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(customDuration == preset ? Color.blue : Color.blue.opacity(0.1))
                            )
                    }
                }
            }
        }
    }
    
    private var modernDurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.headline)
                .fontWeight(.semibold)
            
            ModernDurationSlider(duration: $customDuration)
        }
    }
    
    private var durationText: String {
        let duration = fastingDuration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours >= 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            if remainingHours > 0 {
                return "\(days) day\(days > 1 ? "s" : "") \(remainingHours) hour\(remainingHours > 1 ? "s" : "")"
            } else {
                return "\(days) day\(days > 1 ? "s" : "")"
            }
        } else if hours > 0 {
            if minutes > 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "") \(minutes) minute\(minutes > 1 ? "s" : "")"
            } else {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
    
    private var fastingDuration: TimeInterval {
        return customDuration * 3600 // Always use customDuration now
    }
    
    private var defaultDurationText: String {
        switch selectedFastingType {
        case .intermittent:
            return "16h"
        case .twentyFourHour:
            return "24h"
        case .juice, .water, .dry:
            return "24h"
        case .custom:
            return "Custom"
        }
    }
    
    private var durationRange: ClosedRange<Double> {
        switch selectedFastingType {
        case .intermittent:
            return 12...20 // 12-20 hours for intermittent fasting
        case .twentyFourHour:
            return 20...30 // 20-30 hours for 24-hour fasts
        case .juice, .water:
            return 12...72 // 12 hours to 3 days
        case .dry:
            return 12...48 // 12 hours to 2 days (dry fasting is more intense)
        case .custom:
            return 1...168 // 1 hour to 1 week for custom
        }
    }
    
    private var presetDurations: [Double] {
        switch selectedFastingType {
        case .intermittent:
            return [14, 16, 18, 20]
        case .twentyFourHour:
            return [20, 22, 24, 26]
        case .juice:
            return [24, 36, 48, 72]
        case .water:
            return [24, 36, 48, 72]
        case .dry:
            return [16, 20, 24, 36]
        case .custom:
            return [12, 16, 24, 36, 48, 72]
        }
    }
    
    private func formatPresetDuration(_ hours: Double) -> String {
        let totalHours = Int(hours)
        if totalHours >= 24 {
            let days = totalHours / 24
            let remainingHours = totalHours % 24
            if remainingHours == 0 {
                return "\(days)d"
            } else {
                return "\(days)d\(remainingHours)h"
            }
        } else {
            return "\(totalHours)h"
        }
    }
    
    private func startFasting() {
        let session = FastingSession(
            type: selectedFastingType,
            plannedDuration: fastingDuration,
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
            
            // Start Live Activity with a slight delay to ensure session is saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                LiveActivityService.shared.startLiveActivity(for: session)
            }
            
            dismiss()
        } catch {
            print("Failed to save fasting session: \(error)")
            // Still dismiss even if Live Activity fails
            dismiss()
        }
    }
}

struct FastingTypeCard: View {
    let type: FastingType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomDurationPicker: View {
    @Binding var duration: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Custom Duration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Text("\(Int(duration)) hours")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Slider(value: $duration, in: 1...168, step: 1) // 1 hour to 1 week
                        .accentColor(.blue)
                    
                    HStack {
                        Text("1h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("1 week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ModernSliderSheet: View {
    @Binding var duration: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Fasting Duration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ModernDurationSlider(duration: $duration)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    StartFastingView()
        .modelContainer(for: [FastingSession.self, StreakData.self])
}
