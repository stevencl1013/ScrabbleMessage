import Foundation

struct GameState: Codable {
    var board: Board
    var tileBag: TileBag
    var players: [Player]
    var currentPlayerIndex: Int
    var isGameOver: Bool
    var turnNumber: Int
    var playerIdentifiers: [String] // localParticipantIdentifier UUIDs as strings

    var currentPlayer: Player {
        get { players[currentPlayerIndex] }
        set { players[currentPlayerIndex] = newValue }
    }

    var opponentIndex: Int { 1 - currentPlayerIndex }

    var opponentPlayer: Player {
        get { players[opponentIndex] }
        set { players[opponentIndex] = newValue }
    }

    static func newGame() -> GameState {
        var bag = TileBag.standard()
        var player0 = Player(name: "Player 1")
        var player1 = Player(name: "Player 2")
        player0.rack = bag.draw(ScrabbleConstants.rackSize)
        player1.rack = bag.draw(ScrabbleConstants.rackSize)

        return GameState(
            board: .standard(),
            tileBag: bag,
            players: [player0, player1],
            currentPlayerIndex: 0,
            isGameOver: false,
            turnNumber: 1,
            playerIdentifiers: ["", ""]
        )
    }
}
