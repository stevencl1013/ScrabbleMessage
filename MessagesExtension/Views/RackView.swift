import SwiftUI

struct RackView: View {
    let tiles: [Tile]
    var selectedTileID: UUID?
    var draggedTileID: UUID?
    var dropTargetIndex: Int?
    var onTileTap: ((Tile) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                let isDragged = draggedTileID == tile.id

                TileView(tile: tile, isPending: false, size: 40)
                    .opacity(isDragged ? 0.3 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(tileStrokeColor(tile: tile, index: index), lineWidth: 3)
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: RackSlotFrameKey.self,
                                value: [index: geo.frame(in: .named("gameArea"))]
                            )
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTileTap?(tile)
                    }
            }

            // Empty slots
            ForEach(0..<max(0, ScrabbleConstants.rackSize - tiles.count), id: \.self) { i in
                let slotIndex = tiles.count + i
                RoundedRectangle(cornerRadius: 3)
                    .stroke(dropTargetIndex == slotIndex ? Color.green : Color.gray.opacity(0.3), lineWidth: dropTargetIndex == slotIndex ? 2 : 1)
                    .frame(width: 40, height: 40)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: RackSlotFrameKey.self,
                                value: [slotIndex: geo.frame(in: .named("gameArea"))]
                            )
                        }
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.55, green: 0.35, blue: 0.2).opacity(0.3))
        )
    }

    private func tileStrokeColor(tile: Tile, index: Int) -> Color {
        if dropTargetIndex == index { return .green }
        if selectedTileID == tile.id { return .blue }
        return .clear
    }
}
