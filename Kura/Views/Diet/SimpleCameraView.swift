//
//  SimpleCameraView.swift
//  Kura
//
//  Minimal camera implementation for testing
//

import SwiftUI
import AVFoundation

struct SimpleCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImages: [UIImage] = []
    @State private var recognizedFoods: [RecognizedFoodItem] = []
    @State private var showingResults = false
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @StateObject private var aiService = AIFoodRecognitionService()
    
    let selectedMealType: MealType
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showingResults {
                resultsView
            } else {
                cameraView
            }
        }
        .navigationBarHidden(true)
    }
    
    private var cameraView: some View {
        ZStack {
            // Camera Preview
            SimpleCameraPreview { image in
                capturedImages.append(image)
            }
            .ignoresSafeArea()
            
            // Controls
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    
                    Spacer()
                    
                    Text(selectedMealType.rawValue)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Captured images
                    if !capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                    }
                    
                    // Camera controls
                    HStack {
                        Spacer()
                        
                        // Capture button - this will be handled by the camera preview
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 85, height: 85)
                            )
                        
                        Spacer()
                        
                        if !capturedImages.isEmpty {
                            Button("Analyze") {
                                analyzeImages()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .disabled(isProcessing)
                        } else {
                            Color.clear.frame(width: 80, height: 40)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var resultsView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image preview
                    if let firstImage = capturedImages.first {
                        Image(uiImage: firstImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                    
                    // Processing indicator
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Analyzing with GPT-4o...")
                                .font(.headline)
                            
                            Text("Identifying food and calculating calories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Recognition results
                    if !recognizedFoods.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recognized Foods")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(recognizedFoods, id: \.id) { food in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(food.name)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text("\(food.nutrition.calories) cal")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    HStack {
                                        Text("Protein: \(Int(food.nutrition.protein))g")
                                        Text("Carbs: \(Int(food.nutrition.carbs))g")
                                        Text("Fat: \(Int(food.nutrition.fat))g")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                    Button("Add to \(selectedMealType.rawValue)") {
                                        addFoodEntry(food)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    } else if !isProcessing && !capturedImages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("No Food Recognized")
                                .font(.headline)
                            
                            Text("The AI couldn't identify food in this image. Try taking another photo with better lighting.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Add Manually") {
                                dismiss()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
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
        .alert("AI Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    
    private func analyzeImages() {
        guard !capturedImages.isEmpty else { return }
        
        isProcessing = true
        showingResults = true
        
        Task {
            do {
                print("🧠 Starting GPT-4o analysis...")
                var allRecognizedFoods: [RecognizedFoodItem] = []
                
                for image in capturedImages {
                    let foods = try await aiService.recognizeFood(from: image)
                    allRecognizedFoods.append(contentsOf: foods)
                    print("✅ GPT-4o recognized \(foods.count) food(s)")
                }
                
                await MainActor.run {
                    recognizedFoods = allRecognizedFoods
                    isProcessing = false
                    
                    if allRecognizedFoods.isEmpty {
                        print("⚠️ No foods recognized by GPT-4o")
                    } else {
                        let totalCalories = allRecognizedFoods.reduce(0) { $0 + $1.nutrition.calories }
                        print("✅ Total calories calculated: \(totalCalories)")
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "GPT-4o Analysis Error: \(error.localizedDescription)"
                    showingError = true
                    print("❌ GPT-4o error: \(error)")
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
        
        print("✅ Added \(food.name) (\(food.nutrition.calories) cal) to \(selectedMealType.rawValue)")
        
        // Remove the added food from the list
        recognizedFoods.removeAll { $0.id == food.id }
        
        // If no more foods, dismiss
        if recognizedFoods.isEmpty {
            dismiss()
        }
    }
}

struct SimpleCameraPreview: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> SimpleCameraViewController {
        let controller = SimpleCameraViewController()
        controller.onImageCaptured = onImageCaptured
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SimpleCameraViewController, context: Context) {
        // No updates needed
    }
}

class SimpleCameraViewController: UIViewController {
    var onImageCaptured: ((UIImage) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("❌ Unable to access back camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            photoOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                
                setupLivePreview()
                print("✅ Camera setup successful")
            }
        } catch {
            print("❌ Error setting up camera: \(error)")
        }
    }
    
    private func setupLivePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            print("✅ Camera session started")
        }
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(capturePhoto))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Capturing photo...")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

extension SimpleCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Photo capture error: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to convert photo to image")
            return
        }
        
        print("✅ Photo captured successfully")
        DispatchQueue.main.async {
            self.onImageCaptured?(image)
        }
    }
}

#Preview {
    SimpleCameraView(selectedMealType: .lunch)
}
