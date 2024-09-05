//
//  Models.swift
//  Convee
//
//  Created by Marco Carandente on 19.8.2024.
//

import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    var userMessage: String?
    var correctedUserMessage: [String]?
    var correctedUserMessageTranslation: [String: String]? // Dictionary for word-by-word translation
    var reply: [String]?
    var replyTranslation: [String: String]? // Dictionary for word-by-word translation
    
    // Combine arrays into strings for display
    
    var displayCorrectedUserMessage: String? {
        correctedUserMessage?.joined(separator: " ") ?? ""
    }

    // This method now uses the dictionary to map each word to its translation
    var displayCorrectedUserMessageTranslation: String? {
        correctedUserMessage?.compactMap { word in
            correctedUserMessageTranslation?[word] // Get the translation for each word
        }.joined(separator: " ") ?? ""
    }

    var displayReply: String? {
        reply?.joined(separator: " ") ?? ""
    }

    // Similar logic for displaying the reply translations
    var displayReplyTranslation: String? {
        reply?.compactMap { word in
            replyTranslation?[word] // Get the translation for each word
        }.joined(separator: " ") ?? ""
    }
}


struct ChatGPTResponse {
    let correctedMessage: [String]
    let correctedTranslation: [String]
    let reply: [String]
    let correctedReply: [String]
}

struct Context: Identifiable {
    let id = UUID()
    let description: String
    let partnerPortrait: Image?
    let startingMessage: String
}

enum ChatGPTError: Error {
    case invalidURL
    case requestFailed(String)
    case invalidResponseFormat
    case noDataReceived
    case jsonSerializationFailed(String)
    case invalidJSONStructure
    case apiError(String)
}
