import SwiftUI

struct CompactView: View {
    let gameState: GameState
    let isLocalPlayerTurn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isLocalPlayerTurn ? "Your turn!" : "Waiting for opponent...")
                    .font(.headline)
                    .foregroundColor(isLocalPlayerTurn ? .blue : .secondary)

                Text("\(gameState.players[0].name): \(gameState.players[0].score)  •  \(gameState.players[1].name): \(gameState.players[1].score)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if gameState.isGameOver {
                Text("Game Over")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                Text("Tap to play")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
