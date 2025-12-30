//
//  FoodEditView.swift
//  Kura
//
//  Food editing interface for AI-recognized foods
//

import SwiftUI

struct FoodEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var food: RecognizedFoodItem
    @State private var customName: String
    @State private var estimatedWeight: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var selectedPortionSize: PortionSize = .custom
    
    let onSave: (RecognizedFoodItem) -> Void
    
    init(food: RecognizedFoodItem, onSave: @escaping (RecognizedFoodItem) -> Void) {
        self._food = State(initialValue: food)
        self._customName = State(initialValue: food.name)
        self._estimatedWeight = State(initialValue: String(Int(food.estimatedWeight)))
        self._calories = State(initialValue: String(food.nutrition.calories))
        self._protein = State(initialValue: String(Int(food.nutrition.protein)))
        self._carbs = State(initialValue: String(Int(food.nutrition.carbs)))
        self._fat = State(initialValue: String(Int(food.nutrition.fat)))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Edit Food Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Adjust the AI recognition results")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Food name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter food name", text: $customName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Portion size selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Portion Size")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(PortionSize.allCases, id: \.self) { portion in
                                PortionSizeCard(
                                    portion: portion,
                                    isSelected: selectedPortionSize == portion,
                                    onSelect: { 
                                        selectedPortionSize = portion
                                        updateNutritionForPortion(portion)
                                    }
                                )
                            }
                        }
                        
                        if selectedPortionSize == .custom {
                            HStack {
                                Text("Weight:")
                                    .font(.subheadline)
                                
                                TextField("0", text: $estimatedWeight)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                
                                Text("grams")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Nutrition editing
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            EditableNutritionField(
                                title: "Calories",
                                value: $calories,
                                unit: "cal",
                                color: .red,
                                icon: "flame.fill"
                            )
                            
                            EditableNutritionField(
                                title: "Protein",
                                value: $protein,
                                unit: "g",
                                color: .blue,
                                icon: "dumbbell.fill"
                            )
                            
                            EditableNutritionField(
                                title: "Carbs",
                                value: $carbs,
                                unit: "g",
                                color: .orange,
                                icon: "leaf.fill"
                            )
                            
                            EditableNutritionField(
                                title: "Fat",
                                value: $fat,
                                unit: "g",
                                color: .yellow,
                                icon: "drop.fill"
                            )
                        }
                    }
                    
                    // Confidence indicator
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Confidence")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            ProgressView(value: food.nutrition.confidence)
                                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                            
                            Text("\(Int(food.nutrition.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(confidenceColor)
                        }
                        
                        Text(confidenceDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Save button
                    Button(action: saveChanges) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save Changes")
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
    
    private var confidenceColor: Color {
        if food.nutrition.confidence >= 0.8 {
            return .green
        } else if food.nutrition.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceDescription: String {
        if food.nutrition.confidence >= 0.8 {
            return "High confidence - AI is very sure about this identification"
        } else if food.nutrition.confidence >= 0.6 {
            return "Medium confidence - AI has some uncertainty"
        } else {
            return "Low confidence - Please verify the details"
        }
    }
    
    private func updateNutritionForPortion(_ portion: PortionSize) {
        let baseWeight = food.estimatedWeight
        let newWeight = portion.weightInGrams
        let ratio = newWeight / baseWeight
        
        estimatedWeight = String(Int(newWeight))
        calories = String(Int(Double(food.nutrition.calories) * ratio))
        protein = String(Int(food.nutrition.protein * ratio))
        carbs = String(Int(food.nutrition.carbs * ratio))
        fat = String(Int(food.nutrition.fat * ratio))
    }
    
    private func saveChanges() {
        let updatedNutrition = NutritionData(
            calories: Int(calories) ?? food.nutrition.calories,
            protein: Double(protein) ?? food.nutrition.protein,
            carbs: Double(carbs) ?? food.nutrition.carbs,
            fat: Double(fat) ?? food.nutrition.fat,
            fiber: food.nutrition.fiber,
            sugar: food.nutrition.sugar,
            sodium: food.nutrition.sodium,
            servingSize: food.nutrition.servingSize,
            confidence: food.nutrition.confidence
        )
        
        let updatedFood = RecognizedFoodItem(
            name: customName,
            nutrition: updatedNutrition,
            estimatedWeight: Double(estimatedWeight) ?? food.estimatedWeight,
            boundingBox: food.boundingBox
        )
        
        onSave(updatedFood)
        dismiss()
    }
}

enum PortionSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium" 
    case large = "Large"
    case extraLarge = "Extra Large"
    case custom = "Custom"
    
    var weightInGrams: Double {
        switch self {
        case .small: return 75
        case .medium: return 150
        case .large: return 225
        case .extraLarge: return 300
        case .custom: return 100 // Default for custom
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "circle.fill"
        case .medium: return "circle.fill"
        case .large: return "circle.fill"
        case .extraLarge: return "circle.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "~75g"
        case .medium: return "~150g"
        case .large: return "~225g"
        case .extraLarge: return "~300g"
        case .custom: return "Custom weight"
        }
    }
}

struct PortionSizeCard: View {
    let portion: PortionSize
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: portion.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .scaleEffect(scaleForPortion)
                
                Text(portion.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(portion.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var scaleForPortion: Double {
        switch portion {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.3
        case .extraLarge: return 1.6
        case .custom: return 1.0
        }
    }
}

struct EditableNutritionField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FoodEditView(
        food: RecognizedFoodItem(
            name: "Grilled Chicken Breast",
            nutrition: NutritionData(
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6,
                fiber: 0,
                sugar: 0,
                sodium: 74,
                servingSize: "100g",
                confidence: 0.92
            ),
            estimatedWeight: 150,
            boundingBox: nil
        ),
        onSave: { _ in }
    )
}
