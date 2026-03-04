import SwiftUI

struct RackView: View {
    let tiles: [Tile]
    var selectedTileID: UUID?
    var onTileTap: ((Tile) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tiles) { tile in
                TileView(tile: tile, isPending: false, size: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(selectedTileID == tile.id ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .onTapGesture {
                        onTileTap?(tile)
                    }
            }

            // Empty slots
            ForEach(0..<max(0, ScrabbleConstants.rackSize - tiles.count), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.55, green: 0.35, blue: 0.2).opacity(0.3))
        )
    }
}
