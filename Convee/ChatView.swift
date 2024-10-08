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
    @State private var currentWordTranslated: String = ""
    @State private var showErrorOverlay: Bool = false
    @State private var errorMessage: String = ""


    var body: some View {
         VStack {
             HStack {
      

                 Button(action: {
                     // Reset messages and reset the chosen context
                     backToContextSelection()
                 }) {
                     Text("Back")
                         .padding(.vertical, 8) // Reduced padding
                         .padding(.horizontal, 16) // Horizontal padding for a wider button
                         .foregroundColor(.red)
                         .cornerRadius(8)
                 }
                 
                 Spacer()
                 
                 Button(action: {
                     // Reset messages and restart the chat
                     restartChat()
                 }) {
                     Text("Restart")
                         .padding(.vertical, 8) // Reduced padding
                         .padding(.horizontal, 16) // Horizontal padding for a wider button
                         .cornerRadius(8)
                 }

             }
             .padding(.horizontal)
             
             Divider() // Line between buttons and context

             // Context at the top
             Text(context.description)
                 .padding()
                 .frame(maxWidth: .infinity, alignment: .leading) 
                 .textSelection(.enabled)
             Divider()
             if showErrorOverlay {
                     HStack {
                         Spacer()
                         Text("Error: \(errorMessage)")
                             .padding()
                             .cornerRadius(8)
                             .foregroundColor(.red)
                             .textSelection(.enabled)
                         Spacer()
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.horizontal)
                     .background(Color.red.opacity(0.3))
                 }
            else if !currentTranslation.isEmpty {
                 HStack {
                     Spacer()
                     Text("\(currentWordTranslated) → \(currentTranslation)")
                         .padding()
                         .cornerRadius(8)
                         .textSelection(.enabled)
                     Spacer()
                 }
                 .frame(maxWidth: .infinity)
                 .padding(.horizontal)
                 .background(Color.yellow.opacity(0.3))
             }

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
                                             .frame(maxWidth: 350, alignment: .trailing)
                                             .foregroundColor(.primary)
                                             .textSelection(.enabled)

                                     }
                                     if let correctedUserMessage = message.correctedUserMessage, !correctedUserMessage.isEmpty {
                                         let originalWords = message.splitUserMessage ?? message.userMessage?.components(separatedBy: " ") ?? []

                                         WordWrappingView(words: correctedUserMessage, originalWords: originalWords, maxWidth: 250, onWordTap: { wordIndex in
                                             // Get the word at the tapped index
                                             let tappedWord = correctedUserMessage[wordIndex]
                                             
                                             // Display the translation of the tapped word
                                             if let translationDictionary = message.correctedUserMessageTranslation {
                                                 currentWordTranslated = tappedWord
                                                 currentTranslation = translationDictionary[tappedWord] ?? "No translation available"
                                             }
                                         })
                                         .background(Color.green.opacity(0.1))
                                         .cornerRadius(5)
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
                                             .textSelection(.enabled)

                                     }
                                     if let replyTranslation = message.displayReplyTranslation, !replyTranslation.isEmpty {
                                         Text(replyTranslation)
                                             .font(.footnote)
                                             .foregroundColor(.secondary)
                                             .textSelection(.enabled)

                                     }
                                 }
                                 .padding(.vertical)
                                 Spacer()
                             }
                             .id(message.id)
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
                
                translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: translationArray) { result in
                    switch result {
                    case .success(let translationArray):
                        newChatMessage.replyTranslation = translationArray
                    case .failure(let error):
                        print("Error occurred while translating array: \(error.localizedDescription)")
                        showErrorMessage("Translation error")

                    }
                    
                    self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                }
                
            case .failure(let error):
                print("Error occurred: \(error.localizedDescription)")
                showErrorMessage("Conversation start response was not valid")
            }
        }
    }

    
    func sendMessage() {
        guard !newMessage.isEmpty else { return }

        var newChatMessage = ChatMessage(userMessage: newMessage, correctedUserMessage: nil, correctedUserMessageTranslation: nil, reply: nil, replyTranslation: nil)
        messages.append(newChatMessage)
        let sentMessage = newMessage  // Save the current message content
        self.chatGPTmessages.append(["role": "user", "content": newMessage])
        newMessage = ""

        // Step 1: Make ChatGPT request
        makeChatGPTRequest(with: chatGPTmessages) { result in
            switch result {
            case .success(let json):
                guard let corrected = json["corrected"] as? [String],
                      let reply = json["reply"] as? [String] else {
                    print("Error parsing response")
                    showErrorMessage("Response was not valid")
                    restoreMessageInput(sentMessage)
                    chatGPTmessages.removeLast()
                    return
                }
                
                newChatMessage.reply = reply
                newChatMessage.correctedUserMessage = corrected
                if let splitMessage = json["split"] as? [String]{
                    newChatMessage.splitUserMessage = splitMessage
                }
                chatGPTmessages.append(["role": "assistant", "content": newChatMessage.displayReply ?? ""])
                self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                
                if let correctedMessage = newChatMessage.correctedUserMessage {
                    translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: correctedMessage) { result in
                        switch result {
                        case .success(let translatedArray):
                            newChatMessage.correctedUserMessageTranslation = translatedArray
                            self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                        case .failure(let error):
                            print("Failed to translate corrected message array: \(error.localizedDescription)")
                            showErrorMessage("\(error.localizedDescription)")
                            restoreMessageInput(sentMessage)
                            chatGPTmessages.removeLast(2)
                        }
                        
                        if let replyChatMessage = newChatMessage.reply {
                            translateArray(targetLanguage: self.targetLanguage, startingLanguage: self.startingLanguage, array: replyChatMessage) { result in
                                switch result {
                                case .success(let translatedArray):
                                    newChatMessage.replyTranslation = translatedArray
                                    self.updateOrAppendChatMessage(chatMessage: newChatMessage)
                                case .failure(let error):
                                    print("Failed to translate reply message array: \(error.localizedDescription)")
                                    showErrorMessage("\(error.localizedDescription)")
                                    restoreMessageInput(sentMessage)
                                    chatGPTmessages.removeLast(2)
                                }
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("Failed to get a response from ChatGPT: \(error)")
                showErrorMessage("\(error.localizedDescription)")
                restoreMessageInput(sentMessage)
                chatGPTmessages.removeLast(2)
            }
            resetErrorMessage()
        }
    }

    func updateOrAppendChatMessage (chatMessage: ChatMessage){
        if let lastIndex = messages.lastIndex(where: { $0.id == chatMessage.id }) {
            messages[lastIndex] = chatMessage
        } else {
            messages.append(chatMessage)
        }
    }
    func restartChat() {
         messages.removeAll()
         chatGPTmessages.removeAll()
         initializeChat()
     }

     func backToContextSelection() {
         messages.removeAll()
         chatGPTmessages.removeAll()
         context = Context(description: "", partnerPortrait: nil, startingMessage: "")
     }
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showErrorOverlay = true
    }
    func resetErrorMessage () {
        showErrorOverlay = false
    }
    
    func restoreMessageInput(_ message: String) {
        newMessage = message  // Restore the original message content
        messages.removeLast()
    }
}



#Preview {
    let sampleMessages = [
        ChatMessage(
            userMessage: "Hello, I'd like to order a drink.",
            splitUserMessage: ["Hello,", "I'd", "like", "to", "order", "a", "drink."],
            correctedUserMessage:["Hei,", "haluaisin", "tilata", "juoman."],
            correctedUserMessageTranslation: ["Hei,":"Hello,", "haluaisin":"I would like","tilata":"to order", "juoman.":"a drink."],
            reply: ["Totta,", "mitä", "haluaisit", "ottaa?"],
            replyTranslation: ["Totta,":"Sure,","mitä": "what", "haluaisit":"would you like", "ottaa?":"to have?"]
        ),
        ChatMessage(
            userMessage: "What options do you have?",
            correctedUserMessage: ["Mitä", "vaihtoehtoja", "sinulla", "on?"],
            correctedUserMessageTranslation: ["Mitä":"What", "vaihtoehtoja":"options", "sinulla":"you have", "on?":"are?"],
            reply:  ["Meillä", "on", "olutta,", "viiniä", "ja", "cocktaileja."],
            replyTranslation:["Meillä":"We have", "on":"beer,", "viiniä":"wine,", "ja":"and", "cocktaileja.":"cocktails."]
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
        messages: sampleMessages 
    )
}
