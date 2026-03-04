import SwiftUI

struct ScoreBarView: View {
    let players: [Player]
    let currentPlayerIndex: Int
    let tilesRemaining: Int

    var body: some View {
        HStack {
            playerScore(player: players[0], isActive: currentPlayerIndex == 0)
            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "square.grid.2x2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(tilesRemaining)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
            playerScore(player: players[1], isActive: currentPlayerIndex == 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.95))
    }

    private func playerScore(player: Player, isActive: Bool) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(player.name)
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .primary : .secondary)
            Text("\(player.score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .blue : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}
