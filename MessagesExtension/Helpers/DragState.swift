import SwiftUI

/// Source of a dragged tile
enum DragSource: Equatable {
    case rack(index: Int)
    case board(row: Int, col: Int)
}

/// Where the tile would land if released now
enum DropTarget: Equatable {
    case rack(index: Int)
    case board(row: Int, col: Int)
    case none
}

/// Tracks the current drag-and-drop state across the game view
class DragStateManager: ObservableObject {
    @Published var isDragging = false
    @Published var draggedTile: Tile?
    @Published var dragSource: DragSource?
    @Published var dragLocation: CGPoint = .zero
    @Published var dropTarget: DropTarget = .none

    // Collected frames from board squares and rack slots (in the shared coordinate space)
    var boardFrames: [String: CGRect] = [:]  // "row,col" -> frame
    var rackFrames: [Int: CGRect] = [:]       // index -> frame

    func startDrag(tile: Tile, source: DragSource, location: CGPoint) {
        isDragging = true
        draggedTile = tile
        dragSource = source
        dragLocation = location
        dropTarget = .none
    }

    func updateDrag(location: CGPoint) {
        dragLocation = location
        dropTarget = hitTest(location)
    }

    func endDrag() -> (tile: Tile, source: DragSource, target: DropTarget)? {
        guard let tile = draggedTile, let source = dragSource else {
            cancelDrag()
            return nil
        }
        let target = dropTarget
        cancelDrag()
        return (tile, source, target)
    }

    func cancelDrag() {
        isDragging = false
        draggedTile = nil
        dragSource = nil
        dragLocation = .zero
        dropTarget = .none
    }

    private func hitTest(_ point: CGPoint) -> DropTarget {
        // Check board squares
        for (key, frame) in boardFrames {
            if frame.contains(point) {
                let parts = key.split(separator: ",")
                if parts.count == 2, let row = Int(parts[0]), let col = Int(parts[1]) {
                    return .board(row: row, col: col)
                }
            }
        }

        // Check rack slots
        for (index, frame) in rackFrames {
            if frame.contains(point) {
                return .rack(index: index)
            }
        }

        return .none
    }
}

// MARK: - Preference keys for collecting frames

struct BoardSquareFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct RackSlotFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
