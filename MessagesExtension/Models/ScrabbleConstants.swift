import Foundation

enum ScrabbleConstants {
    static let boardSize = 15
    static let rackSize = 7
    static let bingoBonus = 50
    static let centerRow = 7
    static let centerCol = 7

    // (letter, count, pointValue)
    static let tileDistribution: [(Character, Int, Int)] = [
        ("A", 9, 1), ("B", 2, 3), ("C", 2, 3), ("D", 4, 2),
        ("E", 12, 1), ("F", 2, 4), ("G", 3, 2), ("H", 2, 4),
        ("I", 9, 1), ("J", 1, 8), ("K", 1, 5), ("L", 4, 1),
        ("M", 2, 3), ("N", 6, 1), ("O", 8, 1), ("P", 2, 3),
        ("Q", 1, 10), ("R", 6, 1), ("S", 4, 1), ("T", 6, 1),
        ("U", 4, 1), ("V", 2, 4), ("W", 2, 4), ("X", 1, 8),
        ("Y", 2, 4), ("Z", 1, 10), ("?", 2, 0)
    ]

    static let letterValues: [Character: Int] = {
        var values: [Character: Int] = [:]
        for (letter, _, pointValue) in tileDistribution {
            values[letter] = pointValue
        }
        return values
    }()

    // Premium square map for the standard Scrabble board
    // 0=none, 1=DL, 2=TL, 3=DW, 4=TW, 5=center
    static let premiumMap: [[PremiumType]] = {
        let raw: [[Int]] = [
            [4,0,0,1,0,0,2,0,2,0,0,1,0,0,4],
            [0,3,0,0,0,2,0,0,0,2,0,0,0,3,0],
            [0,0,3,0,0,0,1,0,1,0,0,0,3,0,0],
            [1,0,0,3,0,0,0,1,0,0,0,3,0,0,1],
            [0,0,0,0,3,0,0,0,0,0,3,0,0,0,0],
            [0,2,0,0,0,2,0,0,0,2,0,0,0,2,0],
            [2,0,1,0,0,0,1,0,1,0,0,0,1,0,2],
            [0,0,0,1,0,0,0,5,0,0,0,1,0,0,0],
            [2,0,1,0,0,0,1,0,1,0,0,0,1,0,2],
            [0,2,0,0,0,2,0,0,0,2,0,0,0,2,0],
            [0,0,0,0,3,0,0,0,0,0,3,0,0,0,0],
            [1,0,0,3,0,0,0,1,0,0,0,3,0,0,1],
            [0,0,3,0,0,0,1,0,1,0,0,0,3,0,0],
            [0,3,0,0,0,2,0,0,0,2,0,0,0,3,0],
            [4,0,0,1,0,0,2,0,2,0,0,1,0,0,4],
        ]
        return raw.map { row in
            row.map { PremiumType(rawValue: $0) ?? .none }
        }
    }()
}
