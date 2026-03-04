import Foundation

class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isEndOfWord: Bool = false
}

class WordDictionary {
    static let shared = WordDictionary()

    private let root = TrieNode()
    private var isLoaded = false

    func loadIfNeeded() {
        guard !isLoaded else { return }
        guard let url = Bundle.main.url(forResource: "twl06", withExtension: "txt") else {
            print("Warning: twl06.txt not found in bundle")
            return
        }
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            print("Warning: Could not read twl06.txt")
            return
        }
        let words = contents.components(separatedBy: .newlines)
        for word in words {
            let trimmed = word.trimmingCharacters(in: .whitespaces).uppercased()
            if !trimmed.isEmpty {
                insert(trimmed)
            }
        }
        isLoaded = true
    }

    private func insert(_ word: String) {
        var node = root
        for char in word {
            if node.children[char] == nil {
                node.children[char] = TrieNode()
            }
            node = node.children[char]!
        }
        node.isEndOfWord = true
    }

    func isValidWord(_ word: String) -> Bool {
        loadIfNeeded()
        let upper = word.uppercased()
        guard upper.count >= 2 else { return false }
        var node = root
        for char in upper {
            guard let next = node.children[char] else { return false }
            node = next
        }
        return node.isEndOfWord
    }
}
