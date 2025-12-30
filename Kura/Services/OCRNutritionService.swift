//
//  OCRNutritionService.swift
//  Kura
//
//  OCR-based nutrition label reading for packaged foods
//

import Foundation
import UIKit
import Vision

class OCRNutritionService: ObservableObject {
    
    func extractNutritionFromLabel(image: UIImage) async throws -> NutritionData? {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                let nutritionData = self.parseNutritionLabel(text: recognizedText)
                continuation.resume(returning: nutritionData)
            }
            
            // Configure for better nutrition label reading
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func parseNutritionLabel(text: String) -> NutritionData? {
        let lines = text.components(separatedBy: .newlines)
        
        var calories = 0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber = 0.0
        var sugar = 0.0
        var sodium = 0.0
        
        for line in lines {
            let cleanLine = line.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract calories
            if cleanLine.contains("calories") || cleanLine.contains("energy") {
                calories = extractNumber(from: cleanLine) ?? calories
            }
            
            // Extract protein
            if cleanLine.contains("protein") {
                protein = Double(extractNumber(from: cleanLine) ?? Int(protein))
            }
            
            // Extract carbohydrates
            if cleanLine.contains("carbohydrate") || cleanLine.contains("carbs") {
                carbs = Double(extractNumber(from: cleanLine) ?? Int(carbs))
            }
            
            // Extract fat
            if cleanLine.contains("fat") && !cleanLine.contains("saturated") {
                fat = Double(extractNumber(from: cleanLine) ?? Int(fat))
            }
            
            // Extract fiber
            if cleanLine.contains("fiber") || cleanLine.contains("fibre") {
                fiber = Double(extractNumber(from: cleanLine) ?? Int(fiber))
            }
            
            // Extract sugar
            if cleanLine.contains("sugar") {
                sugar = Double(extractNumber(from: cleanLine) ?? Int(sugar))
            }
            
            // Extract sodium
            if cleanLine.contains("sodium") {
                sodium = Double(extractNumber(from: cleanLine) ?? Int(sodium))
            }
        }
        
        // Only return data if we found at least calories
        guard calories > 0 else { return nil }
        
        return NutritionData(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: "per serving",
            confidence: 0.8 // OCR confidence
        )
    }
    
    private func extractNumber(from text: String) -> Int? {
        let pattern = #"\d+"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let numberString = String(text[Range(match.range, in: text)!])
            return Int(numberString)
        }
        
        return nil
    }
}

enum OCRError: Error {
    case imageProcessingFailed
    case textRecognitionFailed
    case parsingFailed
}
