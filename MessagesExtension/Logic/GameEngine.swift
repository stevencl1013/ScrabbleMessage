import Foundation
import Combine

class GameEngine: ObservableObject {
    @Published var gameState: GameState
    @Published var pendingPlacements: [TilePlacement] = []
    @Published var errorMessage: String?
    @Published var lastMoveScore: Int?
    @Published var showBlankPicker = false

    var pendingBlankTile: Tile?
    var pendingBlankRow: Int = 0
    var pendingBlankCol: Int = 0

    var localPlayerIndex: Int?

    var isLocalPlayerTurn: Bool {
        guard let local = localPlayerIndex else { return true }
        return gameState.currentPlayerIndex == local
    }

    var currentPlayerRack: [Tile] {
        gameState.currentPlayer.rack
    }

    init(gameState: GameState) {
        self.gameState = gameState
    }

    // MARK: - Tile Placement

    func placeTile(_ tile: Tile, at row: Int, col: Int) {
        guard !gameState.board.isOccupied(row: row, col: col) else { return }
        guard !pendingPlacements.contains(where: { $0.row == row && $0.col == col }) else { return }

        if tile.isBlank && tile.assignedLetter == nil {
            pendingBlankTile = tile
            pendingBlankRow = row
            pendingBlankCol = col
            showBlankPicker = true
            return
        }

        // Remove from rack
        if let idx = gameState.currentPlayer.rack.firstIndex(where: { $0.id == tile.id }) {
            gameState.players[gameState.currentPlayerIndex].rack.remove(at: idx)
        }

        let placement = TilePlacement(tile: tile, row: row, col: col)
        pendingPlacements.append(placement)
        gameState.board.place(tile: tile, at: row, col: col)
        errorMessage = nil
    }

    func assignBlankAndPlace(letter: Character) {
        guard var tile = pendingBlankTile else { return }
        tile.assignedLetter = letter

        showBlankPicker = false
        pendingBlankTile = nil

        // Remove from rack
        if let idx = gameState.currentPlayer.rack.firstIndex(where: { $0.id == tile.id }) {
            gameState.players[gameState.currentPlayerIndex].rack.remove(at: idx)
        }

        let placement = TilePlacement(tile: tile, row: pendingBlankRow, col: pendingBlankCol)
        pendingPlacements.append(placement)
        gameState.board.place(tile: tile, at: pendingBlankRow, col: pendingBlankCol)
    }

    func removePlacedTile(at row: Int, col: Int) {
        guard let idx = pendingPlacements.firstIndex(where: { $0.row == row && $0.col == col }) else { return }
        let placement = pendingPlacements.remove(at: idx)
        _ = gameState.board.removeTile(at: row, col: col)
        var returnedTile = placement.tile
        if returnedTile.isBlank {
            returnedTile.assignedLetter = nil
        }
        gameState.players[gameState.currentPlayerIndex].rack.append(returnedTile)
    }

    func recallAllTiles() {
        for placement in pendingPlacements.reversed() {
            removePlacedTile(at: placement.row, col: placement.col)
        }
    }

    func shuffleRack() {
        gameState.players[gameState.currentPlayerIndex].rack.shuffle()
    }

    // MARK: - Submit Move

    func submitMove() -> Result<Move, MoveError> {
        // Validate placement geometry
        let validationResult = MoveValidator.validate(
            placements: pendingPlacements,
            board: gameState.board
        )

        switch validationResult {
        case .failure(let error):
            errorMessage = error.localizedDescription
            return .failure(error)
        case .success:
            break
        }

        // Find all words formed
        let words = WordFinder.findWords(
            placements: pendingPlacements,
            board: gameState.board
        )

        // Validate each word
        let dictionary = WordDictionary.shared
        for word in words {
            if !dictionary.isValidWord(word.word) {
                let error = MoveError.invalidWord(word.word)
                errorMessage = error.localizedDescription
                return .failure(error)
            }
        }

        // Calculate score
        let score = ScoreCalculator.calculateScore(
            words: words,
            placements: pendingPlacements,
            board: gameState.board
        )

        // Mark premiums as used
        for placement in pendingPlacements {
            gameState.board.markPremiumUsed(at: placement.row, col: placement.col)
        }

        // Update player score
        gameState.players[gameState.currentPlayerIndex].score += score
        gameState.players[gameState.currentPlayerIndex].consecutivePasses = 0

        let move = Move(placements: pendingPlacements, wordsFormed: words, score: score)
        lastMoveScore = score

        // Refill rack
        refillRack(for: gameState.currentPlayerIndex)

        // Check game over
        if gameState.players[gameState.currentPlayerIndex].rack.isEmpty && gameState.tileBag.isEmpty {
            endGame(finisher: gameState.currentPlayerIndex)
        } else {
            advanceTurn()
        }

        pendingPlacements = []
        errorMessage = nil
        return .success(move)
    }

    // MARK: - Pass & Exchange

    func passTurn() {
        recallAllTiles()
        gameState.players[gameState.currentPlayerIndex].consecutivePasses += 1

        if gameState.players.allSatisfy({ $0.consecutivePasses >= 3 }) {
            endGameByPasses()
        } else {
            advanceTurn()
        }
        pendingPlacements = []
    }

    func exchangeTiles(_ tilesToExchange: [Tile]) {
        guard gameState.tileBag.count >= tilesToExchange.count else { return }
        recallAllTiles()

        // Remove selected tiles from rack
        for tile in tilesToExchange {
            if let idx = gameState.players[gameState.currentPlayerIndex].rack.firstIndex(where: { $0.id == tile.id }) {
                gameState.players[gameState.currentPlayerIndex].rack.remove(at: idx)
            }
        }

        // Draw new tiles
        let newTiles = gameState.tileBag.draw(tilesToExchange.count)
        gameState.players[gameState.currentPlayerIndex].rack.append(contentsOf: newTiles)

        // Return old tiles to bag
        gameState.tileBag.returnTiles(tilesToExchange)

        gameState.players[gameState.currentPlayerIndex].consecutivePasses += 1

        if gameState.players.allSatisfy({ $0.consecutivePasses >= 3 }) {
            endGameByPasses()
        } else {
            advanceTurn()
        }
        pendingPlacements = []
    }

    // MARK: - Private Helpers

    private func refillRack(for playerIndex: Int) {
        let needed = ScrabbleConstants.rackSize - gameState.players[playerIndex].rack.count
        if needed > 0 {
            let drawn = gameState.tileBag.draw(needed)
            gameState.players[playerIndex].rack.append(contentsOf: drawn)
        }
    }

    private func advanceTurn() {
        gameState.currentPlayerIndex = gameState.opponentIndex
        gameState.turnNumber += 1
    }

    private func endGame(finisher: Int) {
        gameState.isGameOver = true
        let opponent = 1 - finisher
        let opponentRackValue = gameState.players[opponent].rackValue
        gameState.players[finisher].score += opponentRackValue
        gameState.players[opponent].score -= opponentRackValue
    }

    private func endGameByPasses() {
        gameState.isGameOver = true
        for i in 0..<gameState.players.count {
            gameState.players[i].score -= gameState.players[i].rackValue
        }
    }

    func checkGameOver() -> Bool {
        gameState.isGameOver
    }
}
