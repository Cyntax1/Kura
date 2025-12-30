//
//  FastingDetailView.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI
import SwiftData

struct FastingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let session: FastingSession
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showingCompletionView = false
    @State private var showingStopAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with fasting type
                VStack(spacing: 12) {
                    Image(systemName: session.type.systemImage)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(session.type.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(session.type.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Progress Circle
                progressCircle
                
                // Time Information
                timeInfoSection
                
                // Control Buttons
                controlButtons
                
                // Stats Section
                statsSection
                
                // Notes Section
                if !session.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            // Update for both active and paused sessions to show correct time
            if session.isActive || session.isPaused {
                checkForCompletion()
                // Force UI update by saving context
                try? modelContext.save()
            }
        }
        .onAppear {
            // Restart timer when view appears
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        }
        .onDisappear {
            // Stop timer when view disappears to save resources
            timer.upstream.connect().cancel()
        }
        .sheet(isPresented: $showingCompletionView) {
            FastingCompletionView(session: session)
        }
        .alert("Stop Fasting?", isPresented: $showingStopAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Stop", role: .destructive) {
                stopFasting()
            }
        } message: {
            Text("Are you sure you want to stop your fast? Your progress will be saved.")
        }
    }
    
    private var progressCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 200, height: 200)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: session.progressPercentage)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: session.progressPercentage)
            
            // Center content
            VStack(spacing: 4) {
                Text(formatDuration(session.currentDuration))
                    .font(.title)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                Text("\(Int(session.progressPercentage * 100))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var timeInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                TimeInfoCard(
                    title: "Started",
                    value: formatTime(session.startTime),
                    icon: "play.fill",
                    color: .green
                )
                
                TimeInfoCard(
                    title: "Target",
                    value: formatDuration(session.plannedDuration),
                    icon: "target",
                    color: .blue
                )
            }
            
            HStack {
                TimeInfoCard(
                    title: "Remaining",
                    value: formatDuration(session.remainingTime),
                    icon: "clock.fill",
                    color: .orange
                )
                
                TimeInfoCard(
                    title: "Status",
                    value: session.status.rawValue.capitalized,
                    icon: statusIcon,
                    color: statusColor
                )
            }
        }
    }
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if session.isActive {
                Button(action: pauseFasting) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause Fast")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else if session.isPaused {
                Button(action: resumeFasting) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume Fast")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button(action: { showingStopAlert = true }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Fast")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fast Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatRow(label: "Total Paused Time", value: formatDuration(session.totalPausedDuration))
                StatRow(label: "Active Time", value: formatDuration(session.currentDuration))
                StatRow(label: "Started At", value: formatDateTime(session.startTime))
                
                if let pausedTime = session.pausedTime {
                    StatRow(label: "Paused At", value: formatDateTime(pausedTime))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(session.notes)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        switch session.status {
        case .active: return "play.fill"
        case .paused: return "pause.fill"
        case .completed: return "checkmark.circle.fill"
        case .stopped: return "stop.fill"
        }
    }
    
    private var statusColor: Color {
        switch session.status {
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        case .stopped: return .red
        }
    }
    
    // MARK: - Methods
    
    private func pauseFasting() {
        session.status = .paused
        session.pausedTime = Date()
        try? modelContext.save()
    }
    
    private func resumeFasting() {
        if let pausedTime = session.pausedTime {
            session.totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        session.status = .active
        session.pausedTime = nil
        try? modelContext.save()
    }
    
    private func stopFasting() {
        session.status = .stopped
        session.endTime = Date()
        session.actualDuration = session.currentDuration
        try? modelContext.save()
        dismiss()
    }
    
    private func checkForCompletion() {
        if session.isActive && session.currentDuration >= session.plannedDuration {
            completeFasting()
        }
    }
    
    private func completeFasting() {
        session.status = .completed
        session.endTime = Date()
        session.actualDuration = session.currentDuration
        try? modelContext.save()
        showingCompletionView = true
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TimeInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}

#Preview {
    let session = FastingSession(type: .twentyFourHour, plannedDuration: 24 * 3600, notes: "My first 24-hour fast!")
    
    return FastingDetailView(session: session)
        .modelContainer(for: [FastingSession.self])
}
