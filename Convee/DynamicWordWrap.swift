import SwiftUI

struct WordWrappingView: View {
    let words: [String]
    let originalWords: [String]
    let maxWidth: CGFloat
    var onWordTap: ((Int) -> Void)?
    @State private var touchedWordIndex: Int? = nil

    var body: some View {
          VStack(alignment: .leading, spacing: 10) {
              ForEach(Array(rows.enumerated()), id: \.0) { rowIndex, row in
                  HStack(spacing: 5) {
                      ForEach(Array(row.enumerated()), id: \.0) { wordIndex, word in
                          Text(word)
                              .padding(5)
                              .background(cleanedOriginalWords.contains(cleanedWord(word)) ? Color.blue.opacity(0.2) : Color.red.opacity(0.2))
                              .cornerRadius(5)
                              .onTapGesture {
                                  let index = rows[0..<rowIndex].flatMap { $0 }.count + wordIndex
                                  onWordTap?(index)
                              }
                              .textSelection(.enabled)
                              .gesture(
                                  DragGesture(minimumDistance: 0)
                                      .onChanged { _ in
                                          let index = rows[0..<rowIndex].flatMap { $0 }.count + wordIndex
                                          if touchedWordIndex != index {
                                              touchedWordIndex = index
                                              onWordTap?(index)
                                          }
                                      }
                              )
                      }
                  }
              }
          }
          .padding()
      }
    
    private var cleanedOriginalWords: [String] {
        originalWords.map { cleanedWord($0) }
    }
    
    private func cleanedWord(_ word: String) -> String {
        word.filter { $0.isLetter || $0.isNumber }
    }
    
    private var rows: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentWidth: CGFloat = 0
        
        for word in words {
            let wordWidth = word.width(usingFont: .systemFont(ofSize: 16)) + 10
            if currentWidth + wordWidth > maxWidth {
                rows.append(currentRow)
                currentRow = [word]
                currentWidth = wordWidth
            } else {
                currentRow.append(word)
                currentWidth += wordWidth
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

extension String {
    func width(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attributes)
        return size.width
    }
}

struct ContentWrapView: View {
    var body: some View {
        WordWrappingView(words: ["Swift", "UI,", "is", "amazing", "and", "powerful", "for", "building", "iOS", "apps!", "Extraordinarly", "so", "supercalifragilistiexpiralidociouslyyyyyyyyyyyy", "very"], originalWords: ["Swift", "UI", "is", "great", "and!", "powerful", "for", "building", "iOS", "apps", "extraordinarly", "so", "supercalifragilistiexpiralidociouslyyyyyyyyyyyy", "very"], maxWidth: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentWrapView()
    }
}
