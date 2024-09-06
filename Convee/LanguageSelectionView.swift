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
            // Title for Target Language
            Text("Which language are you learning?")
                .font(.headline)
                .padding(.top)
            
            // TextField for Target Language
            TextField("Enter the language you are learning", text: $targetLanguage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            // Title for Starting Language
            Text("Which language are you are fluent in?")
                .font(.headline)
                .padding(.top)

            // TextField for Starting Language
            TextField("Enter your starting language", text: $startingLanguage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
            
            // Confirm Button
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
