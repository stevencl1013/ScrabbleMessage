import Foundation

struct Player: Codable, Identifiable {
    let id: UUID
    var name: String
    var score: Int
    var rack: [Tile]
    var consecutivePasses: Int

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.score = 0
        self.rack = []
        self.consecutivePasses = 0
    }

    var rackValue: Int {
        rack.reduce(0) { $0 + $1.pointValue }
    }
}
