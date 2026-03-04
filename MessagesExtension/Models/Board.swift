import Foundation

struct Board: Codable {
    var grid: [[Square]]

    static func standard() -> Board {
        let map = ScrabbleConstants.premiumMap
        var grid: [[Square]] = []
        for row in 0..<ScrabbleConstants.boardSize {
            var gridRow: [Square] = []
            for col in 0..<ScrabbleConstants.boardSize {
                gridRow.append(Square(premium: map[row][col]))
            }
            grid.append(gridRow)
        }
        return Board(grid: grid)
    }

    func tile(at row: Int, col: Int) -> Tile? {
        guard isValid(row: row, col: col) else { return nil }
        return grid[row][col].tile
    }

    mutating func place(tile: Tile, at row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        grid[row][col].tile = tile
    }

    mutating func removeTile(at row: Int, col: Int) -> Tile? {
        guard isValid(row: row, col: col) else { return nil }
        let tile = grid[row][col].tile
        grid[row][col].tile = nil
        return tile
    }

    func isOccupied(row: Int, col: Int) -> Bool {
        tile(at: row, col: col) != nil
    }

    var hasAnyTile: Bool {
        grid.contains { row in row.contains { !$0.isEmpty } }
    }

    func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < ScrabbleConstants.boardSize &&
        col >= 0 && col < ScrabbleConstants.boardSize
    }

    mutating func markPremiumUsed(at row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        grid[row][col].premiumUsed = true
    }
}
