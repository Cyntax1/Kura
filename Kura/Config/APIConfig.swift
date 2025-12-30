//
//  APIConfig.swift
//  Kura
//

import Foundation

struct APIConfig {
    // ONLY OpenAI API - No other APIs needed!
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    
    // Configuration validation - only checks OpenAI
    static var isConfigured: Bool {
        return !openAIAPIKey.isEmpty && !openAIAPIKey.contains("your-")
    }
    
    // API endpoints - only OpenAI
    struct Endpoints {
        static let openAI = "https://api.openai.com/v1/chat/completions"
    }
    
    // Using latest OpenAI vision model with best image recognition
    // Available models: gpt-4o, gpt-4o-mini, o1-preview, o1-mini
    // Check https://platform.openai.com/docs/models for latest models
    // Note: o1 models have different pricing and capabilities
    static let visionModel = "gpt-4o"
}

// MARK: - Setup Instructions
/*
 OpenAI API Setup:
 
 1. Get your API key:
    - Go to https://platform.openai.com/api-keys
    - Create a new API key
    - Copy the key (starts with "sk-")
 
 2. Add to this file:
    - Replace the openAIAPIKey value above with your key
    - That's it! No other APIs needed.
 
 3. Features:
    - GPT-4o Vision model analyzes food images
    - Returns complete nutrition data (calories, protein, carbs, fat, etc.)
    - Identifies multiple foods in one image
    - Estimates portion sizes
    - Cost: ~$0.01-0.03 per image analysis
 
 Note: Check OpenAI docs for latest available vision models
      - gpt-4o: Best for complex vision tasks
      - gpt-4o-mini: Faster and cheaper alternative
      - o1-preview/o1-mini: Advanced reasoning (different pricing)
 */
