//
//  QuickFoodTestView.swift
//  Kura
//
//  Quick test view for food recognition functionality
//

import SwiftUI

struct QuickFoodTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var selectedMealType: MealType = .breakfast
    
    private var currentMealType: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("🍎 Food Recognition Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test the AI food recognition camera for different meal types")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("Current Time Suggestion: \(currentMealType.rawValue)")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Button(action: {
                                selectedMealType = mealType
                                showingCamera = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: mealType.systemImage)
                                        .font(.title)
                                        .foregroundColor(mealType == currentMealType ? .blue : .primary)
                                    
                                    Text(mealType.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if mealType == currentMealType {
                                        Text("Suggested")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    mealType == currentMealType ? 
                                    Color.blue.opacity(0.1) : 
                                    Color(.systemGray6)
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            mealType == currentMealType ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("📸 Tap any meal type to open the AI camera")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("The camera will recognize food and show calories automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Food Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            NativeCameraView(selectedMealType: selectedMealType)
        }
    }
}

#Preview {
    QuickFoodTestView()
        .modelContainer(for: [FoodEntry.self])
}
