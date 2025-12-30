//
//  KeyboardDismissal.swift
//  Kura
//
//  Created by Rishith Chennupati on 9/26/25.
//

import SwiftUI

// MARK: - Keyboard Dismissal Extension

extension View {
    /// Adds tap gesture to dismiss keyboard when tapping outside text fields
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Adds toolbar with Done button for number pad keyboards
    func numberPadToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Custom TextField with Keyboard Dismissal

struct DismissibleTextField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let placeholder: String
    
    init(_ title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, placeholder: String = "") {
        self.title = title
        self._text = text
        self.keyboardType = keyboardType
        self.placeholder = placeholder.isEmpty ? title : placeholder
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(keyboardType)
            .numberPadToolbar()
    }
}

struct DismissibleNumberField: View {
    let title: String
    @Binding var value: Int
    let placeholder: String
    
    init(_ title: String, value: Binding<Int>, placeholder: String = "") {
        self.title = title
        self._value = value
        self.placeholder = placeholder.isEmpty ? title : placeholder
    }
    
    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .numberPadToolbar()
    }
}

struct DismissibleDecimalField: View {
    let title: String
    @Binding var value: Double
    let placeholder: String
    
    init(_ title: String, value: Binding<Double>, placeholder: String = "") {
        self.title = title
        self._value = value
        self.placeholder = placeholder.isEmpty ? title : placeholder
    }
    
    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .numberPadToolbar()
    }
}
