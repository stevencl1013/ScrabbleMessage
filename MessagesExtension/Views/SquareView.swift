import SwiftUI

struct SquareView: View {
    let square: Square
    let row: Int
    let col: Int
    var isPending: Bool = false
    var isDropTarget: Bool = false
    var size: CGFloat = 24
    var onTap: (() -> Void)?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .border(Color.black.opacity(0.15), width: 0.5)

            if isDropTarget && square.tile == nil {
                Rectangle()
                    .fill(Color.green.opacity(0.35))
            }

            if let tile = square.tile {
                TileView(tile: tile, isPending: isPending, size: size - 2)
            } else if square.premium != .none {
                Text(square.premium.label)
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(premiumTextColor)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size, height: size)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: BoardSquareFrameKey.self,
                    value: ["\(row),\(col)": geo.frame(in: .named("gameArea"))]
                )
            }
        )
        .onTapGesture {
            onTap?()
        }
    }

    private var backgroundColor: Color {
        if square.tile != nil { return Color(red: 0.92, green: 0.87, blue: 0.74) }
        switch square.premium {
        case .tripleWord: return Color(red: 0.9, green: 0.25, blue: 0.2)
        case .doubleWord: return Color(red: 0.95, green: 0.6, blue: 0.65)
        case .tripleLetter: return Color(red: 0.2, green: 0.5, blue: 0.85)
        case .doubleLetter: return Color(red: 0.65, green: 0.82, blue: 0.95)
        case .center: return Color(red: 0.95, green: 0.6, blue: 0.65)
        case .none: return Color(red: 0.82, green: 0.78, blue: 0.68)
        }
    }

    private var premiumTextColor: Color {
        switch square.premium {
        case .tripleWord: return .white
        case .tripleLetter: return .white
        default: return .white.opacity(0.9)
        }
    }
}
