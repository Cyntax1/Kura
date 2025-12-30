//
//  ModernDurationSlider.swift
//  Kura
//
//  Created by Rishith Chennupati on 9/26/25.
//

import SwiftUI

struct ModernDurationSlider: View {
    @Binding var duration: Double // in hours
    let range: ClosedRange<Double>
    let step: Double
    
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(duration: Binding<Double>, range: ClosedRange<Double> = 1...72, step: Double = 0.5) {
        self._duration = duration
        self.range = range
        self.step = step
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Duration Display
            VStack(spacing: 8) {
                Text(formatDuration(duration))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                
                Text("Fasting Duration")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Custom Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 16)
                    
                    // Progress Track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(in: geometry), height: 16)
                        .animation(.easeInOut(duration: 0.2), value: duration)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .offset(x: thumbOffset(in: geometry))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        hapticFeedback.impactOccurred()
                                    }
                                    
                                    let newValue = valueFromOffset(value.location.x, in: geometry)
                                    let steppedValue = round(newValue / step) * step
                                    
                                    if abs(steppedValue - duration) >= step {
                                        duration = max(range.lowerBound, min(range.upperBound, steppedValue))
                                        hapticFeedback.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    hapticFeedback.impactOccurred()
                                }
                        )
                }
            }
            .frame(height: 40)
            
            // Quick Duration Buttons
            HStack(spacing: 12) {
                ForEach(quickDurations, id: \.self) { quickDuration in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            duration = quickDuration
                        }
                        hapticFeedback.impactOccurred()
                    }) {
                        Text(formatQuickDuration(quickDuration))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(duration == quickDuration ? .white : .blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(duration == quickDuration ? Color.blue : Color.blue.opacity(0.1))
                            )
                    }
                    .scaleEffect(duration == quickDuration ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3), value: duration)
                }
            }
            
            // Range Labels
            HStack {
                Text(formatQuickDuration(range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatQuickDuration(range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var thumbSize: CGFloat {
        isDragging ? 32 : 28
    }
    
    private var gradientColors: [Color] {
        if duration <= 12 {
            return [.green, .mint]
        } else if duration <= 24 {
            return [.blue, .cyan]
        } else if duration <= 48 {
            return [.orange, .yellow]
        } else {
            return [.red, .pink]
        }
    }
    
    private var quickDurations: [Double] {
        [12, 16, 18, 24, 36, 48]
    }
    
    // MARK: - Helper Methods
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        let progress = (duration - range.lowerBound) / (range.upperBound - range.lowerBound)
        return geometry.size.width * progress
    }
    
    private func thumbOffset(in geometry: GeometryProxy) -> CGFloat {
        let progress = (duration - range.lowerBound) / (range.upperBound - range.lowerBound)
        return (geometry.size.width - thumbSize) * progress
    }
    
    private func valueFromOffset(_ offset: CGFloat, in geometry: GeometryProxy) -> Double {
        let progress = offset / geometry.size.width
        return range.lowerBound + (range.upperBound - range.lowerBound) * Double(progress)
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalHours = Int(hours)
        let minutes = Int((hours - Double(totalHours)) * 60)
        
        if totalHours >= 24 {
            let days = totalHours / 24
            let remainingHours = totalHours % 24
            if remainingHours == 0 && minutes == 0 {
                return "\(days)d"
            } else if minutes == 0 {
                return "\(days)d \(remainingHours)h"
            } else {
                return "\(days)d \(remainingHours)h \(minutes)m"
            }
        } else if minutes == 0 {
            return "\(totalHours)h"
        } else {
            return "\(totalHours)h \(minutes)m"
        }
    }
    
    private func formatQuickDuration(_ hours: Double) -> String {
        let totalHours = Int(hours)
        if totalHours >= 24 {
            let days = totalHours / 24
            return "\(days)d"
        } else {
            return "\(totalHours)h"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        ModernDurationSlider(duration: .constant(16))
        ModernDurationSlider(duration: .constant(24))
        ModernDurationSlider(duration: .constant(48))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
