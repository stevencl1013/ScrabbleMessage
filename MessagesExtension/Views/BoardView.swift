import SwiftUI

struct BoardView: View {
    let board: Board
    let pendingPositions: Set<String>
    let squareSize: CGFloat
    var onSquareTap: ((Int, Int) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<ScrabbleConstants.boardSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<ScrabbleConstants.boardSize, id: \.self) { col in
                        let square = board.grid[row][col]
                        let key = "\(row),\(col)"
                        SquareView(
                            square: square,
                            row: row,
                            col: col,
                            isPending: pendingPositions.contains(key),
                            size: squareSize,
                            onTap: { onSquareTap?(row, col) }
                        )
                    }
                }
            }
        }
        .background(Color.black)
    }
}
