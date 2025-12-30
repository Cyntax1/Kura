//
//  AIChatbotView.swift
//  Kura
//
//  AI Assistant that knows everything about the user
//

import SwiftUI
import SwiftData

struct AIChatbotView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \ChatMessage.timestamp) private var allMessages: [ChatMessage]
    @Query private var userProfiles: [UserProfile]
    @Query private var fastingSessions: [FastingSession]
    @Query private var foodEntries: [FoodEntry]
    @Query private var dietPlans: [DietPlan]
    
    @StateObject private var chatService = AIChatbotService()
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var systemPrompt = ""
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Welcome message
                            if allMessages.isEmpty {
                                welcomeMessage
                                    .padding(.top, 40)
                            }
                            
                            // Chat messages
                            ForEach(allMessages.filter { $0.role != .system }) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: allMessages.count) { oldValue, newValue in
                        if let lastMessage = allMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Ask me anything about your health...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                        .focused($isTextFieldFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(isLoading || messageText.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Kura AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: refreshContext) {
                            Label("Refresh My Data", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: viewContext) {
                            Label("View My Data", systemImage: "info.circle")
                        }
                        
                        Button(role: .destructive, action: clearChat) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                generateSystemPrompt()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text("Hi, I'm Kura AI! 👋")
                .font(.title)
                .fontWeight(.bold)
            
            Text("I know everything about your health journey")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                ChatInfoRow(icon: "person.fill", text: "Your profile and goals")
                ChatInfoRow(icon: "chart.bar.fill", text: "All your fasting sessions")
                ChatInfoRow(icon: "fork.knife", text: "Every meal you've logged")
                ChatInfoRow(icon: "target", text: "Your diet plans")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Text("Ask me anything about your health data!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        // Save user message
        let userMessage = ChatMessage(role: .user, content: message)
        modelContext.insert(userMessage)
        
        // Clear input
        messageText = ""
        isTextFieldFocused = false
        isLoading = true
        
        // Generate fresh system prompt with latest data
        generateSystemPrompt()
        
        Task {
            do {
                let response = try await chatService.sendMessage(
                    userMessage: message,
                    conversationHistory: allMessages,
                    systemPrompt: systemPrompt
                )
                
                await MainActor.run {
                    // Save assistant response
                    let assistantMessage = ChatMessage(role: .assistant, content: response)
                    modelContext.insert(assistantMessage)
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func generateSystemPrompt() {
        let profile = userProfiles.first
        systemPrompt = chatService.generateSystemPrompt(
            userProfile: profile,
            fastingSessions: fastingSessions,
            foodEntries: foodEntries,
            dietPlans: dietPlans
        )
    }
    
    private func refreshContext() {
        generateSystemPrompt()
        
        // Show feedback
        let message = ChatMessage(role: .assistant, content: "✅ I've refreshed my knowledge of your latest health data!")
        modelContext.insert(message)
    }
    
    private func viewContext() {
        // Show the system prompt to user (for transparency)
        let message = ChatMessage(role: .assistant, content: "Here's everything I know about you:\n\n\(systemPrompt)")
        modelContext.insert(message)
    }
    
    private func clearChat() {
        // Delete all messages
        for message in allMessages {
            modelContext.delete(message)
        }
    }
}

// MARK: - Supporting Views

struct ChatBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 50) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(
                        isUser ?
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isUser { Spacer(minLength: 50) }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatbotView()
        .modelContainer(for: [ChatMessage.self, UserProfile.self, FastingSession.self, FoodEntry.self, DietPlan.self])
}
