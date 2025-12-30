//
//  FastingLiveActivity.swift
//  Kura
//
//  Created by Rishith Chennupati on 9/26/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FastingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that update during the activity
        var currentDuration: TimeInterval
        var remainingTime: TimeInterval
        var progressPercentage: Double
        var status: FastingStatus
        var isPaused: Bool
    }

    // Static properties that don't change during the activity
    var fastingType: FastingType
    var plannedDuration: TimeInterval
    var startTime: Date
    var sessionId: String
}

struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingAttributes.self) { context in
            // Lock screen/banner UI goes here
            FastingLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    FastingTypeIcon(type: context.attributes.fastingType)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FastingTimeRemaining(remainingTime: context.state.remainingTime)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    FastingProgressView(
                        progress: context.state.progressPercentage,
                        isPaused: context.state.isPaused
                    )
                }
            } compactLeading: {
                FastingTypeIcon(type: context.attributes.fastingType)
                    .font(.caption2)
            } compactTrailing: {
                Text(formatTime(context.state.remainingTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(context.state.isPaused ? .orange : .blue)
            } minimal: {
                FastingTypeIcon(type: context.attributes.fastingType)
                    .font(.caption2)
            }
        }
    }
}

struct FastingLiveActivityView: View {
    let context: ActivityViewContext<FastingAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Fasting type and status
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.fastingType.systemImage)
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text(context.attributes.fastingType.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(context.state.isPaused ? "Paused" : "Active")
                        .font(.caption)
                        .foregroundColor(context.state.isPaused ? .orange : .green)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Time remaining
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(context.state.remainingTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(context.state.isPaused ? .orange : .blue)
                    
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: context.state.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: context.state.isPaused ? .orange : .blue))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            // Duration info
            HStack {
                Text("Started: \(formatStartTime(context.attributes.startTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Goal: \(formatTime(context.attributes.plannedDuration))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct FastingTypeIcon: View {
    let type: FastingType
    
    var body: some View {
        Image(systemName: type.systemImage)
            .foregroundColor(.blue)
    }
}

struct FastingTimeRemaining: View {
    let remainingTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formatTime(remainingTime))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("left")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct FastingProgressView: View {
    let progress: Double
    let isPaused: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Fasting Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPaused ? .orange : .blue)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: isPaused ? .orange : .blue))
        }
    }
}

// MARK: - Helper Functions

private func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

private func formatStartTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#Preview("Fasting Live Activity", as: .content, using: FastingAttributes(
    fastingType: .intermittent,
    plannedDuration: 16 * 3600, // 16 hours
    startTime: Date().addingTimeInterval(-2 * 3600), // Started 2 hours ago
    sessionId: "preview"
)) {
    FastingLiveActivity()
} contentStates: {
    FastingAttributes.ContentState(
        currentDuration: 2 * 3600, // 2 hours elapsed
        remainingTime: 14 * 3600, // 14 hours remaining
        progressPercentage: 0.125, // 12.5% complete
        status: .active,
        isPaused: false
    )
    
    FastingAttributes.ContentState(
        currentDuration: 8 * 3600, // 8 hours elapsed
        remainingTime: 8 * 3600, // 8 hours remaining
        progressPercentage: 0.5, // 50% complete
        status: .paused,
        isPaused: true
    )
}
