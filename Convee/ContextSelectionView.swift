//
//  ContextSelectionView.swift
//  Convee
//
//  Created by Marco Carandente on 18.8.2024.
//

import Foundation
import SwiftUI
struct ContextSelectionView: View {
    @Binding var selectedContext: Context
    @Binding var targetLanguage: String
    @Binding var startingLanguage: String
    @Binding var isLanguageConfirmed: Bool
    
    var body: some View {
        VStack {
            // Header showing chosen languages
            HStack {
                Spacer()
                Text("\(startingLanguage)")
                Image(systemName: "arrow.right")
                Text("\(targetLanguage)")
                
                Spacer()
                Button(action: {
                    isLanguageConfirmed = false // Unconfirm the language
                    clearLanguages() // Optionally clear the saved languages
                }) {
                    Text("Change")
                        .foregroundColor(.red)
                }
                Spacer()
            }
            
            List(contexts) { context in
                Button(action: {
                    selectedContext = context
                }) {
                    Text(context.description)
                        .padding()
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    private func clearLanguages() {
        UserDefaults.standard.removeObject(forKey: "TargetLanguage")
        UserDefaults.standard.removeObject(forKey: "StartingLanguage")
    }
}
