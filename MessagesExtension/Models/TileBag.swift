import Foundation

struct TileBag: Codable {
    private(set) var tiles: [Tile]

    static func standard() -> TileBag {
        var tiles: [Tile] = []
        for (letter, count, pointValue) in ScrabbleConstants.tileDistribution {
            for _ in 0..<count {
                tiles.append(Tile(letter: letter, pointValue: pointValue))
            }
        }
        tiles.shuffle()
        return TileBag(tiles: tiles)
    }

    mutating func draw(_ count: Int) -> [Tile] {
        let drawCount = min(count, tiles.count)
        let drawn = Array(tiles.prefix(drawCount))
        tiles.removeFirst(drawCount)
        return drawn
    }

    mutating func returnTiles(_ returned: [Tile]) {
        tiles.append(contentsOf: returned)
        tiles.shuffle()
    }

    var isEmpty: Bool { tiles.isEmpty }
    var count: Int { tiles.count }
}
