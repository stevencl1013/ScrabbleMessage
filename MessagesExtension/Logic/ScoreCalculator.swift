import Foundation

struct ScoreCalculator {
    /// Calculate the total score for all words formed by the given placements.
    static func calculateScore(
        words: [FoundWord],
        placements: [TilePlacement],
        board: Board
    ) -> Int {
        let placedPositions = Set(placements.map { "\($0.row),\($0.col)" })
        var totalScore = 0

        for foundWord in words {
            var wordScore = 0
            var wordMultiplier = 1

            for pos in foundWord.positions {
                let square = board.grid[pos.row][pos.col]
                guard let tile = square.tile else { continue }

                var tileScore = tile.pointValue

                // Premiums only apply to tiles placed this turn on unused premium squares
                let key = "\(pos.row),\(pos.col)"
                if placedPositions.contains(key) && !square.premiumUsed {
                    tileScore *= square.premium.letterMultiplier
                    if square.premium.isWordMultiplier {
                        wordMultiplier *= square.premium.wordMultiplier
                    }
                }

                wordScore += tileScore
            }

            totalScore += wordScore * wordMultiplier
        }

        // Bingo bonus: all 7 tiles placed
        if placements.count == ScrabbleConstants.rackSize {
            totalScore += ScrabbleConstants.bingoBonus
        }

        return totalScore
    }
}
