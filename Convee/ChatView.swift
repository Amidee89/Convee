import SwiftUI

struct ChatView: View {
    @Binding var context: Context
    @Binding var targetLanguage: String
    @Binding var startingLanguage: String

    @State var messages: [ChatMessage] = []
    @State var chatGPTmessages: [[String: String]] = []
    @State var newMessage: String = ""
    @State private var showTranslationOverlay: Bool = false
    @State private var currentTranslation: String = ""



    var body: some View {
        VStack {
            // Context at the top
            Text(context.description)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading) // Align context to the leading edge

            // Chat messages in a scrollable view with auto-scroll to bottom
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing) {
                                    if let userMessage = message.userMessage, !userMessage.isEmpty {
                                        Text(userMessage)
                                            .padding()
                                            .background(Color.blue.opacity(0.3))
                                            .cornerRadius(10)
                                            .frame(maxWidth: 300, alignment: .trailing)
                                            .foregroundColor(.primary)
                                    }
                                    if let correctedUserMessage = message.correctedUserMessage, !correctedUserMessage.isEmpty {
                                        HStack {
                                            ForEach(correctedUserMessage.indices, id: \.self) { index in
                                                Text(correctedUserMessage[index])
                                                    .foregroundColor(.green)
                                                    .onTapGesture {
                                                        currentTranslation = message.correctedUserMessageTranslation?[index] ?? ""
                                                        showTranslationOverlay.toggle()
                                                    }
                                                    .lineLimit(nil) // Allows multiline text
                                                    .frame(maxWidth: .infinity, alignment: .leading) // Sets max width and aligns to the leading edge
                                            }
                                        }
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(5)
                                        .frame(maxWidth: 300, alignment: .leading) // Sets the container to a max width with leading alignment
                                    }
                                }
                                .padding(.vertical)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    if let reply = message.displayReply, !reply.isEmpty {
                                        Text(reply)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                            .frame(maxWidth: 300, alignment: .leading)
                                            .foregroundColor(.primary)
                                    }
                                    if let replyTranslation = message.displayReplyTranslation, !replyTranslation.isEmpty {
                                        Text(replyTranslation)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical)
                                Spacer()
                            }
                            .id(message.id) // Set the ID to the message
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messages) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }

            // Input area with send button at the bottom
            HStack {
                TextEditor(text: $newMessage)
                    .frame(minHeight: 40, maxHeight: 100)
                    .padding(5)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                    .padding(.horizontal)

                Button(action: sendMessage) {
                    Text("Send")
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.trailing)
            }
            .padding(.bottom)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear(perform: { initializeChat() })
        .overlay(
            VStack {
                if showTranslationOverlay {
                    VStack {
                        Text(currentTranslation)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 10)
                            .onTapGesture {
                                showTranslationOverlay = false
                            }
                            .padding(20)
                    }
                    .padding()
                    .cornerRadius(10)
                }
            }
            .alignmentGuide(.top) { d in
                d[.top] + 50
            }
            .padding(.top, 50),
            alignment: .center
        )
    }

    func initializeChat() {
        let initialPrompt = createInitialPrompt(targetLanguage: targetLanguage, context: context, startingLanguage: startingLanguage)
        
        chatGPTmessages.append(["role": "system", "content": initialPrompt])
        
        var newChatMessage = ChatMessage(userMessage: nil, correctedUserMessage: nil, correctedUserMessageTranslation: nil, reply: nil, replyTranslation: nil)
        messages.append(newChatMessage)
        
        translateInitialMessage(context: context, targetLanguage: targetLanguage, startingLanguage: startingLanguage) { result in
            switch result {
            case .success(let translationArray):
                newChatMessage.reply = translationArray
                chatGPTmessages.append(["role": "assistant", "content": newChatMessage.displayReply ?? ""])
                
                self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                
                // Now proceed to translate the reply
                translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: translationArray) { result in
                    switch result {
                    case .success(let translationArray):
                        newChatMessage.replyTranslation = translationArray
                    case .failure(let error):
                        print("Error occurred while translating array: \(error.localizedDescription)")
                    }
                    
                    // Final update after translating
                    self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                }
                
            case .failure(let error):
                print("Error occurred: \(error.localizedDescription)")
            }
        }
    }

    
    func sendMessage() {
        guard !newMessage.isEmpty else { return }

        var newChatMessage = ChatMessage(userMessage: newMessage, correctedUserMessage: nil, correctedUserMessageTranslation: nil, reply: nil, replyTranslation: nil)
        messages.append(newChatMessage)
        chatGPTmessages.append(["role": "user", "content": newMessage])
        newMessage = ""

        // Step 1: Make ChatGPT request
        makeChatGPTRequest(with: chatGPTmessages) { result in
            switch result {
            case .success(let json):
                guard let corrected = json["corrected"] as? [String],
                      let reply = json["reply"] as? [String] else {
                    print("Error parsing response")
                    return
                }
                
                // Update chat message with corrected message and reply
                newChatMessage.reply = reply
                newChatMessage.correctedUserMessage = corrected
                self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                
                // Step 2: Translate corrected user message
                if let correctedMessage = newChatMessage.correctedUserMessage {
                    translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: correctedMessage) { result in
                        switch result {
                        case .success(let translatedArray):
                            newChatMessage.correctedUserMessageTranslation = translatedArray
                            self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                        case .failure(let error):
                            print("Failed to translate corrected message array: \(error.localizedDescription)")
                        }
                        
                        // Step 3: Translate the reply
                        if let replyChatMessage = newChatMessage.reply {
                            translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: replyChatMessage) { result in
                                switch result {
                                case .success(let translatedArray):
                                    newChatMessage.replyTranslation = translatedArray
                                    self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                                case .failure(let error):
                                    print("Failed to translate reply message array: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("Failed to get a response from ChatGPT: \(error)")
            }
        }
    }

    func updateOrAppendChatMessage (chatMessage: ChatMessage){
        if let lastIndex = messages.lastIndex(where: { $0.id == chatMessage.id }) {
            messages[lastIndex] = chatMessage
        } else {
            messages.append(chatMessage)
        }
    }

}



#Preview {
    let sampleMessages = [
        ChatMessage(
            userMessage: "Hello, I'd like to order a drink.",
            correctedUserMessage:["Hei,", "haluaisin", "tilata", "juoman."],
            correctedUserMessageTranslation: ["Hello,", "I would like", "to order", "a drink."],
            reply: ["Totta,", "mitä", "haluaisit", "ottaa?"],
            replyTranslation: ["Sure,", "what", "would you like", "to have?"]
        ),
        ChatMessage(
            userMessage: "What options do you have?",
            correctedUserMessage: ["Mitä", "vaihtoehtoja", "sinulla", "on?"],
            correctedUserMessageTranslation: ["What", "options", "you have", "are?"],
            reply:  ["Meillä", "on", "olutta,", "viiniä", "ja", "cocktaileja."],
            replyTranslation:["We have", "beer,", "wine,", "and", "cocktails."]
        )
    ]
    
    return ChatView(
        context: .constant(Context(
            description: "You are at a bar, and you approach the counter to order something to drink.",
            partnerPortrait: Image(systemName: "person.fill"),
            startingMessage: "Hello, what do you want to order?"
        )),
        targetLanguage: .constant("Finnish"),
        startingLanguage: .constant("English"),
        messages: sampleMessages // Pass the sample messages here
    )
}
