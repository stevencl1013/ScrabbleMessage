import Messages
import UIKit

struct MessageComposer {
    static func compose(
        state: GameState,
        session: MSSession,
        caption: String,
        subcaption: String
    ) -> MSMessage {
        let message = MSMessage(session: session)
        let layout = MSMessageTemplateLayout()
        layout.caption = caption
        layout.subcaption = subcaption
        message.layout = layout

        var components = URLComponents()
        components.queryItems = GameStateCoder.encode(state)
        message.url = components.url

        return message
    }

    static func captionForMove(playerName: String, move: Move) -> String {
        let wordsText = move.wordsFormed.map(\.word).joined(separator: ", ")
        return "\(playerName) played \(wordsText) for \(move.score) pts"
    }

    static func captionForPass(playerName: String) -> String {
        "\(playerName) passed"
    }

    static func captionForExchange(playerName: String, count: Int) -> String {
        "\(playerName) exchanged \(count) tile\(count == 1 ? "" : "s")"
    }

    static func subcaption(state: GameState) -> String {
        if state.isGameOver {
            let winner = state.players[0].score >= state.players[1].score
                ? state.players[0] : state.players[1]
            return "Game over! \(winner.name) wins \(state.players[0].score)-\(state.players[1].score)"
        }
        return "Your turn! Score: \(state.players[0].score)-\(state.players[1].score)"
    }
}
