//
//  OfflineFoodCameraView.swift
//  Kura
//
//  Completely offline food recognition camera
//

import SwiftUI
import AVFoundation

struct OfflineFoodCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var capturedImage: UIImage?
    @State private var recognizedFoods: [RecognizedFoodItem] = []
    @State private var isProcessing = false
    @State private var showingResults = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var processingMode: ProcessingMode = .foodRecognition
    
    @StateObject private var offlineService = OfflineFoodRecognitionService()
    @StateObject private var ocrService = OCRNutritionService()
    
    enum ProcessingMode: String, CaseIterable {
        case foodRecognition = "Food Recognition"
        case nutritionLabel = "Nutrition Label"
        
        var icon: String {
            switch self {
            case .foodRecognition: return "camera.viewfinder"
            case .nutritionLabel: return "doc.text.viewfinder"
            }
        }
        
        var description: String {
            switch self {
            case .foodRecognition: return "Identify whole foods and meals"
            case .nutritionLabel: return "Read packaged food labels"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermission == .authorized {
                    if let image = capturedImage {
                        resultsView
                    } else {
                        offlineCameraView
                    }
                } else {
                    permissionView
                }
                
                if isProcessing {
                    processingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(ProcessingMode.allCases, id: \.self) { mode in
                            Button(action: { processingMode = mode }) {
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private var offlineCameraView: some View {
        ZStack {
            CameraPreview(onImageCaptured: handleImageCapture)
                .ignoresSafeArea()
            
            VStack {
                // Top info bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: processingMode.icon)
                                .foregroundColor(.white)
                            Text(processingMode.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text(processingMode.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Offline indicator
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("Offline")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                // Camera guide overlay
                if processingMode == .nutritionLabel {
                    nutritionLabelGuide
                } else {
                    foodRecognitionGuide
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Mode switcher
                    HStack(spacing: 12) {
                        ForEach(ProcessingMode.allCases, id: \.self) { mode in
                            Button(action: { processingMode = mode }) {
                                VStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.title3)
                                    Text(mode.rawValue.components(separatedBy: " ").first ?? "")
                                        .font(.caption2)
                                }
                                .foregroundColor(processingMode == mode ? .blue : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    processingMode == mode ? 
                                    Color.white.opacity(0.9) : 
                                    Color.black.opacity(0.3)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Capture button
                    Button(action: capturePhoto) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 90, height: 90)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    private var foodRecognitionGuide: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 280, height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Position food here")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
            
            Text("Works offline • No internet required")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
        }
    }
    
    private var nutritionLabelGuide: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 200, height: 280)
                .overlay(
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Nutrition Facts")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
            
            Text("Reads nutrition labels • OCR powered")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Captured image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                // Processing mode indicator
                HStack {
                    Image(systemName: processingMode.icon)
                        .foregroundColor(.blue)
                    Text("Processed with \(processingMode.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.caption2)
                        Text("Offline")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
                .padding(.horizontal)
                
                // Results
                if recognizedFoods.isEmpty && !isProcessing {
                    noResultsView
                } else {
                    recognizedFoodsView
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Retake") {
                    capturedImage = nil
                    recognizedFoods = []
                    showingResults = false
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var recognizedFoodsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recognition Results")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(recognizedFoods, id: \.id) { food in
                OfflineFoodCard(
                    food: food,
                    onAdd: { addFoodEntry(food) }
                )
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: processingMode == .nutritionLabel ? "doc.text.magnifyingglass" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(processingMode == .nutritionLabel ? "No Nutrition Label Found" : "No Food Recognized")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(processingMode == .nutritionLabel ? 
                 "Make sure the nutrition facts panel is clearly visible and well-lit" :
                 "Try better lighting or a clearer view of the food")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Retake Photo") {
                    capturedImage = nil
                    showingResults = false
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button("Add Manually") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(processingMode == .nutritionLabel ? "Reading Nutrition Label..." : "Recognizing Food...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Processing offline with device AI")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("No internet required")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            .padding(40)
            .background(Color.black.opacity(0.9))
            .cornerRadius(20)
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Kura uses offline AI to recognize food and read nutrition labels. No data is sent to external servers.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Enable Camera") {
                requestCameraPermission()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func checkCameraPermission() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermission = granted ? .authorized : .denied
            }
        }
    }
    
    private func capturePhoto() {
        // This would be handled by the camera preview
    }
    
    private func handleImageCapture(_ image: UIImage) {
        capturedImage = image
        processImage(image)
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        showingResults = true
        
        Task {
            do {
                var foods: [RecognizedFoodItem] = []
                
                switch processingMode {
                case .foodRecognition:
                    foods = try await offlineService.recognizeFood(from: image)
                case .nutritionLabel:
                    if let nutritionData = try await ocrService.extractNutritionFromLabel(image: image) {
                        let food = RecognizedFoodItem(
                            name: "Packaged Food Item",
                            nutrition: nutritionData,
                            estimatedWeight: 100, // Default serving
                            boundingBox: nil
                        )
                        foods = [food]
                    }
                }
                
                await MainActor.run {
                    recognizedFoods = foods
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    recognizedFoods = []
                    isProcessing = false
                }
            }
        }
    }
    
    private func addFoodEntry(_ food: RecognizedFoodItem) {
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
        try? modelContext.save()
        
        recognizedFoods.removeAll { $0.id == food.id }
        
        if recognizedFoods.isEmpty {
            dismiss()
        }
    }
}

struct OfflineFoodCard: View {
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
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.caption2)
                        Text("Offline")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    
                    Text("\(Int(food.nutrition.confidence * 100))%")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(confidenceColor.opacity(0.2))
                        .foregroundColor(confidenceColor)
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 16) {
                NutrientInfo(label: "Cal", value: "\(food.nutrition.calories)")
                NutrientInfo(label: "P", value: "\(Int(food.nutrition.protein))g")
                NutrientInfo(label: "C", value: "\(Int(food.nutrition.carbs))g")
                NutrientInfo(label: "F", value: "\(Int(food.nutrition.fat))g")
            }
            
            Button("Add to Log") {
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

#Preview {
    OfflineFoodCameraView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
