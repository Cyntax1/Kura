//
//  AchievementRow.swift
//  Kura
//
//  Created by Rishith Chennupati on 8/6/25.
//

import SwiftUI

struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isUnlocked ? .yellow : .secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status indicator
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    VStack(spacing: 12) {
        AchievementRow(
            title: "First Fast",
            description: "Complete your first fasting session",
            isUnlocked: true,
            icon: "star.fill"
        )
        
        AchievementRow(
            title: "Week Warrior",
            description: "Maintain a 7-day fasting streak",
            isUnlocked: false,
            icon: "flame.fill"
        )
        
        AchievementRow(
            title: "Fast Master",
            description: "Complete 10 fasting sessions",
            isUnlocked: false,
            icon: "trophy.fill"
        )
    }
    .padding()
}
