import Foundation

struct TilePlacement: Codable, Hashable {
    let tile: Tile
    let row: Int
    let col: Int
}

enum Direction: Codable {
    case horizontal
    case vertical
}

struct FoundWord: Codable {
    let word: String
    let positions: [Position]
    let direction: Direction

    struct Position: Codable {
        let row: Int
        let col: Int
    }
}

struct Move: Codable {
    let placements: [TilePlacement]
    let wordsFormed: [FoundWord]
    let score: Int
}

enum TurnAction: Codable {
    case play(Move)
    case exchange(Int) // number of tiles exchanged
    case pass
}
