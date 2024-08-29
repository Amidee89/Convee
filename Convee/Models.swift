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
    let userMessage: String?
    var correctedUserMessage: [String]?
    var correctedUserMessageTranslation: [String]?
    var reply: [String]?
    var replyTranslation: [String]?
    
    // Combine arrays into strings for display
    
    var displayCorrectedUserMessage: String? {
        correctedUserMessage?.joined(separator: " ") ?? ""
    }
    
    var displayCorrectedUserMessageTranslation: String? {
        correctedUserMessageTranslation?.joined(separator: " ") ?? ""
    }
    
    var displayReply: String? {
        reply?.joined(separator: " ") ?? ""
    }
    
    var displayReplyTranslation: String? {
        replyTranslation?.joined(separator: " ") ?? ""
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
