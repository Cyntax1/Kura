//
//  QuickFoodLogView.swift
//  Kura
//
//  Natural Language Food Logging
//

import SwiftUI
import SwiftData

struct QuickFoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var foodText = ""
    @State private var isProcessing = false
    @State private var parsedFoods: [ParsedFoodItem] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isInputFocused: Bool
    
    private let nlLogger = NaturalLanguageFoodLogger()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Quick Log")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Just describe what you ate")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Input Section
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you eat?")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("e.g., 2 eggs, bacon, and toast", text: $foodText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isInputFocused)
                            .lineLimit(3...6)
                            .submitLabel(.done)
                            .onSubmit {
                                parseFood()
                            }
                    }
                    
                    // Quick examples
                    if parsedFoods.isEmpty && !isProcessing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ExampleChip(text: "2 eggs and toast") {
                                        foodText = "2 eggs and toast"
                                    }
                                    ExampleChip(text: "Chipotle chicken bowl") {
                                        foodText = "Chipotle chicken bowl"
                                    }
                                    ExampleChip(text: "Greek yogurt with berries") {
                                        foodText = "Greek yogurt with berries"
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: parseFood) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Analyzing...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Parse Food")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: foodText.isEmpty ? [.gray] : [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: foodText.isEmpty ? .clear : .green.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(foodText.isEmpty || isProcessing)
                }
                .padding()
                
                // Results
                if !parsedFoods.isEmpty {
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Detected Foods")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("Total: \(totalCalories) cal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            ForEach(Array(parsedFoods.enumerated()), id: \.offset) { index, food in
                                ParsedFoodCard(food: food) {
                                    parsedFoods.remove(at: index)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Save button
                    VStack {
                        Button(action: saveFoods) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save All Foods")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var totalCalories: Int {
        parsedFoods.reduce(0) { $0 + $1.calories }
    }
    
    private func parseFood() {
        guard !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        isInputFocused = false
        
        Task {
            do {
                let foods = try await nlLogger.parseFood(from: foodText)
                
                await MainActor.run {
                    parsedFoods = foods
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func saveFoods() {
        for food in parsedFoods {
            let entry = FoodEntry(
                name: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                fiber: food.fiber,
                sugar: food.sugar,
                quantity: food.estimatedGrams,
                unit: "g",
                mealType: selectedMealType,
                isAIRecognized: true,
                confidence: 0.85,
                notes: "Quick logged: \(food.displayQuantity)"
            )
            
            modelContext.insert(entry)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

struct ExampleChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
    }
}

struct ParsedFoodCard: View {
    let food: ParsedFoodItem
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(food.displayQuantity)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(food.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            HStack(spacing: 16) {
                MacroLabel(icon: "leaf.fill", label: "P", value: String(format: "%.1f", food.protein), color: .blue)
                MacroLabel(icon: "flame.fill", label: "C", value: String(format: "%.1f", food.carbs), color: .orange)
                MacroLabel(icon: "drop.fill", label: "F", value: String(format: "%.1f", food.fat), color: .purple)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MacroLabel: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(label): \(value)g")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    QuickFoodLogView(selectedMealType: .breakfast)
        .modelContainer(for: [FoodEntry.self])
}
