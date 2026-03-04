import Foundation

/// Encodes and decodes GameState to/from URL query parameters.
/// Board is a 225-char string: "."=empty, "A"-"Z"=tile, "a"-"z"=blank-assigned-as-letter.
/// Tile bag is stored as counts per letter type.
/// Racks are stored as letter strings with "?" for unassigned blanks.
struct GameStateCoder {

    // MARK: - Encode

    static func encode(_ state: GameState) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        // Board: 225-char string
        items.append(URLQueryItem(name: "b", value: encodeBoard(state.board)))

        // Tile bag: count per letter type
        items.append(URLQueryItem(name: "bg", value: encodeTileBag(state.tileBag)))

        // Racks
        items.append(URLQueryItem(name: "r0", value: encodeRack(state.players[0].rack)))
        items.append(URLQueryItem(name: "r1", value: encodeRack(state.players[1].rack)))

        // Scores
        items.append(URLQueryItem(name: "s0", value: String(state.players[0].score)))
        items.append(URLQueryItem(name: "s1", value: String(state.players[1].score)))

        // Current player
        items.append(URLQueryItem(name: "t", value: String(state.currentPlayerIndex)))

        // Turn number
        items.append(URLQueryItem(name: "n", value: String(state.turnNumber)))

        // Consecutive passes
        items.append(URLQueryItem(name: "p0", value: String(state.players[0].consecutivePasses)))
        items.append(URLQueryItem(name: "p1", value: String(state.players[1].consecutivePasses)))

        // Game over
        items.append(URLQueryItem(name: "g", value: state.isGameOver ? "1" : "0"))

        // Player names
        items.append(URLQueryItem(name: "n0", value: state.players[0].name))
        items.append(URLQueryItem(name: "n1", value: state.players[1].name))

        // Player identifiers
        items.append(URLQueryItem(name: "id0", value: state.playerIdentifiers[0]))
        items.append(URLQueryItem(name: "id1", value: state.playerIdentifiers[1]))

        // Premium used flags: encode as a 225-char string of 0/1
        items.append(URLQueryItem(name: "pu", value: encodePremiumUsed(state.board)))

        return items
    }

    // MARK: - Decode

    static func decode(from url: URL) -> GameState? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }

        let dict = Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })

        guard let boardStr = dict["b"],
              let bagStr = dict["bg"],
              let rack0Str = dict["r0"],
              let rack1Str = dict["r1"],
              let score0 = dict["s0"].flatMap(Int.init),
              let score1 = dict["s1"].flatMap(Int.init),
              let turn = dict["t"].flatMap(Int.init),
              let turnNumber = dict["n"].flatMap(Int.init) else {
            return nil
        }

        var board = decodeBoard(boardStr)
        let premiumUsedStr = dict["pu"] ?? ""
        applyPremiumUsed(&board, from: premiumUsedStr)

        let tileBag = decodeTileBag(bagStr)
        let rack0 = decodeRack(rack0Str)
        let rack1 = decodeRack(rack1Str)

        var player0 = Player(name: dict["n0"] ?? "Player 1")
        player0.score = score0
        player0.rack = rack0
        player0.consecutivePasses = dict["p0"].flatMap(Int.init) ?? 0

        var player1 = Player(name: dict["n1"] ?? "Player 2")
        player1.score = score1
        player1.rack = rack1
        player1.consecutivePasses = dict["p1"].flatMap(Int.init) ?? 0

        let isGameOver = dict["g"] == "1"
        let id0 = dict["id0"] ?? ""
        let id1 = dict["id1"] ?? ""

        return GameState(
            board: board,
            tileBag: tileBag,
            players: [player0, player1],
            currentPlayerIndex: turn,
            isGameOver: isGameOver,
            turnNumber: turnNumber,
            playerIdentifiers: [id0, id1]
        )
    }

    // MARK: - Board Encoding

    private static func encodeBoard(_ board: Board) -> String {
        var result = ""
        for row in board.grid {
            for square in row {
                if let tile = square.tile {
                    if tile.isBlank {
                        // Lowercase for blank-assigned-as-letter
                        let letter = tile.assignedLetter ?? Character("a")
                        result.append(Character(letter.lowercased()))
                    } else {
                        result.append(tile.letter)
                    }
                } else {
                    result.append(".")
                }
            }
        }
        return result
    }

    private static func decodeBoard(_ str: String) -> Board {
        var board = Board.standard()
        let chars = Array(str)
        for i in 0..<min(chars.count, 225) {
            let row = i / 15
            let col = i % 15
            let ch = chars[i]
            if ch == "." {
                continue
            } else if ch.isLowercase {
                // Blank tile assigned as this letter
                let upper = Character(ch.uppercased())
                var tile = Tile(letter: "?", pointValue: 0)
                tile.assignedLetter = upper
                board.grid[row][col].tile = tile
            } else {
                let pointValue = ScrabbleConstants.letterValues[ch] ?? 0
                let tile = Tile(letter: ch, pointValue: pointValue)
                board.grid[row][col].tile = tile
            }
        }
        return board
    }

    // MARK: - Premium Used Encoding

    private static func encodePremiumUsed(_ board: Board) -> String {
        var result = ""
        for row in board.grid {
            for square in row {
                result.append(square.premiumUsed ? "1" : "0")
            }
        }
        return result
    }

    private static func applyPremiumUsed(_ board: inout Board, from str: String) {
        let chars = Array(str)
        for i in 0..<min(chars.count, 225) {
            let row = i / 15
            let col = i % 15
            board.grid[row][col].premiumUsed = chars[i] == "1"
        }
    }

    // MARK: - Tile Bag Encoding

    /// Encode tile bag as remaining counts for each tile type (A-Z, then blank).
    /// Each count is encoded as a hex character (0-9, a-f).
    private static func encodeTileBag(_ bag: TileBag) -> String {
        let order: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ?")
        var counts: [Character: Int] = [:]
        for tile in bag.tiles {
            counts[tile.letter, default: 0] += 1
        }
        var result = ""
        for letter in order {
            let count = counts[letter] ?? 0
            result.append(String(count, radix: 16))
        }
        return result
    }

    private static func decodeTileBag(_ str: String) -> TileBag {
        let order: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ?")
        let chars = Array(str)
        var tiles: [Tile] = []

        for (i, letter) in order.enumerated() {
            guard i < chars.count else { break }
            let count = Int(String(chars[i]), radix: 16) ?? 0
            let pointValue = ScrabbleConstants.letterValues[letter] ?? 0
            for _ in 0..<count {
                tiles.append(Tile(letter: letter, pointValue: pointValue))
            }
        }

        tiles.shuffle()
        return TileBag(tiles: tiles)
    }

    // MARK: - Rack Encoding

    private static func encodeRack(_ rack: [Tile]) -> String {
        var result = ""
        for tile in rack {
            if tile.isBlank {
                if let assigned = tile.assignedLetter {
                    result.append(Character(assigned.lowercased()))
                } else {
                    result.append("?")
                }
            } else {
                result.append(tile.letter)
            }
        }
        return result
    }

    private static func decodeRack(_ str: String) -> [Tile] {
        var rack: [Tile] = []
        for ch in str {
            if ch == "?" {
                rack.append(Tile(letter: "?", pointValue: 0))
            } else if ch.isLowercase {
                var tile = Tile(letter: "?", pointValue: 0)
                tile.assignedLetter = Character(ch.uppercased())
                rack.append(tile)
            } else {
                let pointValue = ScrabbleConstants.letterValues[ch] ?? 0
                rack.append(Tile(letter: ch, pointValue: pointValue))
            }
        }
        return rack
    }
}
