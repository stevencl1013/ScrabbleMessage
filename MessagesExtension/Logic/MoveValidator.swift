import Foundation

enum MoveError: Error, LocalizedError {
    case noTilesPlaced
    case notInLine
    case notContiguous
    case mustCrossCenter
    case notConnected
    case invalidWord(String)

    var errorDescription: String? {
        switch self {
        case .noTilesPlaced: return "Place at least one tile."
        case .notInLine: return "All tiles must be in the same row or column."
        case .notContiguous: return "Tiles must form a contiguous line."
        case .mustCrossCenter: return "First move must cover the center square."
        case .notConnected: return "Tiles must connect to existing tiles on the board."
        case .invalidWord(let word): return "\"\(word)\" is not a valid word."
        }
    }
}

struct MoveValidator {
    static func validate(
        placements: [TilePlacement],
        board: Board
    ) -> Result<Void, MoveError> {
        guard !placements.isEmpty else {
            return .failure(.noTilesPlaced)
        }

        // Check all tiles are in the same row or column
        let rows = Set(placements.map(\.row))
        let cols = Set(placements.map(\.col))
        let isHorizontal = rows.count == 1
        let isVertical = cols.count == 1
        let isSingleTile = placements.count == 1

        if !isSingleTile && !isHorizontal && !isVertical {
            return .failure(.notInLine)
        }

        // Check contiguity (no gaps in the line, though existing tiles may fill them)
        if !isSingleTile {
            if isHorizontal {
                let row = placements[0].row
                let minCol = placements.map(\.col).min()!
                let maxCol = placements.map(\.col).max()!
                let placedCols = Set(placements.map(\.col))
                for col in minCol...maxCol {
                    if !placedCols.contains(col) && !board.isOccupied(row: row, col: col) {
                        return .failure(.notContiguous)
                    }
                }
            } else {
                let col = placements[0].col
                let minRow = placements.map(\.row).min()!
                let maxRow = placements.map(\.row).max()!
                let placedRows = Set(placements.map(\.row))
                for row in minRow...maxRow {
                    if !placedRows.contains(row) && !board.isOccupied(row: row, col: col) {
                        return .failure(.notContiguous)
                    }
                }
            }
        }

        // First move must cross center
        if !board.hasAnyTile {
            let crossesCenter = placements.contains {
                $0.row == ScrabbleConstants.centerRow && $0.col == ScrabbleConstants.centerCol
            }
            if !crossesCenter {
                return .failure(.mustCrossCenter)
            }
        } else {
            // Must connect to at least one existing tile
            let connected = placements.contains { placement in
                let neighbors = [
                    (placement.row - 1, placement.col),
                    (placement.row + 1, placement.col),
                    (placement.row, placement.col - 1),
                    (placement.row, placement.col + 1)
                ]
                return neighbors.contains { board.isOccupied(row: $0.0, col: $0.1) }
            }
            if !connected {
                return .failure(.notConnected)
            }
        }

        return .success(())
    }
}
