import SwiftUI

struct BoardView: View {
    let board: Board
    let pendingPositions: Set<String>
    let squareSize: CGFloat
    var dropTargetPosition: (row: Int, col: Int)?
    var onSquareTap: ((Int, Int) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<ScrabbleConstants.boardSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<ScrabbleConstants.boardSize, id: \.self) { col in
                        let square = board.grid[row][col]
                        let key = "\(row),\(col)"
                        let isTarget = dropTargetPosition?.row == row && dropTargetPosition?.col == col
                        SquareView(
                            square: square,
                            row: row,
                            col: col,
                            isPending: pendingPositions.contains(key),
                            isDropTarget: isTarget,
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
