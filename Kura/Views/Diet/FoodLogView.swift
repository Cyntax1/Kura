//
//  FoodLogView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var foodEntries: [FoodEntry]
    @Query private var dietPlans: [DietPlan]
    
    @State private var showingAddFood = false
    @State private var showingCamera = false
    @State private var selectedMealType: MealType = .breakfast
    
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return foodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: Date()) }
    }
    
    private var activeDietPlan: DietPlan? {
        dietPlans.first { $0.isActive }
    }
    
    private var todayCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var todayProtein: Double {
        todayEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var todayCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.carbs }
    }
    
    private var todayFat: Double {
        todayEntries.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Summary
                    dailySummarySection
                    
                    // Quick Add Buttons
                    quickAddSection
                    
                    // Meal Sections
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        mealSection(for: mealType)
                    }
                }
                .padding()
            }
            .navigationTitle("Food Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddFood = true }) {
                            Label("Add Food Manually", systemImage: "plus")
                        }
                        
                        Button(action: { showingCamera = true }) {
                            Label("Scan with Camera", systemImage: "camera")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(selectedMealType: selectedMealType)
        }
        .sheet(isPresented: $showingCamera) {
            NativeCameraView(selectedMealType: selectedMealType)
        }
    }
    
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            // Calorie Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Daily Calories")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let goal = activeDietPlan?.dailyCalorieGoal {
                        Text("\(todayCalories) / \(goal)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(todayCalories > goal ? .red : .blue)
                    } else {
                        Text("\(todayCalories) cal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                if let goal = activeDietPlan?.dailyCalorieGoal {
                    ProgressView(value: Double(todayCalories), total: Double(goal))
                        .progressViewStyle(LinearProgressViewStyle(tint: todayCalories > goal ? .red : .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Macro Breakdown
            if let dietPlan = activeDietPlan {
                HStack(spacing: 12) {
                    MacroCard(
                        title: "Protein",
                        current: Int(todayProtein),
                        goal: dietPlan.proteinGoal,
                        unit: "g",
                        color: .red
                    )
                    
                    MacroCard(
                        title: "Carbs",
                        current: Int(todayCarbs),
                        goal: dietPlan.carbGoal,
                        unit: "g",
                        color: .orange
                    )
                    
                    MacroCard(
                        title: "Fat",
                        current: Int(todayFat),
                        goal: dietPlan.fatGoal,
                        unit: "g",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Button(action: {
                            selectedMealType = mealType
                            showingCamera = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Scan \(mealType.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(width: 100, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func mealSection(for mealType: MealType) -> some View {
        let mealEntries = todayEntries.filter { $0.mealType == mealType }
        let mealCalories = mealEntries.reduce(0) { $0 + $1.calories }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mealType.systemImage)
                    .foregroundColor(.blue)
                
                Text(mealType.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(mealCalories) cal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    selectedMealType = mealType
                    showingAddFood = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if mealEntries.isEmpty {
                Text("No food logged for \(mealType.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.leading, 28)
            } else {
                VStack(spacing: 8) {
                    ForEach(mealEntries, id: \.id) { entry in
                        FoodEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MacroCard: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(current)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(current > goal ? .red : color)
            
            Text("/ \(goal)\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(current), total: Double(goal))
                .progressViewStyle(LinearProgressViewStyle(tint: current > goal ? .red : color))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            // Food image or icon
            if let imageData = entry.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(Int(entry.quantity)) \(entry.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if entry.isAIRecognized {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.calories) cal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("P:\(Int(entry.protein)) C:\(Int(entry.carbs)) F:\(Int(entry.fat))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .contextMenu {
            Button(action: {
                modelContext.delete(entry)
                try? modelContext.save()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    FoodLogView()
        .modelContainer(for: [FoodEntry.self, DietPlan.self])
}
