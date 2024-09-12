//
//  Prompts.swift
//  Convee
//
//  Created by Marco Carandente on 27.8.2024.
//

import Foundation

func createInitialPrompt(targetLanguage: String, context: Context, startingLanguage: String) -> String {
    let initialPrompt = """
    You are a \(targetLanguage) language coach doing roleplay with me. The context is: \(context.description). I will try to talk to you in \(targetLanguage) and you will be replying in \(targetLanguage). I will put words that I don’t know in \(startingLanguage) in my part of the roleplay. You will answer with a JSON containing a dictionary of arrays. The dictionary is formed as such:
    "split": (list) my message, in a list split word by word
    “corrected”: (list) my message, corrected by you retaining the meaning but fixing mistakes or translating missing words, in a list word by word
    “reply”: (list) your response to the message, in \(targetLanguage), in a list word by word
    Continue the conversation given the context and keep it short and natural, one to two sentences maximum using spoken language style adequate for the setting. Always make sure your reply will always require an answer from the user, except when the user clearly shows interest to close the conversation. Do not stray at all from the context. Do not answer questions that do not fit the language coaching context. If you feel the reply is not in roleplay and makes no sense in the context, the json shall contain just {“error”:“conversation strayed from context”}
    """
    return initialPrompt
}


func createTranslateArrayFromEnglishSystemPrompt(targetLanguage: String) -> String {
    let translateSystemPrompt =
    """
    You are a helpful assistant, ready to make accurate translations from English to \(targetLanguage). You will answer with a JSON containing a list containing the translation of the message you're given in \(targetLanguage), word by word.
    """
    return translateSystemPrompt
}

func createTranslateInitalMessageFromEnglishPrompt (targetLanguage: String, context: Context) -> String {
    let translateInitalMessagePrompt = """
Translate this sentence: "\(context.startingMessage)" in \(targetLanguage). This is the first sentence in a conversation in this context: \(context.description)."
"""
    return translateInitalMessagePrompt
}

func createTranslateArraySystemPrompt (targetLanguage: String, startingLanguage: String) -> String {
    let translateWordArraySystemPrompt = """
    You are a helpful assistant, ready to make accurate translations from \(targetLanguage) to \(startingLanguage). You will answer with a JSON containing a dictionary containing the translation of the each of the words you're given in \(targetLanguage). Be super careful to give a translation for each of the words. Keep the translation accurate to the context of the sentence, that is being the list of words you're given when read in order. So for every word, you give out "\(targetLanguage) word":"\(startingLanguage) translation", keeping the translation meaningful in the context of the sentence you're given as a list of words.
    """
       return translateWordArraySystemPrompt
}

func createTranslateArrayPrompt (translationArray: [String]) -> String {
        let translateWordArrayPrompt =
            """
            Translate this sentence given as a list of words: \(translationArray)
            """
        return translateWordArrayPrompt
    }

func translateInitialMessage(context: Context, targetLanguage: String, startingLanguage: String, completion: @escaping (Result<[String], Error>) -> Void) {
    let translateInitialMessageSystemPrompt = createTranslateArrayFromEnglishSystemPrompt(targetLanguage: targetLanguage)
    let translateInitialMessagePrompt = createTranslateInitalMessageFromEnglishPrompt(targetLanguage: targetLanguage, context: context)
    
    var translateMessages = [["role": "system", "content": translateInitialMessageSystemPrompt]]
    translateMessages.append(["role": "user", "content": translateInitialMessagePrompt])
    
    makeChatGPTRequest(with: translateMessages) { result in
        switch result {
        case .success(let json):
            if let translationArray = json["translation"] as? [String] {
                completion(.success(translationArray))
            } else {
                let error = NSError(domain: "TranslationErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to extract array from response"])
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}


func translateArray(targetLanguage: String , startingLanguage: String, array: [String], completion: @escaping (Result<[String: String], Error>) -> Void) {
    let translateTranslateArraySystemPrompt = createTranslateArraySystemPrompt(targetLanguage: targetLanguage, startingLanguage: startingLanguage)
    let translateTranslateArrayPrompt = createTranslateArrayPrompt(translationArray: array)
    
    var translateMessages = [["role": "system", "content": translateTranslateArraySystemPrompt]]
    translateMessages.append(["role": "user", "content": translateTranslateArrayPrompt])
    
    makeChatGPTRequest(with: translateMessages) { result in
        switch result {
        case .success(let json):
            if let translationDict = json as? [String: String] {
                completion(.success(translationDict))
            } else {
                let error = NSError(domain: "TranslationErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to extract dictionary from response"])
                completion(.failure(error))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}



func makeChatGPTRequest(with messages: [[String: String]], completion: @escaping (Result<[String: Any], ChatGPTError>) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion(.failure(.invalidURL))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(k.k)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let parameters: [String: Any] = [
        "model": "gpt-4o",
        "messages": messages,
        "temperature": 0.1,
        "response_format": ["type": "json_object"]
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    } catch {
        completion(.failure(.jsonSerializationFailed(error.localizedDescription)))
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(.requestFailed(error.localizedDescription)))
            return
        }

        guard let data = data else {
            completion(.failure(.noDataReceived))
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let errorMessage = json["error"] as? [String: Any], let errorContent = errorMessage["content"] as? String {
                    completion(.failure(.apiError(errorContent)))
                    return
                }

                if let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let contentData = content.data(using: .utf8),
                   let finalJSON = try JSONSerialization.jsonObject(with: contentData, options: []) as? [String: Any] {
                    completion(.success(finalJSON))
                } else {
                    completion(.failure(.invalidJSONStructure))
                }
            } else {
                completion(.failure(.invalidJSONStructure))
            }
        } catch {
            completion(.failure(.jsonSerializationFailed(error.localizedDescription)))
        }
    }

    task.resume()
}
