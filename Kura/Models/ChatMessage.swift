//
//  ChatMessage.swift
//  Kura
//
//  AI Chatbot conversation model
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var tokensUsed: Int?
    
    init(role: MessageRole, content: String, tokensUsed: Int? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.tokensUsed = tokensUsed
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}
