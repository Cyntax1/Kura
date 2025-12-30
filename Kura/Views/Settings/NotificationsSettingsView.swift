//
//  NotificationsSettingsView.swift
//  Kura
//
//  Notification preferences and settings
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fastingReminders") private var fastingReminders = true
    @AppStorage("mealReminders") private var mealReminders = true
    @AppStorage("waterReminders") private var waterReminders = true
    @AppStorage("achievementNotifications") private var achievementNotifications = true
    @AppStorage("dailySummary") private var dailySummary = false
    
    @State private var notificationsEnabled = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if !notificationsEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.orange)
                                Text("Notifications Disabled")
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Enable notifications in Settings to receive reminders and updates.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Permission")
                }
                
                Section {
                    Toggle(isOn: $fastingReminders) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fasting Reminders")
                                .fontWeight(.medium)
                            Text("Notifications for fasting milestones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notificationsEnabled)
                    
                    Toggle(isOn: $mealReminders) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meal Logging")
                                .fontWeight(.medium)
                            Text("Reminders to log your meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notificationsEnabled)
                    
                    Toggle(isOn: $waterReminders) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Water Intake")
                                .fontWeight(.medium)
                            Text("Hourly water drinking reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notificationsEnabled)
                } header: {
                    Text("Reminders")
                }
                
                Section {
                    Toggle(isOn: $achievementNotifications) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Achievements")
                                .fontWeight(.medium)
                            Text("Celebrate when you unlock achievements")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notificationsEnabled)
                    
                    Toggle(isOn: $dailySummary) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Summary")
                                .fontWeight(.medium)
                            Text("Evening recap of your progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notificationsEnabled)
                } header: {
                    Text("Updates")
                }
                
                Section {
                    Text("We respect your privacy. Notifications are sent locally from your device and are never shared.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}

#Preview {
    NotificationsSettingsView()
}
