//
//  FoodCameraView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import AVFoundation
import Vision

struct FoodCameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedMealType: MealType
    
    @State private var capturedImage: UIImage?
    @State private var recognizedFoods: [RecognizedFood] = []
    @State private var isProcessing = false
    @State private var showingResults = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationView {
            ZStack {
                if cameraPermission == .authorized {
                    if let image = capturedImage {
                        resultsView
                    } else {
                        CameraPreview(onImageCaptured: handleImageCapture)
                            .ignoresSafeArea()
                    }
                } else {
                    permissionView
                }
                
                // Processing overlay
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
                
                if capturedImage != nil && !isProcessing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Retake") {
                            capturedImage = nil
                            recognizedFoods = []
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            checkCameraPermission()
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
            
            Text("Kura needs camera access to recognize food items and automatically log your meals.")
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
                
                // Recognition results
                if recognizedFoods.isEmpty && !isProcessing {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("No Food Recognized")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Try taking another photo or add food manually")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Manually") {
                            dismiss()
                            // This would trigger the manual add flow
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recognized Foods")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(recognizedFoods, id: \.id) { food in
                            RecognizedFoodCard(
                                food: food,
                                onAdd: { addFoodEntry(food) }
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Analyzing Food...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Using AI to identify food items")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
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
    
    private func handleImageCapture(_ image: UIImage) {
        capturedImage = image
        processImage(image)
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        // Simulate AI food recognition with mock data
        // In the real app, this calls OpenAI GPT-4o for food recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            recognizedFoods = generateMockRecognizedFoods()
            isProcessing = false
        }
    }
    
    private func generateMockRecognizedFoods() -> [RecognizedFood] {
        let mockFoods = [
            RecognizedFood(
                name: "Grilled Chicken Breast",
                confidence: 0.92,
                calories: 231,
                protein: 43.5,
                carbs: 0,
                fat: 5.0,
                quantity: 1,
                unit: "piece"
            ),
            RecognizedFood(
                name: "Brown Rice",
                confidence: 0.87,
                calories: 216,
                protein: 5.0,
                carbs: 45.0,
                fat: 1.8,
                quantity: 1,
                unit: "cup"
            ),
            RecognizedFood(
                name: "Steamed Broccoli",
                confidence: 0.94,
                calories: 55,
                protein: 3.7,
                carbs: 11.2,
                fat: 0.6,
                quantity: 1,
                unit: "cup"
            )
        ]
        
        // Return 1-3 random foods to simulate recognition
        return Array(mockFoods.shuffled().prefix(Int.random(in: 1...3)))
    }
    
    private func addFoodEntry(_ recognizedFood: RecognizedFood) {
        let foodEntry = FoodEntry(
            name: recognizedFood.name,
            calories: recognizedFood.calories,
            protein: recognizedFood.protein,
            carbs: recognizedFood.carbs,
            fat: recognizedFood.fat,
            quantity: recognizedFood.quantity,
            unit: recognizedFood.unit,
            mealType: selectedMealType,
            imageData: capturedImage?.jpegData(compressionQuality: 0.8),
            isAIRecognized: true,
            confidence: recognizedFood.confidence
        )
        
        modelContext.insert(foodEntry)
        try? modelContext.save()
        
        // Remove the added food from the list
        recognizedFoods.removeAll { $0.id == recognizedFood.id }
        
        // If no more foods, dismiss
        if recognizedFoods.isEmpty {
            dismiss()
        }
    }
}

struct RecognizedFood {
    let id = UUID()
    let name: String
    let confidence: Double
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let quantity: Double
    let unit: String
}

struct RecognizedFoodCard: View {
    let food: RecognizedFood
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(food.confidence * 100))%")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(confidenceColor.opacity(0.2))
                        .foregroundColor(confidenceColor)
                        .cornerRadius(4)
                }
                
                Text("\(Int(food.quantity)) \(food.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    NutrientInfo(label: "Cal", value: "\(food.calories)")
                    NutrientInfo(label: "P", value: "\(Int(food.protein))g")
                    NutrientInfo(label: "C", value: "\(Int(food.carbs))g")
                    NutrientInfo(label: "F", value: "\(Int(food.fat))g")
                }
            }
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        if food.confidence >= 0.8 {
            return .green
        } else if food.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct NutrientInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onImageCaptured = onImageCaptured
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var onImageCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
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
    
    private func setupUI() {
        // Capture button
        let captureButton = UIButton(type: .system)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.frame = CGRect(x: view.center.x - 35, y: view.bounds.height - 120, width: 70, height: 70)
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        // Add border
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        view.addSubview(captureButton)
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        DispatchQueue.main.async {
            self.onImageCaptured?(image)
        }
    }
}

#Preview {
    FoodCameraView(selectedMealType: .lunch)
        .modelContainer(for: [FoodEntry.self])
}
