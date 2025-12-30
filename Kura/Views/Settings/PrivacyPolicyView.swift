//
//  PrivacyPolicyView.swift
//  Kura
//
//  Privacy policy and data handling information
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last updated: \(formattedDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    // Privacy sections
                    PrivacySection(
                        title: "Your Data, Your Control",
                        icon: "lock.shield.fill",
                        color: .green
                    ) {
                        Text("Kura stores all your health data locally on your device. We never collect, transmit, or sell your personal information to third parties.")
                    }
                    
                    PrivacySection(
                        title: "What We Collect",
                        icon: "list.bullet.clipboard.fill",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Fasting sessions and progress")
                            BulletPoint(text: "Meal logs and food entries")
                            BulletPoint(text: "Water intake records")
                            BulletPoint(text: "Personal health metrics (height, weight, goals)")
                            BulletPoint(text: "Achievement and streak data")
                        }
                    }
                    
                    PrivacySection(
                        title: "How We Use Your Data",
                        icon: "gearshape.fill",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint(text: "Track your health and wellness progress")
                            BulletPoint(text: "Calculate personalized nutrition goals")
                            BulletPoint(text: "Generate insights and statistics")
                            BulletPoint(text: "Provide achievement notifications")
                        }
                    }
                    
                    PrivacySection(
                        title: "AI Food Recognition",
                        icon: "brain.head.profile",
                        color: .purple
                    ) {
                        Text("When using AI food recognition, images are sent to OpenAI's GPT-4o service for analysis. OpenAI processes the image according to their privacy policy. Images are not stored permanently.")
                    }
                    
                    PrivacySection(
                        title: "Third-Party Services",
                        icon: "network",
                        color: .cyan
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kura uses the following third-party services:")
                                .fontWeight(.medium)
                            BulletPoint(text: "OpenAI GPT-4o for food image recognition")
                            BulletPoint(text: "CloudKit for optional iCloud backup")
                            
                            Text("These services have their own privacy policies. We encourage you to review them.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    
                    PrivacySection(
                        title: "Data Deletion",
                        icon: "trash.fill",
                        color: .red
                    ) {
                        Text("You can delete all your data at any time by removing the app. All locally stored data will be permanently deleted. If you use iCloud backup, you can manage that data in your iCloud settings.")
                    }
                    
                    PrivacySection(
                        title: "Contact Us",
                        icon: "envelope.fill",
                        color: .teal
                    ) {
                        Text("If you have questions about this privacy policy or how your data is handled, please contact us at:\n\nsupport@kuraapp.com")
                    }
                    
                    // Footer
                    VStack(spacing: 12) {
                        Divider()
                        
                        Text("By using Kura, you agree to this privacy policy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("We are committed to protecting your privacy and maintaining transparency about how your data is used.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct PrivacySection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
}

#Preview {
    PrivacyPolicyView()
}
