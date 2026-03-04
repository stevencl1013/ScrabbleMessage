import SwiftUI

struct ExchangeSheetView: View {
    let rack: [Tile]
    @Binding var isPresented: Bool
    var onConfirm: ([Tile]) -> Void

    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select tiles to exchange")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(rack) { tile in
                        TileView(tile: tile, size: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(selectedIDs.contains(tile.id) ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                if selectedIDs.contains(tile.id) {
                                    selectedIDs.remove(tile.id)
                                } else {
                                    selectedIDs.insert(tile.id)
                                }
                            }
                    }
                }

                Text("\(selectedIDs.count) tile\(selectedIDs.count == 1 ? "" : "s") selected")
                    .foregroundColor(.secondary)

                Button("Exchange") {
                    let tiles = rack.filter { selectedIDs.contains($0.id) }
                    onConfirm(tiles)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIDs.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Exchange Tiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
