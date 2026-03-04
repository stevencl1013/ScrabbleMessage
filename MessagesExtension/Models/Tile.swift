import Foundation

struct Tile: Codable, Hashable, Identifiable {
    let id: UUID
    let letter: Character
    let pointValue: Int
    var assignedLetter: Character?

    var displayLetter: Character {
        assignedLetter ?? letter
    }

    var isBlank: Bool { letter == "?" }

    init(letter: Character, pointValue: Int, assignedLetter: Character? = nil) {
        self.id = UUID()
        self.letter = letter
        self.pointValue = pointValue
        self.assignedLetter = assignedLetter
    }

    // Custom Codable for Character
    enum CodingKeys: String, CodingKey {
        case id, letter, pointValue, assignedLetter
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        let letterStr = try c.decode(String.self, forKey: .letter)
        letter = letterStr.first ?? "?"
        pointValue = try c.decode(Int.self, forKey: .pointValue)
        if let assigned = try c.decodeIfPresent(String.self, forKey: .assignedLetter) {
            assignedLetter = assigned.first
        } else {
            assignedLetter = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(String(letter), forKey: .letter)
        try c.encode(pointValue, forKey: .pointValue)
        if let assigned = assignedLetter {
            try c.encode(String(assigned), forKey: .assignedLetter)
        }
    }
}
