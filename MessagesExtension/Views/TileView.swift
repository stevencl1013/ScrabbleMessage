import SwiftUI

struct TileView: View {
    let tile: Tile
    var isPending: Bool = false
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.95, green: 0.89, blue: 0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isPending ? Color.orange : Color(red: 0.78, green: 0.72, blue: 0.60), lineWidth: isPending ? 2 : 1)
                )

            VStack(spacing: 0) {
                Text(String(tile.displayLetter))
                    .font(.system(size: size * 0.55, weight: .bold, design: .serif))
                    .foregroundColor(.black)
            }

            if tile.pointValue > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(tile.pointValue)")
                            .font(.system(size: size * 0.25, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.trailing, 2)
                            .padding(.bottom, 1)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}
