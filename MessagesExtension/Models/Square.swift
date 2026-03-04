import Foundation

enum PremiumType: Int, Codable {
    case none = 0
    case doubleLetter = 1
    case tripleLetter = 2
    case doubleWord = 3
    case tripleWord = 4
    case center = 5

    var label: String {
        switch self {
        case .none: return ""
        case .doubleLetter: return "DL"
        case .tripleLetter: return "TL"
        case .doubleWord: return "DW"
        case .tripleWord: return "TW"
        case .center: return "★"
        }
    }

    var isWordMultiplier: Bool {
        self == .doubleWord || self == .tripleWord || self == .center
    }

    var wordMultiplier: Int {
        switch self {
        case .doubleWord, .center: return 2
        case .tripleWord: return 3
        default: return 1
        }
    }

    var letterMultiplier: Int {
        switch self {
        case .doubleLetter: return 2
        case .tripleLetter: return 3
        default: return 1
        }
    }
}

struct Square: Codable {
    let premium: PremiumType
    var tile: Tile?
    var premiumUsed: Bool

    init(premium: PremiumType, tile: Tile? = nil, premiumUsed: Bool = false) {
        self.premium = premium
        self.tile = tile
        self.premiumUsed = premiumUsed
    }

    var isEmpty: Bool { tile == nil }
}
