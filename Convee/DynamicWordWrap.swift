import SwiftUI

struct WordWrappingView: View {
    let words: [String]
    let maxWidth: CGFloat
    var onWordTap: ((Int) -> Void)?  // Closure to handle word taps
    @State private var touchedWordIndex: Int? = nil  

    var body: some View {
          VStack(alignment: .leading, spacing: 10) {
              ForEach(Array(rows.enumerated()), id: \.0) { rowIndex, row in
                  HStack(spacing: 5) {
                      ForEach(Array(row.enumerated()), id: \.0) { wordIndex, word in
                          Text(word)
                              .padding(5)
                              .background(Color.blue.opacity(0.2))
                              .cornerRadius(5)
                              .onTapGesture {
                                  let index = rows[0..<rowIndex].flatMap { $0 }.count + wordIndex
                                  onWordTap?(index)
                              }
                              .gesture(
                                  DragGesture(minimumDistance: 0)
                                      .onChanged { _ in
                                          // Calculate the index of the word being swiped over
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
      
    
    private var rows: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentWidth: CGFloat = 0
        
        for word in words {
            let wordWidth = word.width(usingFont: .systemFont(ofSize: 16)) + 10 // Approximate word width
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
        WordWrappingView(words: ["Swift", "UI", "is", "amazing", "and", "powerful", "for", "building", "iOS", "apps", "extraordinarly", "so", "supercalifragilistiexpiralidociouslyyyyyyyyyyyy", "very"], maxWidth: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentWrapView()
    }
}
