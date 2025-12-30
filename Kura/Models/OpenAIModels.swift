//
//  OpenAIModels.swift
//  Kura
//
//  Shared OpenAI API response models
//

import Foundation

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}
