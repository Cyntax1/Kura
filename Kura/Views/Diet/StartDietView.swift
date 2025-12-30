//
//  StartDietView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData

struct StartDietView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDietType: DietType = .keto
    @State private var dietName: String = ""
    @State private var description: String = ""
    @State private var dailyCalorieGoal: Double = 2000
    @State private var proteinGoal: Double = 150
    @State private var carbGoal: Double = 50
    @State private var fatGoal: Double = 150
    @State private var endDate: Date?
    @State private var hasEndDate: Bool = false
    @State private var showingCustomMacros: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Start Your Diet")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose a diet plan that fits your lifestyle and goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Diet Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Diet Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(DietType.allCases, id: \.self) { type in
                                DietTypeCard(
                                    type: type,
                                    isSelected: selectedDietType == type,
                                    action: {
                                        selectedDietType = type
                                        updateDefaultValues()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Diet Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Diet Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            TextField("Diet Name", text: $dietName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Description (Optional)", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    // Goals Section
                    goalsSection
                    
                    // Duration Section
                    durationSection
                    
                    // Start Button
                    Button(action: startDiet) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Diet Plan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(dietName.isEmpty)
                    .opacity(dietName.isEmpty ? 0.6 : 1.0)
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
        .onAppear {
            updateDefaultValues()
        }
    }
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingCustomMacros ? "Hide Details" : "Customize") {
                    withAnimation {
                        showingCustomMacros.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Calorie Goal
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Calories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(dailyCalorieGoal)) cal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Slider(value: $dailyCalorieGoal, in: 1000...4000, step: 50)
                    .accentColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Macro Goals (expandable)
            if showingCustomMacros {
                VStack(spacing: 12) {
                    MacroSlider(
                        title: "Protein",
                        value: $proteinGoal,
                        range: 50...300,
                        unit: "g",
                        color: .red
                    )
                    
                    MacroSlider(
                        title: "Carbs",
                        value: $carbGoal,
                        range: 20...400,
                        unit: "g",
                        color: .orange
                    )
                    
                    MacroSlider(
                        title: "Fat",
                        value: $fatGoal,
                        range: 30...200,
                        unit: "g",
                        color: .yellow
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Set End Date", isOn: $hasEndDate)
                .toggleStyle(SwitchToggleStyle(tint: .green))
            
            if hasEndDate {
                DatePicker(
                    "End Date",
                    selection: Binding(
                        get: { endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date() },
                        set: { endDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Methods
    
    private func updateDefaultValues() {
        if dietName.isEmpty {
            dietName = selectedDietType.rawValue + " Plan"
        }
        
        if description.isEmpty {
            description = selectedDietType.description
        }
        
        // Set default macros based on diet type
        switch selectedDietType {
        case .keto:
            proteinGoal = 100
            carbGoal = 25
            fatGoal = 150
        case .highProtein:
            proteinGoal = 200
            carbGoal = 150
            fatGoal = 80
        case .lowCarb:
            proteinGoal = 120
            carbGoal = 50
            fatGoal = 120
        case .vegan, .vegetarian, .plantBased:
            proteinGoal = 80
            carbGoal = 250
            fatGoal = 70
        default:
            proteinGoal = 150
            carbGoal = 200
            fatGoal = 100
        }
    }
    
    private func startDiet() {
        let dietPlan = DietPlan(
            type: selectedDietType,
            name: dietName,
            dietDescription: description,
            dailyCalorieGoal: Int(dailyCalorieGoal),
            proteinGoal: Int(proteinGoal),
            carbGoal: Int(carbGoal),
            fatGoal: Int(fatGoal),
            startDate: Date(),
            endDate: hasEndDate ? endDate : nil
        )
        
        modelContext.insert(dietPlan)
        
        // Update diet streak
        let dietStreak = StreakData(type: .dieting)
        dietStreak.updateStreak()
        modelContext.insert(dietStreak)
        
        try? modelContext.save()
        dismiss()
    }
}

struct DietTypeCard: View {
    let type: DietType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .green)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(isSelected ? Color.green : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacroSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(value))\(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: range, step: 5)
                .accentColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StartDietView()
        .modelContainer(for: [DietPlan.self, StreakData.self])
}
