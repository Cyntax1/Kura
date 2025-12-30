//
//  AppleHealthStepView.swift
//  Kura
//
//  Apple Health onboarding step
//

import SwiftUI

struct AppleHealthStepView: View {
    @StateObject private var healthKitService = HealthKitService()
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.red.opacity(0.1),
                    Color.pink.opacity(0.05),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 40)
                    
                    // Hero section
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Connect Apple Health")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Track workouts and calories burned automatically")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Benefits cards
                    VStack(spacing: 16) {
                        HealthBenefitCard(
                            icon: "figure.run",
                            title: "Workout Tracking",
                            description: "See all your workouts and activities",
                            color: .orange
                        )
                        
                        HealthBenefitCard(
                            icon: "flame.fill",
                            title: "Calories Burned",
                            description: "Automatic calorie burn calculations",
                            color: .red
                        )
                        
                        HealthBenefitCard(
                            icon: "chart.bar.fill",
                            title: "Net Calories",
                            description: "Complete picture: eaten - burned",
                            color: .blue
                        )
                        
                        HealthBenefitCard(
                            icon: "figure.walk",
                            title: "Activity Data",
                            description: "Steps, distance, and active energy",
                            color: .green
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Connection status or button
                    VStack(spacing: 16) {
                        if healthKitService.isAuthorized {
                            // Connected state
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    
                                    Text("Connected to Apple Health")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                                
                                Text("You can manage permissions in Settings anytime")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Not connected state
                            VStack(spacing: 12) {
                                Button(action: connectToHealthKit) {
                                    HStack {
                                        if isConnecting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "heart.fill")
                                        }
                                        Text(isConnecting ? "Connecting..." : "Connect Apple Health")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.red, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                                }
                                .disabled(isConnecting)
                                
                                Button(action: {}) {
                                    Text("Skip for now")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Privacy note
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.secondary)
                            Text("Your Privacy")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("All health data stays on your device. We never share your workout information.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .alert("Connection Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Check if already authorized
            if HealthKitService.isHealthDataAvailable {
                healthKitService.requestAuthorization { _, _ in }
            }
        }
    }
    
    private func connectToHealthKit() {
        guard HealthKitService.isHealthDataAvailable else {
            errorMessage = "Apple Health is not available on this device."
            showingError = true
            return
        }
        
        isConnecting = true
        
        healthKitService.requestAuthorization { success, error in
            isConnecting = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            } else if success {
                // Successfully connected
                print("✅ Apple Health connected during onboarding")
            }
        }
    }
}

struct HealthBenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AppleHealthStepView()
}
