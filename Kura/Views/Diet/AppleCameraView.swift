//
//  AppleCameraView.swift
//  Kura
//
//  Native Apple-style camera interface for food recognition
//

import SwiftUI
import AVFoundation

struct AppleCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var capturedImages: [UIImage] = []
    @State private var recognizedFoods: [RecognizedFoodItem] = []
    @State private var isProcessing = false
    @State private var showingResults = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    @State private var currentImageIndex = 0
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @StateObject private var aiService = AIFoodRecognitionService()
    @StateObject private var cameraModel = CameraModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraPermission == .authorized {
                if showingResults && !capturedImages.isEmpty {
                    resultsView
                } else {
                    nativeCameraView
                }
            } else {
                permissionView
            }
            
            // Processing overlay
            if isProcessing {
                processingOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkCameraPermission()
        }
        .onDisappear {
            cameraModel.stopSession()
        }
        .alert("Camera Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var nativeCameraView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview
                AppleCameraPreview(cameraModel: cameraModel)
                    .ignoresSafeArea()
                
                // Top Controls
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                        
                        Spacer()
                        
                        // Flash Control
                        Button(action: toggleFlash) {
                            Image(systemName: flashIconName)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Bottom Controls
                    VStack(spacing: 20) {
                        // Captured Images Preview
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
                                                    .font(.system(size: 20))
                                                    .offset(x: 5, y: -5)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 80)
                        }
                        
                        // Camera Controls Row
                        HStack {
                            // Gallery/Last Photo
                            Button(action: {}) {
                                if let lastImage = capturedImages.last {
                                    Image(uiImage: lastImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "photo.on.rectangle")
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            // Capture Button
                            Button(action: capturePhoto) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 85, height: 85)
                                }
                            }
                            .scaleEffect(cameraModel.isCapturing ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: cameraModel.isCapturing)
                            
                            Spacer()
                            
                            // Analyze Button
                            Button(action: analyzeImages) {
                                VStack(spacing: 4) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 24))
                                    
                                    Text("Analyze")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    capturedImages.isEmpty ? 
                                    Color.gray.opacity(0.3) : 
                                    Color.blue
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(capturedImages.isEmpty)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    }
                }
                
                // Meal Type Indicator
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Image(systemName: selectedMealType.systemImage)
                                .font(.system(size: 20))
                            
                            Text(selectedMealType.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var resultsView: some View {
        NavigationView {
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
            .navigationTitle("Food Recognition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Retake") {
                        capturedImages.removeAll()
                        recognizedFoods.removeAll()
                        showingResults = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
                FoodResultCard(
                    food: food,
                    onAdd: { addFoodEntry(food) }
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
                NutrientDisplay(label: "Calories", value: "\(totalCalories)", color: .red)
                NutrientDisplay(label: "Protein", value: "\(Int(totalProtein))g", color: .blue)
                NutrientDisplay(label: "Carbs", value: "\(Int(totalCarbs))g", color: .orange)
                NutrientDisplay(label: "Fat", value: "\(Int(totalFat))g", color: .yellow)
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
            
            Text("Try taking another photo with better lighting")
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
    
    private var flashIconName: String {
        switch flashMode {
        case .off: return "bolt.slash"
        case .on: return "bolt"
        case .auto: return "bolt.badge.a"
        @unknown default: return "bolt.slash"
        }
    }
    
    private func toggleFlash() {
        switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
        cameraModel.setFlashMode(flashMode)
    }
    
    private func checkCameraPermission() {
        cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Camera permission status: \(cameraPermission.rawValue)")
        
        if cameraPermission == .authorized {
            print("✅ Camera permission granted, starting session")
            // Start camera session when permission is granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cameraModel.startSession()
            }
        } else if cameraPermission == .notDetermined {
            print("❓ Camera permission not determined, requesting...")
            requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermission = granted ? .authorized : .denied
                if granted {
                    cameraModel.startSession()
                }
            }
        }
    }
    
    private func capturePhoto() {
        cameraModel.capturePhoto { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    capturedImages.append(image)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
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
                    errorMessage = error.localizedDescription
                    showingError = true
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
    
    private func addAllFoods() {
        for food in recognizedFoods {
            addFoodEntry(food)
        }
        dismiss()
    }
}

// MARK: - Supporting Views

struct FoodResultCard: View {
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
                
                Text("\(Int(food.nutrition.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 16) {
                AppleNutrientInfo(label: "Cal", value: "\(food.nutrition.calories)")
                AppleNutrientInfo(label: "P", value: "\(Int(food.nutrition.protein))g")
                AppleNutrientInfo(label: "C", value: "\(Int(food.nutrition.carbs))g")
                AppleNutrientInfo(label: "F", value: "\(Int(food.nutrition.fat))g")
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

struct NutrientDisplay: View {
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

struct AppleNutrientInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Camera Model

class CameraModel: NSObject, ObservableObject {
    @Published var isCapturing = false
    
    var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureCompletionHandler: ((Result<UIImage, Error>) -> Void)?
    
    override init() {
        super.init()
        print("🔧 Initializing CameraModel...")
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Back camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
                print("✅ Camera input added successfully")
            } else {
                print("❌ Cannot add camera input")
                return
            }
        } catch {
            print("❌ Error creating camera input: \(error)")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
            print("✅ Photo output added successfully")
        } else {
            print("❌ Cannot add photo output")
        }
    }
    
    func startSession() {
        guard let captureSession = captureSession else {
            print("❌ No capture session available")
            return
        }
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                print("✅ Camera session started")
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.stopRunning()
        }
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        // Flash mode will be set during capture
    }
    
    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(.failure(CameraError.noPhotoOutput))
            return
        }
        
        isCapturing = true
        captureCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        isCapturing = false
        
        if let error = error {
            captureCompletionHandler?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureCompletionHandler?(.failure(CameraError.imageProcessingFailed))
            return
        }
        
        captureCompletionHandler?(.success(image))
    }
}

enum CameraError: Error, LocalizedError {
    case noPhotoOutput
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotoOutput:
            return "Camera not available"
        case .imageProcessingFailed:
            return "Failed to process captured image"
        }
    }
}

// MARK: - Camera Preview

struct AppleCameraPreview: UIViewRepresentable {
    let cameraModel: CameraModel
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        previewView.cameraModel = cameraModel
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update handled by the UIView itself
    }
}

class CameraPreviewView: UIView {
    var cameraModel: CameraModel? {
        didSet {
            setupPreview()
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
    
    private func setupPreview() {
        guard let cameraModel = cameraModel,
              let session = cameraModel.captureSession else {
            return
        }
        
        layer.session = session
        layer.videoGravity = .resizeAspectFill
        
        // Start session if not running
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                print("✅ Camera session started from preview")
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.frame = bounds
    }
}

#Preview {
    AppleCameraView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
