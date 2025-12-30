//
//  AITestView.swift
//  Kura
//
//  Test view for AI food recognition functionality
//

import SwiftUI

struct AITestView: View {
    @StateObject private var aiService = AIFoodRecognitionService()
    @State private var testResult = "Ready to test AI recognition"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Food Recognition Test")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(testResult)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .multilineTextAlignment(.center)
            
            if isLoading {
                ProgressView("Testing AI...")
            }
            
            Button("Test API Configuration") {
                testAPIConfiguration()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Configuration Status:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: APIConfig.openAIAPIKey.starts(with: "sk-") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(APIConfig.openAIAPIKey.starts(with: "sk-") ? .green : .red)
                    Text("OpenAI API Key: \(APIConfig.openAIAPIKey.starts(with: "sk-") ? "✓ Configured" : "✗ Missing")")
                }
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Using GPT-4o Vision Model")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No other APIs needed!")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("AI Test")
    }
    
    private func testAPIConfiguration() {
        isLoading = true
        testResult = "Testing API configuration..."
        
        Task {
            do {
                // Test with a simple food image (we'll use a placeholder test)
                let testImage = createTestImage()
                let results = try await aiService.recognizeFood(from: testImage)
                
                await MainActor.run {
                    if results.isEmpty {
                        testResult = "⚠️ API working but no food recognized in test image. Try with a real food photo."
                    } else {
                        let totalCalories = results.reduce(0) { $0 + $1.nutrition.calories }
                        testResult = "✅ Success! Recognized \(results.count) food(s) with \(totalCalories) total calories"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Error: \(error.localizedDescription)\n\nCheck your API keys and internet connection."
                    isLoading = false
                }
            }
        }
    }
    
    private func createTestImage() -> UIImage {
        // Create a simple test image with text
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.systemBackground.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let text = "🍎 Apple"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24),
            .foregroundColor: UIColor.label
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}

#Preview {
    NavigationView {
        AITestView()
    }
}
