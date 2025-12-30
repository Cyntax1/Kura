//
//  FastingCompletionView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI

struct FastingCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    let session: FastingSession
    
    @State private var showConfetti = false
    @State private var animateStats = false
    @State private var animateButtons = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    // Celebration header
                    VStack(spacing: 16) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .scaleEffect(animateStats ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateStats)
                        
                        Text("Congratulations!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("You've successfully completed your \(session.type.rawValue.lowercased())!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Achievement badge
                    achievementBadge
                    
                    // Fast statistics
                    fastStatsSection
                    
                    // Motivational message
                    motivationalMessage
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var achievementBadge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("DONE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(animateStats ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateStats)
            
            Text("Fast Completed")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private var fastStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Achievement")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                CompletionStatCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: formatDuration(session.actualDuration),
                    subtitle: "Total time fasted",
                    color: .blue
                )
                .scaleEffect(animateStats ? 1.0 : 0.9)
                .opacity(animateStats ? 1.0 : 0.0)
                .animation(.spring(response: 0.6).delay(0.3), value: animateStats)
                
                CompletionStatCard(
                    icon: "target",
                    title: "Goal Achievement",
                    value: "\(Int((session.actualDuration / session.plannedDuration) * 100))%",
                    subtitle: "Of planned duration",
                    color: .green
                )
                .scaleEffect(animateStats ? 1.0 : 0.9)
                .opacity(animateStats ? 1.0 : 0.0)
                .animation(.spring(response: 0.6).delay(0.4), value: animateStats)
                
                if session.totalPausedDuration > 0 {
                    CompletionStatCard(
                        icon: "pause.fill",
                        title: "Paused Time",
                        value: formatDuration(session.totalPausedDuration),
                        subtitle: "Time spent paused",
                        color: .orange
                    )
                    .scaleEffect(animateStats ? 1.0 : 0.9)
                    .opacity(animateStats ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6).delay(0.5), value: animateStats)
                }
                
                CompletionStatCard(
                    icon: "calendar",
                    title: "Completed On",
                    value: formatDate(session.endTime ?? Date()),
                    subtitle: "Achievement date",
                    color: .purple
                )
                .scaleEffect(animateStats ? 1.0 : 0.9)
                .opacity(animateStats ? 1.0 : 0.0)
                .animation(.spring(response: 0.6).delay(0.6), value: animateStats)
            }
        }
    }
    
    private var motivationalMessage: some View {
        VStack(spacing: 12) {
            Text("🎉 Amazing Work! 🎉")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(getMotivationalMessage())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .scaleEffect(animateStats ? 1.0 : 0.9)
        .opacity(animateStats ? 1.0 : 0.0)
        .animation(.spring(response: 0.6).delay(0.7), value: animateStats)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Share achievement
                shareAchievement()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Achievement")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .scaleEffect(animateButtons ? 1.0 : 0.9)
            .opacity(animateButtons ? 1.0 : 0.0)
            .animation(.spring(response: 0.6).delay(0.8), value: animateButtons)
            
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .scaleEffect(animateButtons ? 1.0 : 0.9)
            .opacity(animateButtons ? 1.0 : 0.0)
            .animation(.spring(response: 0.6).delay(0.9), value: animateButtons)
        }
    }
    
    // MARK: - Methods
    
    private func startAnimations() {
        withAnimation {
            showConfetti = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateStats = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateButtons = true
        }
        
        // Stop confetti after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showConfetti = false
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getMotivationalMessage() -> String {
        let messages = [
            "You've shown incredible discipline and willpower. This achievement is a testament to your commitment to health and wellness.",
            "Fasting is not just about abstaining from food—it's about building mental strength and self-control. You've proven you have both!",
            "Every fast completed is a step toward better health and increased mindfulness. Keep up the amazing work!",
            "You've successfully reset your relationship with food and demonstrated remarkable self-discipline. Congratulations!",
            "This fast represents more than time—it represents your dedication to personal growth and health. Well done!"
        ]
        
        return messages.randomElement() ?? messages[0]
    }
    
    private func shareAchievement() {
        let text = "I just completed a \(session.type.rawValue.lowercased()) lasting \(formatDuration(session.actualDuration))! 🎉 #FastingGoals #HealthJourney #KuraApp"
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct CompletionStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size.width, height: piece.size.height)
                    .position(piece.position)
                    .rotationEffect(piece.rotation)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan]
        
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -50
                ),
                size: CGSize(
                    width: CGFloat.random(in: 8...15),
                    height: CGFloat.random(in: 8...15)
                ),
                color: colors.randomElement() ?? .blue,
                rotation: Angle(degrees: Double.random(in: 0...360)),
                opacity: Double.random(in: 0.7...1.0)
            )
            
            confettiPieces.append(piece)
            
            // Animate the piece falling
            withAnimation(.linear(duration: Double.random(in: 2...4))) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position.y = UIScreen.main.bounds.height + 100
                    confettiPieces[index].rotation = Angle(degrees: Double.random(in: 360...720))
                }
            }
        }
        
        // Remove confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            confettiPieces.removeAll()
        }
    }
}

struct ConfettiPiece {
    let id: UUID
    var position: CGPoint
    let size: CGSize
    let color: Color
    var rotation: Angle
    let opacity: Double
}

#Preview {
    let session = FastingSession(type: .twentyFourHour, plannedDuration: 24 * 3600, notes: "Test fast")
    session.status = .completed
    session.endTime = Date()
    session.actualDuration = 24 * 3600
    
    return FastingCompletionView(session: session)
}
