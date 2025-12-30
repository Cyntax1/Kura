//
//  EditProfileView.swift
//  Kura
//
//  Created by Aaditya Shah on 8/6/25.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let userProfile: UserProfile?
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var targetWeight: String = ""
    @State private var selectedGender: Gender?
    @State private var selectedActivityLevel: ActivityLevel = .moderate
    @State private var dailyCalorieGoal: String = ""
    @State private var dailyWaterGoal: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Edit Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Update your personal information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ProfileField(title: "Name", value: $name, placeholder: "Enter your name")
                            
                            ProfileField(title: "Age", value: $age, placeholder: "Enter your age", keyboardType: .numberPad)
                            
                            // Gender Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 12) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Button(action: { selectedGender = gender }) {
                                            Text(gender.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedGender == gender ? .white : .blue)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedGender == gender ? Color.blue : Color.blue.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Physical Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Physical Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ProfileField(title: "Height (cm)", value: $height, placeholder: "Enter height in cm", keyboardType: .decimalPad)
                            
                            ProfileField(title: "Current Weight (kg)", value: $weight, placeholder: "Enter current weight", keyboardType: .decimalPad)
                            
                            ProfileField(title: "Target Weight (kg)", value: $targetWeight, placeholder: "Enter target weight (optional)", keyboardType: .decimalPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Activity Level
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity Level")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Button(action: { selectedActivityLevel = level }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(level.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text(level.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedActivityLevel == level ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedActivityLevel == level ? .blue : .gray)
                                    }
                                    .padding()
                                    .background(selectedActivityLevel == level ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Goals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Goals")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ProfileField(title: "Calorie Goal", value: $dailyCalorieGoal, placeholder: "2000", keyboardType: .numberPad)
                            
                            ProfileField(title: "Water Goal (L)", value: $dailyWaterGoal, placeholder: "2.0", keyboardType: .decimalPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save Profile")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .numberPadToolbar()
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func loadCurrentProfile() {
        guard let profile = userProfile else { return }
        
        name = profile.name
        age = profile.age != nil ? String(profile.age!) : ""
        height = profile.height != nil ? String(profile.height!) : ""
        weight = profile.weight != nil ? String(profile.weight!) : ""
        targetWeight = profile.targetWeight != nil ? String(profile.targetWeight!) : ""
        selectedGender = profile.gender
        selectedActivityLevel = profile.activityLevel
        dailyCalorieGoal = String(profile.dailyCalorieGoal)
        dailyWaterGoal = String(profile.dailyWaterGoal)
    }
    
    private func saveProfile() {
        if let profile = userProfile {
            // Update existing profile
            profile.name = name
            profile.age = !age.isEmpty ? Int(age) : nil
            profile.height = !height.isEmpty ? Double(height) : nil
            profile.weight = !weight.isEmpty ? Double(weight) : nil
            profile.targetWeight = !targetWeight.isEmpty ? Double(targetWeight) : nil
            profile.gender = selectedGender
            profile.activityLevel = selectedActivityLevel
            profile.dailyCalorieGoal = Int(dailyCalorieGoal) ?? 2000
            profile.dailyWaterGoal = Double(dailyWaterGoal) ?? 2.0
            profile.updatedAt = Date()
        } else {
            // Create new profile
            let newProfile = UserProfile(
                name: name,
                age: !age.isEmpty ? Int(age) : nil,
                height: !height.isEmpty ? Double(height) : nil,
                weight: !weight.isEmpty ? Double(weight) : nil,
                targetWeight: !targetWeight.isEmpty ? Double(targetWeight) : nil,
                activityLevel: selectedActivityLevel,
                gender: selectedGender,
                dailyCalorieGoal: Int(dailyCalorieGoal) ?? 2000,
                dailyWaterGoal: Double(dailyWaterGoal) ?? 2.0
            )
            modelContext.insert(newProfile)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

struct ProfileField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
}

#Preview {
    EditProfileView(userProfile: nil)
        .modelContainer(for: [UserProfile.self])
}
