//
//  ModernFastingTimer.swift
//  Kura
//
//  Created by Rishith Chennupati on 10/5/25.
//

import SwiftUI

struct ModernFastingTimer: View {
    let session: FastingSession
    @State private var animationProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Modern circular progress with floating time segments
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 240, height: 240)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: session.progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: session.progressPercentage)
                
                // Floating time segments
                modernTimeDisplay
                
                // Animated pulse for active sessions
                if session.isActive {
                    Circle()
                        .stroke(gradientColors.first?.opacity(0.3) ?? .clear, lineWidth: 2)
                        .frame(width: 240 + pulseScale * 20, height: 240 + pulseScale * 20)
                        .opacity(2 - pulseScale)
                        .scaleEffect(pulseScale)
                }
            }
            
            // Status and progress info
            modernStatusSection
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: session.isActive) { _, isActive in
            if isActive {
                startAnimations()
            }
        }
    }
    
    private var modernTimeDisplay: some View {
        VStack(spacing: 16) {
            // Main time display with floating segments
            HStack(spacing: 12) {
                TimeSegment(
                    value: hours,
                    label: "HRS",
                    color: gradientColors.first ?? .blue
                )
                
                TimeSeparator()
                
                TimeSegment(
                    value: minutes,
                    label: "MIN",
                    color: gradientColors.last ?? .cyan
                )
                
                if hours == 0 {
                    TimeSeparator()
                    
                    TimeSegment(
                        value: seconds,
                        label: "SEC",
                        color: .green
                    )
                }
            }
            
            // Progress percentage with modern styling
            Text("\(Int(session.progressPercentage * 100))%")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(gradientColors.first?.opacity(0.1) ?? Color.blue.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(gradientColors.first?.opacity(0.3) ?? Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    private var modernStatusSection: some View {
        VStack(spacing: 12) {
            // Status badge
            HStack(spacing: 8) {
                Circle()
                    .fill(session.isPaused ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                    .scaleEffect(session.isActive ? pulseScale : 1.0)
                
                Text(session.isPaused ? "PAUSED" : "ACTIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(session.isPaused ? .orange : .green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill((session.isPaused ? Color.orange : Color.green).opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke((session.isPaused ? Color.orange : Color.green).opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Remaining time info
            VStack(spacing: 4) {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatRemainingTime(session.remainingTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeComponents: (hours: Int, minutes: Int, seconds: Int) {
        let duration = session.currentDuration
        let h = Int(duration) / 3600
        let m = Int(duration) % 3600 / 60
        let s = Int(duration) % 60
        return (h, m, s)
    }
    
    private var hours: Int { timeComponents.hours }
    private var minutes: Int { timeComponents.minutes }
    private var seconds: Int { timeComponents.seconds }
    
    private var gradientColors: [Color] {
        if session.isPaused {
            return [.orange, .yellow]
        } else if session.progressPercentage > 0.8 {
            return [.green, .mint]
        } else if session.progressPercentage > 0.5 {
            return [.blue, .cyan]
        } else {
            return [.purple, .blue]
        }
    }
    
    // MARK: - Methods
    
    private func startAnimations() {
        if session.isActive {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        } else {
            pulseScale = 1.0
        }
    }
    
    private func formatRemainingTime(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TimeSegment: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .monospacedDigit()
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct TimeSeparator: View {
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color.primary.opacity(0.6))
                .frame(width: 4, height: 4)
            
            Circle()
                .fill(Color.primary.opacity(0.6))
                .frame(width: 4, height: 4)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                opacity = 0.3
            }
        }
    }
}

// MARK: - Alternative Minimalist Timer

struct MinimalistFastingTimer: View {
    let session: FastingSession
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Wave progress indicator
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                
                // Animated wave fill
                GeometryReader { geometry in
                    WaveShape(offset: waveOffset, progress: session.progressPercentage)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: waveOffset)
                }
                .frame(height: 120)
                
                // Time display overlay
                VStack(spacing: 8) {
                    Text(formatElapsedTime())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("ELAPSED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Simple progress bar with time markers
            progressBarWithMarkers
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = 1
            }
        }
    }
    
    private var progressBarWithMarkers: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * session.progressPercentage, height: 8)
                        .animation(.spring(response: 0.8), value: session.progressPercentage)
                }
            }
            .frame(height: 8)
            
            // Time markers
            HStack {
                Text("0h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatRemainingTime())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTotalTime())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var gradientColors: [Color] {
        if session.isPaused {
            return [.orange, .yellow]
        } else if session.progressPercentage > 0.8 {
            return [.green, .mint]
        } else {
            return [.blue, .cyan]
        }
    }
    
    private func formatElapsedTime() -> String {
        let hours = Int(session.currentDuration) / 3600
        let minutes = Int(session.currentDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatRemainingTime() -> String {
        let hours = Int(session.remainingTime) / 3600
        let minutes = Int(session.remainingTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    private func formatTotalTime() -> String {
        let hours = Int(session.plannedDuration) / 3600
        return "\(hours)h goal"
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var progress: Double
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 10
        let fillHeight = rect.height * (1 - CGFloat(progress))
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: fillHeight))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + offset) * 2 * .pi)
            let y = fillHeight + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        ModernFastingTimer(session: FastingSession(type: .intermittent, plannedDuration: 16 * 3600))
        
        MinimalistFastingTimer(session: FastingSession(type: .water, plannedDuration: 24 * 3600))
    }
    .padding()
}
