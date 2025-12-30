//
//  NativeCameraView.swift
//  Kura
//
//  Apple-native camera interface using UIImagePickerController
//

import SwiftUI
import UIKit

// MARK: - Camera Flow States
enum CameraFlowState {
    case initial          // Show camera button
    case capturing        // Camera is open
    case preview          // Photo preview with retake/use options
    case analyzing        // AI is analyzing the food
    case results          // Show nutrition results
}

struct NativeCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var flowState: CameraFlowState = .initial
    @State private var capturedImage: UIImage?
    @State private var recognizedFoods: [RecognizedFoodItem] = []
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @StateObject private var aiService = AIFoodRecognitionService()
    var body: some View {
        NavigationView {
            ZStack {
                switch flowState {
                case .initial:
                    initialView
                case .capturing:
                    Color.clear // Camera sheet handles this
                case .preview:
                    photoPreviewView
                case .analyzing:
                    analyzingView
                case .results:
                    resultsView
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            AppleImagePicker { image in
                print("📸 Received image in callback, updating state...")
                // Small delay to ensure sheet dismissal completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("✅ Updating camera state with image")
                    capturedImage = image
                    showingCamera = false
                    flowState = .preview
                    print("✅ State updated - moving to preview")
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Initial View (Start Camera)
    private var initialView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Image(systemName: selectedMealType.systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Log \(selectedMealType.rawValue)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Take a photo to automatically identify food and calculate nutrition")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: { 
                    flowState = .capturing
                    showingCamera = true 
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                
                Button(action: { dismiss() }) {
                    Text("Add Food Manually")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    // MARK: - Photo Preview (Retake or Use)
    private var photoPreviewView: some View {
        VStack(spacing: 0) {
            // Photo Preview
            if let image = capturedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .background(Color.black)
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                Text("Is this photo clear?")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    // Retake Button
                    Button(action: {
                        capturedImage = nil
                        flowState = .initial
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 32))
                            Text("Retake")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(12)
                    }
                    
                    // Use Photo Button (Auto-analyze)
                    Button(action: {
                        flowState = .analyzing
                        analyzePhoto()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                            Text("Use Photo")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { 
                    capturedImage = nil
                    flowState = .initial
                }
            }
        }
    }
    
    // MARK: - Analyzing View
    private var analyzingView: some View {
        VStack(spacing: 30) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(16)
                    .shadow(radius: 10)
            }
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)
                
                Text("Analyzing with KuraAi...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    Text("🔍 Identifying food items")
                    Text("📊 Calculating nutrition data")
                    Text("🧮 Estimating calories, protein, carbs & fat")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Analyzing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Food Identified!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("KuraAi found \(recognizedFoods.count) item(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Image preview
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                
                // Nutrition Results
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrition Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(recognizedFoods, id: \.id) { food in
                        NutritionResultCard(
                            food: food,
                            mealType: selectedMealType,
                            onAdd: { addFoodEntry(food) }
                        )
                    }
                    
                    // Total summary for multiple foods
                    if recognizedFoods.count > 1 {
                        totalNutritionCard
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Retake") {
                    capturedImage = nil
                    recognizedFoods.removeAll()
                    flowState = .initial
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var totalNutritionCard: some View {
        let totalCalories = recognizedFoods.reduce(0) { $0 + $1.nutrition.calories }
        let totalProtein = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.protein }
        let totalCarbs = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.carbs }
        let totalFat = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.fat }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sum")
                    .foregroundColor(.blue)
                Text("Total Nutrition")
                    .font (.headline)
                    .fontWeight(.semibold)
            }
            
            // Macro grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SimpleMacroCard(icon: "flame.fill", label: "Calories", value: "\(totalCalories)", color: .red)
                SimpleMacroCard(icon: "figure.strengthtraining.traditional", label: "Protein", value: "\(Int(totalProtein))g", color: .blue)
                SimpleMacroCard(icon: "leaf.fill", label: "Carbs", value: "\(Int(totalCarbs))g", color: .orange)
                SimpleMacroCard(icon: "drop.fill", label: "Fat", value: "\(Int(totalFat))g", color: .yellow)
            }
            
            Button(action: addAllFoods) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add All to \(selectedMealType.rawValue)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    
    // MARK: - Methods
    
    private func analyzePhoto() {
        guard let image = capturedImage else {
            print("❌ No image to analyze")
            flowState = .initial
            return
        }
        
        print("🚀 Starting food analysis")
        print("🔑 API Key configured: \(APIConfig.isConfigured ? "YES" : "NO")")
        print("🤖 Using model: \(APIConfig.visionModel)")
        
        Task {
            do {
                print("🧠 Sending image to KuraAi...")
                let foods = try await aiService.recognizeFood(from: image)
                
                print("✅ KurAi recognized \(foods.count) food(s)")
                for food in foods {
                    print("  🍽️ \(food.name): \(food.nutrition.calories) cal, P:\(Int(food.nutrition.protein))g, C:\(Int(food.nutrition.carbs))g, F:\(Int(food.nutrition.fat))g")
                }
                
                await MainActor.run {
                    recognizedFoods = foods
                    flowState = .results
                    
                    if foods.isEmpty {
                        print("⚠️ No foods recognized")
                        errorMessage = "KuraAi couldn't identify any food in this image. Try taking another photo with better lighting."
                        showingError = true
                        flowState = .preview
                    } else {
                        let totalCalories = foods.reduce(0) { $0 + $1.nutrition.calories }
                        print("✅ SUCCESS! Total: \(totalCalories) calories")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Analysis failed: \(error.localizedDescription)")
                    errorMessage = "Analysis Error: \(error.localizedDescription)\n\nAPI Key: \(APIConfig.isConfigured ? "Configured" : "Missing")"
                    showingError = true
                    flowState = .preview
                }
            }
        }
    }
    
    private func addFoodEntry(_ food: RecognizedFoodItem) {
        print("💾 Saving: \(food.name) - \(food.nutrition.calories) cal, P:\(Int(food.nutrition.protein))g, C:\(Int(food.nutrition.carbs))g, F:\(Int(food.nutrition.fat))g")
        
        do {
            let foodEntry = FoodEntry(
                name: food.name,
                calories: food.nutrition.calories,
                protein: food.nutrition.protein,
                carbs: food.nutrition.carbs,
                fat: food.nutrition.fat,
                fiber: food.nutrition.fiber,
                sugar: food.nutrition.sugar,
                sodium: food.nutrition.sodium,
                quantity: food.estimatedWeight / 100,
                unit: "100g",
                mealType: selectedMealType,
                imageData: capturedImage?.jpegData(compressionQuality: 0.8),
                isAIRecognized: true,
                confidence: food.nutrition.confidence
            )
            
            modelContext.insert(foodEntry)
            try modelContext.save()
            
            print("✅ Added \(food.name) to \(selectedMealType.rawValue)!")
            
            recognizedFoods.removeAll { $0.id == food.id }
            
            if recognizedFoods.isEmpty {
                print("✅ All foods added to diet, closing camera")
                dismiss()
            }
        } catch {
            print("❌ Save error: \(error.localizedDescription)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func addAllFoods() {
        for food in recognizedFoods {
            addFoodEntry(food)
        }
        dismiss()
    }
}

// MARK: - Supporting Views

// Modern nutrition result card with add-to-diet button
struct NutritionResultCard: View {
    let food: RecognizedFoodItem
    let mealType: MealType
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Food name and calories
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(Int(food.estimatedWeight))g serving")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(food.nutrition.calories)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.red)
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Macros grid
            HStack(spacing: 16) {
                NutrientPill(icon: "💪", label: "Protein", value: "\(Int(food.nutrition.protein))g", color: .blue)
                NutrientPill(icon: "🌾", label: "Carbs", value: "\(Int(food.nutrition.carbs))g", color: .orange)
                NutrientPill(icon: "🥑", label: "Fat", value: "\(Int(food.nutrition.fat))g", color: .yellow)
            }
            
            // Confidence badge
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(confidenceColor)
                Text("\(Int(food.nutrition.confidence * 100))% confident")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundColor(confidenceColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(confidenceColor.opacity(0.1))
            .cornerRadius(8)
            
            // Add button
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to \(mealType.rawValue)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .green.opacity(0.3), radius: 5, y: 3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
}

// Nutrient pill display
struct NutrientPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// Simple macro card for grid display (nutrition totals)
struct SimpleMacroCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AppleImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraDevice = .rear
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AppleImagePicker
        
        init(_ parent: AppleImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📸 Camera captured image")
            
            // Dismiss picker first
            picker.dismiss(animated: true) {
                // Then handle the image on main thread after dismissal
                if let image = info[.originalImage] as? UIImage {
                    print("✅ Image extracted, dispatching to main thread")
                    DispatchQueue.main.async {
                        self.parent.onImageSelected(image)
                    }
                } else {
                    print("❌ Failed to extract image from picker")
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ Camera cancelled")
            picker.dismiss(animated: true)
        }
    }
}

struct NativeFoodCard: View {
    let food: RecognizedFoodItem
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(Int(food.estimatedWeight))g estimated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(food.nutrition.calories)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                MacroInfo(label: "Protein", value: "\(Int(food.nutrition.protein))g")
                MacroInfo(label: "Carbs", value: "\(Int(food.nutrition.carbs))g")
                MacroInfo(label: "Fat", value: "\(Int(food.nutrition.fat))g")
                
                Spacer()
                
                Text("\(Int(food.nutrition.confidence * 100))% confident")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(6)
            }
            
            Button("Add to \(food.name)") {
                onAdd()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
}

struct MacroInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NativeNutrientBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NativeCameraView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
