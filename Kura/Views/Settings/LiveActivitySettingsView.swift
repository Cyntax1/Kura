//
//  LiveActivitySettingsView.swift
//  Kura
//
//  Created by Rishith Chennupati on 9/26/25.
//

import SwiftUI
import ActivityKit

struct LiveActivitySettingsView: View {
    @State private var isLiveActivitiesEnabled = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Live Activities")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("See your fasting progress on the lock screen and Dynamic Island")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Feature Preview
            VStack(spacing: 16) {
                Text("What you'll see:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    LiveActivityFeatureRow(
                        icon: "lock.fill",
                        title: "Lock Screen Widget",
                        description: "Real-time fasting progress with countdown timer"
                    )
                    
                    LiveActivityFeatureRow(
                        icon: "iphone.circle.fill",
                        title: "Dynamic Island",
                        description: "Compact timer display on iPhone 14 Pro and later"
                    )
                    
                    LiveActivityFeatureRow(
                        icon: "pause.circle.fill",
                        title: "Status Updates",
                        description: "See when your fast is paused or completed"
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Status Section
            VStack(spacing: 16) {
                HStack {
                    Text("Current Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: isLiveActivitiesEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isLiveActivitiesEnabled ? .green : .red)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Activities")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(isLiveActivitiesEnabled ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundColor(isLiveActivitiesEnabled ? .green : .secondary)
                    }
                    
                    Spacer()
                    
                    if !isLiveActivitiesEnabled {
                        Button("Enable") {
                            showingPermissionAlert = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            if !isLiveActivitiesEnabled {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Enable:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionStep(
                            number: 1,
                            text: "Open Settings app on your device"
                        )
                        
                        InstructionStep(
                            number: 2,
                            text: "Scroll down and tap \"Kura\""
                        )
                        
                        InstructionStep(
                            number: 3,
                            text: "Toggle \"Live Activities\" to ON"
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkLiveActivityPermission()
        }
        .alert("Live Activities Not Available", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enable Live Activities, please go to Settings > Kura > Live Activities and turn it on.")
        }
    }
    
    private func checkLiveActivityPermission() {
        isLiveActivitiesEnabled = LiveActivityService.shared.checkLiveActivityPermission()
    }
}

struct LiveActivityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    LiveActivitySettingsView()
}
