import SwiftUI

struct ControlsView: View {
    let hasPendingTiles: Bool
    let canExchange: Bool
    let isGameOver: Bool
    var onSubmit: () -> Void
    var onRecall: () -> Void
    var onShuffle: () -> Void
    var onPass: () -> Void
    var onExchange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRecall) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Recall")
                        .font(.caption2)
                }
            }
            .disabled(!hasPendingTiles || isGameOver)

            Button(action: onShuffle) {
                VStack(spacing: 2) {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                        .font(.caption2)
                }
            }
            .disabled(isGameOver)

            Button(action: onExchange) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Exchange")
                        .font(.caption2)
                }
            }
            .disabled(!canExchange || isGameOver)

            Button(action: onPass) {
                VStack(spacing: 2) {
                    Image(systemName: "forward.end")
                    Text("Pass")
                        .font(.caption2)
                }
            }
            .disabled(isGameOver)

            Button(action: onSubmit) {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Submit")
                        .font(.caption2)
                }
            }
            .disabled(!hasPendingTiles || isGameOver)
            .tint(.green)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
