//
//  LanguageSelectionView.swift
//  Convee
//
//  Created by Marco Carandente on 18.8.2024.
//

import Foundation
import SwiftUI

struct LanguageInputView: View {
    @Binding var targetLanguage: String
    @Binding var startingLanguage: String
    @Binding var isConfirmed: Bool
    
    var body: some View {
        VStack {
            TextField("Enter the language you are learning", text: $targetLanguage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Enter your starting language", text: $startingLanguage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Confirm") {
                saveLanguages() // Save to UserDefaults
                isConfirmed = true
            }
            .padding()
            .disabled(targetLanguage.isEmpty || startingLanguage.isEmpty)
        }
        .padding()
    }
    
    private func saveLanguages() {
        UserDefaults.standard.set(targetLanguage, forKey: "TargetLanguage")
        UserDefaults.standard.set(startingLanguage, forKey: "StartingLanguage")
    }
}
