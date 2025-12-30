//
//  EnhancedFoodCameraView.swift
//  Kura
//
//  CalAI-style enhanced camera interface for food recognition
//

import SwiftUI
import AVFoundation
import Vision

struct EnhancedFoodCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var capturedImages: [UIImage] = []
    @State private var recognizedFoods: [RecognizedFoodItem] = []
    @State private var isProcessing = false
    @State private var showingResults = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var currentImageIndex = 0
    @State private var showingTips = false
    
    @StateObject private var aiService = AIFoodRecognitionService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermission == .authorized {
                    if !capturedImages.isEmpty && showingResults {
                        resultsView
                    } else {
                        enhancedCameraView
                    }
                } else {
                    permissionView
                }
                
                // Processing overlay
                if isProcessing {
                    processingOverlay
                }
                
                // Tips overlay
                if showingTips {
                    tipsOverlay
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
                    Button(action: { showingTips.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private var enhancedCameraView: some View {
        ZStack {
            EnhancedCameraPreview(
                onImageCaptured: handleImageCapture,
                capturedImages: capturedImages
            )
            .ignoresSafeArea()
            
            // Camera overlay UI
            VStack {
                // Top instruction bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position food in frame")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Tap to capture • Hold for multiple photos")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Flash toggle would go here
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
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Captured images preview
                    if !capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                    Button(action: { removeImage(at: index) }) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white, in: Circle())
                                                .font(.caption)
                                                .offset(x: 5, y: -5)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                    }
                    
                    // Camera controls
                    HStack(spacing: 40) {
                        // Gallery button
                        Button(action: {}) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
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
                        
                        // Analyze button
                        Button(action: analyzeImages) {
                            VStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                
                                Text("Analyze")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(capturedImages.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(capturedImages.isEmpty)
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
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image carousel
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .tag(index)
                    }
                }
                .frame(height: 250)
                .tabViewStyle(PageTabViewStyle())
                
                // Recognition results
                if recognizedFoods.isEmpty && !isProcessing {
                    noFoodRecognizedView
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
                    capturedImages.removeAll()
                    recognizedFoods.removeAll()
                    showingResults = false
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var recognizedFoodsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recognized Foods")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(recognizedFoods.count) items")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            ForEach(recognizedFoods, id: \.id) { food in
                EnhancedFoodCard(
                    food: food,
                    onAdd: { addFoodEntry(food) },
                    onEdit: { editFood(food) }
                )
            }
            
            // Total nutrition summary
            if !recognizedFoods.isEmpty {
                totalNutritionSummary
            }
        }
    }
    
    private var totalNutritionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Nutrition")
                .font(.headline)
                .fontWeight(.semibold)
            
            let totalCalories = recognizedFoods.reduce(0) { $0 + $1.nutrition.calories }
            let totalProtein = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.protein }
            let totalCarbs = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.carbs }
            let totalFat = recognizedFoods.reduce(0.0) { $0 + $1.nutrition.fat }
            
            HStack(spacing: 20) {
                NutrientSummary(label: "Calories", value: "\(totalCalories)", color: .red)
                NutrientSummary(label: "Protein", value: "\(Int(totalProtein))g", color: .blue)
                NutrientSummary(label: "Carbs", value: "\(Int(totalCarbs))g", color: .orange)
                NutrientSummary(label: "Fat", value: "\(Int(totalFat))g", color: .yellow)
            }
            
            Button("Add All Foods") {
                addAllFoods()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var noFoodRecognizedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("No Food Recognized")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try taking another photo with better lighting or add food manually")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Retake Photo") {
                    capturedImages.removeAll()
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
    
    private var tipsOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { showingTips = false }
            
            VStack(spacing: 20) {
                Text("Photo Tips")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "lightbulb", text: "Use good lighting - natural light works best")
                    TipRow(icon: "viewfinder", text: "Center food in frame with clear view")
                    TipRow(icon: "hand.raised", text: "Include your hand for size reference")
                    TipRow(icon: "camera.viewfinder", text: "Take multiple angles for better accuracy")
                    TipRow(icon: "fork.knife", text: "Separate mixed dishes when possible")
                }
                
                Button("Got it!") {
                    showingTips = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(30)
            .background(Color.black.opacity(0.9))
            .cornerRadius(20)
            .padding()
        }
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analyzing Food with AI...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Identifying ingredients and calculating nutrition")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
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
            
            Text("Kura uses AI to recognize food items and automatically calculate calories and macros from your photos.")
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
        capturedImages.append(image)
    }
    
    private func removeImage(at index: Int) {
        capturedImages.remove(at: index)
    }
    
    private func analyzeImages() {
        guard !capturedImages.isEmpty else { return }
        
        isProcessing = true
        showingResults = true
        
        Task {
            do {
                var allRecognizedFoods: [RecognizedFoodItem] = []
                
                for image in capturedImages {
                    let foods = try await aiService.recognizeFood(from: image)
                    allRecognizedFoods.append(contentsOf: foods)
                }
                
                await MainActor.run {
                    recognizedFoods = allRecognizedFoods
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    print("AI Food Recognition Error: \(error)")
                    // Handle error - could show alert
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
            quantity: food.estimatedWeight / 100, // Convert to 100g servings
            unit: "100g",
            mealType: selectedMealType,
            imageData: capturedImages.first?.jpegData(compressionQuality: 0.8),
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
    
    private func editFood(_ food: RecognizedFoodItem) {
        // This would open an edit interface
    }
    
    private func addAllFoods() {
        for food in recognizedFoods {
            addFoodEntry(food)
        }
        dismiss()
    }
}

// MARK: - Supporting Views

struct EnhancedFoodCard: View {
    let food: RecognizedFoodItem
    let onAdd: () -> Void
    let onEdit: () -> Void
    
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
                
                Text("\(Int(food.nutrition.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 16) {
                NutrientInfo(label: "Cal", value: "\(food.nutrition.calories)")
                NutrientInfo(label: "P", value: "\(Int(food.nutrition.protein))g")
                NutrientInfo(label: "C", value: "\(Int(food.nutrition.carbs))g")
                NutrientInfo(label: "F", value: "\(Int(food.nutrition.fat))g")
            }
            
            HStack(spacing: 12) {
                Button("Edit") {
                    onEdit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                Button("Add to Log") {
                    onAdd()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
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

struct NutrientSummary: View {
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

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct EnhancedCameraPreview: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let capturedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> EnhancedCameraViewController {
        let controller = EnhancedCameraViewController()
        controller.onImageCaptured = onImageCaptured
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EnhancedCameraViewController, context: Context) {
        uiViewController.updateCapturedCount(capturedImages.count)
    }
}

class EnhancedCameraViewController: UIViewController {
    var onImageCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    private func setupOverlay() {
        // Add crop guide overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add crop guide
        let cropGuide = UIView()
        cropGuide.layer.borderColor = UIColor.white.cgColor
        cropGuide.layer.borderWidth = 2
        cropGuide.layer.cornerRadius = 12
        cropGuide.backgroundColor = UIColor.clear
        cropGuide.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(cropGuide)
        
        NSLayoutConstraint.activate([
            cropGuide.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            cropGuide.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -50),
            cropGuide.widthAnchor.constraint(equalTo: overlayView.widthAnchor, multiplier: 0.8),
            cropGuide.heightAnchor.constraint(equalTo: cropGuide.widthAnchor, multiplier: 0.75)
        ])
    }
    
    func updateCapturedCount(_ count: Int) {
        // Update UI to show captured count
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

#Preview {
    EnhancedFoodCameraView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
