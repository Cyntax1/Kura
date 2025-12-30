//
//  StatCard.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Title and Subtitle
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(
            title: "Total Fasts",
            value: "12",
            subtitle: "completed",
            icon: "clock.fill",
            color: .blue
        )
        
        StatCard(
            title: "Success Rate",
            value: "85%",
            subtitle: "completion",
            icon: "checkmark.circle.fill",
            color: .green
        )
        
        StatCard(
            title: "Avg Duration",
            value: "18",
            subtitle: "hours",
            icon: "timer",
            color: .orange
        )
    }
    .padding()
}
