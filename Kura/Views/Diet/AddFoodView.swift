//
//  AddFoodView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var foodName: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var quantity: String = "1"
    @State private var unit: String = "serving"
    @State private var notes: String = ""
    
    private let commonUnits = ["serving", "cup", "piece", "slice", "gram", "ounce", "tablespoon", "teaspoon"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: selectedMealType.systemImage)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Add Food to \(selectedMealType.rawValue)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Manually enter food details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Food Details Form
                    VStack(spacing: 16) {
                        // Food Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Enter food name", text: $foodName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Quantity and Unit
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quantity")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("1", text: $quantity)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Unit")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Menu {
                                    ForEach(commonUnits, id: \.self) { unitOption in
                                        Button(unitOption) {
                                            unit = unitOption
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(unit)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Nutrition Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutrition Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                NutritionField(
                                    title: "Calories",
                                    value: $calories,
                                    unit: "cal",
                                    color: .red
                                )
                                
                                NutritionField(
                                    title: "Protein",
                                    value: $protein,
                                    unit: "g",
                                    color: .blue
                                )
                                
                                NutritionField(
                                    title: "Carbs",
                                    value: $carbs,
                                    unit: "g",
                                    color: .orange
                                )
                                
                                NutritionField(
                                    title: "Fat",
                                    value: $fat,
                                    unit: "g",
                                    color: .yellow
                                )
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Add any notes...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Add Button
                        Button(action: addFood) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Food")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid)
                        .padding(.top)
                    }
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .numberPadToolbar()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !foodName.isEmpty && !calories.isEmpty
    }
    
    private func addFood() {
        let foodEntry = FoodEntry(
            name: foodName,
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            quantity: Double(quantity) ?? 1,
            unit: unit,
            mealType: selectedMealType,
            notes: notes
        )
        
        modelContext.insert(foodEntry)
        try? modelContext.save()
        dismiss()
    }
}

struct NutritionField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview {
    AddFoodView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
