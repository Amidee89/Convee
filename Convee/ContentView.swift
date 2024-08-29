//
//  ContentView.swift
//  Convee
//
//  Created by Marco Carandente on 17.8.2024.
//

import SwiftUI

struct ContentView: View {
    @State private var targetLanguage: String = ""
    @State private var startingLanguage: String = ""
    @State private var isLanguageConfirmed: Bool = false
    @State private var selectedContext: Context = Context(description: "", partnerPortrait: nil, startingMessage: "")
    

    var body: some View {
        Group{
            if !isLanguageConfirmed {
                LanguageInputView(targetLanguage: $targetLanguage, startingLanguage: $startingLanguage, isConfirmed: $isLanguageConfirmed)
            } else {
                if selectedContext.description == "" {
                    ContextSelectionView(selectedContext: $selectedContext, targetLanguage: $targetLanguage, startingLanguage: $startingLanguage, isLanguageConfirmed: $isLanguageConfirmed)
                } else {
                    ChatView(context: $selectedContext, targetLanguage: $targetLanguage, startingLanguage: $startingLanguage)
                }
            }
        }.onAppear(perform: loadLanguages)
    }

    
    private func loadLanguages() {
        if let savedTargetLanguage = UserDefaults.standard.string(forKey: "TargetLanguage"),
           let savedStartingLanguage = UserDefaults.standard.string(forKey: "StartingLanguage") {
            targetLanguage = savedTargetLanguage
            startingLanguage = savedStartingLanguage
            isLanguageConfirmed = true
        }
    }
}

#Preview {
    ContentView()
}
