import Foundation

struct WordFinder {
    /// Find all words formed by the given placements on the board.
    /// The board should already have the placed tiles on it.
    static func findWords(
        placements: [TilePlacement],
        board: Board
    ) -> [FoundWord] {
        guard !placements.isEmpty else { return [] }

        var words: [FoundWord] = []

        // Determine main direction
        let rows = Set(placements.map(\.row))
        let mainDirection: Direction = rows.count == 1 && placements.count > 1
            ? .horizontal : .vertical

        // Find the main word along the placement direction
        if let mainWord = findWordThrough(
            row: placements[0].row,
            col: placements[0].col,
            direction: mainDirection,
            board: board
        ), mainWord.word.count >= 2 {
            words.append(mainWord)
        }

        // Find cross-words for each placed tile
        let crossDirection: Direction = mainDirection == .horizontal ? .vertical : .horizontal
        for placement in placements {
            if let crossWord = findWordThrough(
                row: placement.row,
                col: placement.col,
                direction: crossDirection,
                board: board
            ), crossWord.word.count >= 2 {
                // Avoid duplicates
                let key = crossWord.positions.map { "\($0.row),\($0.col)" }.joined(separator: "-")
                let existingKeys = words.map { w in
                    w.positions.map { "\($0.row),\($0.col)" }.joined(separator: "-")
                }
                if !existingKeys.contains(key) {
                    words.append(crossWord)
                }
            }
        }

        // For a single tile, check both directions
        if placements.count == 1 {
            // For single tile, check horizontal too (mainDirection defaults to vertical)
            if let hWord = findWordThrough(
                row: placements[0].row,
                col: placements[0].col,
                direction: .horizontal,
                board: board
            ), hWord.word.count >= 2 {
                let key = hWord.positions.map { "\($0.row),\($0.col)" }.joined(separator: "-")
                let existingKeys = words.map { w in
                    w.positions.map { "\($0.row),\($0.col)" }.joined(separator: "-")
                }
                if !existingKeys.contains(key) {
                    words.append(hWord)
                }
            }
        }

        return words
    }

    /// Extends in both directions from the given position to find the full word.
    private static func findWordThrough(
        row: Int,
        col: Int,
        direction: Direction,
        board: Board
    ) -> FoundWord? {
        let dRow = direction == .vertical ? 1 : 0
        let dCol = direction == .horizontal ? 1 : 0

        // Extend backward to find start of word
        var startRow = row
        var startCol = col
        while board.isValid(row: startRow - dRow, col: startCol - dCol) &&
              board.isOccupied(row: startRow - dRow, col: startCol - dCol) {
            startRow -= dRow
            startCol -= dCol
        }

        // Extend forward to collect entire word
        var positions: [FoundWord.Position] = []
        var letters: [Character] = []
        var r = startRow
        var c = startCol
        while board.isValid(row: r, col: c), let tile = board.tile(at: r, col: c) {
            positions.append(FoundWord.Position(row: r, col: c))
            letters.append(tile.displayLetter)
            r += dRow
            c += dCol
        }

        guard letters.count >= 2 else { return nil }

        return FoundWord(
            word: String(letters),
            positions: positions,
            direction: direction
        )
    }
}
