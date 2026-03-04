import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine
    @EnvironmentObject var sendAction: SendMessageAction
    @StateObject private var dragState = DragStateManager()
    @State private var selectedTile: Tile?
    @State private var showExchange = false
    @State private var showPassConfirm = false
    @State private var dragStartedThisGesture = false

    var body: some View {
        GeometryReader { geometry in
            let boardWidth = min(geometry.size.width - 8, geometry.size.height * 0.6)
            let squareSize = boardWidth / CGFloat(ScrabbleConstants.boardSize)

            ZStack {
                VStack(spacing: 8) {
                    // Score bar
                    ScoreBarView(
                        players: engine.gameState.players,
                        currentPlayerIndex: engine.gameState.currentPlayerIndex,
                        tilesRemaining: engine.gameState.tileBag.count
                    )

                    // Board
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        BoardView(
                            board: engine.gameState.board,
                            pendingPositions: pendingPositionSet,
                            squareSize: squareSize,
                            dropTargetPosition: boardDropTarget,
                            onSquareTap: { row, col in
                                handleSquareTap(row: row, col: col)
                            }
                        )
                    }
                    .frame(maxHeight: boardWidth)

                    // Error message
                    if let error = engine.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    // Last move score
                    if let score = engine.lastMoveScore {
                        Text("Last move: +\(score) pts")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Spacer(minLength: 4)

                    if engine.gameState.isGameOver {
                        gameOverView
                    } else {
                        // Waiting indicator
                        if !engine.isLocalPlayerTurn {
                            Text("Waiting for opponent — plan your next move!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        // Rack (always visible when game is active)
                        RackView(
                            tiles: localPlayerRack,
                            selectedTileID: engine.isLocalPlayerTurn ? selectedTile?.id : nil,
                            draggedTileID: rackDraggedTileID,
                            dropTargetIndex: rackDropTargetIndex,
                            onTileTap: { tile in
                                guard engine.isLocalPlayerTurn else { return }
                                if selectedTile?.id == tile.id {
                                    selectedTile = nil
                                } else {
                                    selectedTile = tile
                                }
                            }
                        )

                        if engine.isLocalPlayerTurn {
                            // Full controls when it's your turn
                            ControlsView(
                                hasPendingTiles: !engine.pendingPlacements.isEmpty,
                                canExchange: engine.gameState.tileBag.count >= ScrabbleConstants.rackSize,
                                isGameOver: engine.gameState.isGameOver,
                                onSubmit: handleSubmit,
                                onRecall: {
                                    engine.recallAllTiles()
                                    selectedTile = nil
                                },
                                onShuffle: { engine.shuffleRack() },
                                onPass: { showPassConfirm = true },
                                onExchange: { showExchange = true }
                            )
                        } else {
                            // Just shuffle when waiting
                            Button(action: { shuffleLocalPlayerRack() }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "shuffle")
                                    Text("Shuffle")
                                        .font(.caption2)
                                }
                            }
                            .buttonStyle(.bordered)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Floating dragged tile overlay
                if dragState.isDragging, let tile = dragState.draggedTile {
                    TileView(tile: tile, isPending: true, size: 44)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                        .position(dragState.dragLocation)
                        .allowsHitTesting(false)
                        .animation(nil, value: dragState.dragLocation)
                }
            }
            .coordinateSpace(name: "gameArea")
            .onPreferenceChange(BoardSquareFrameKey.self) { frames in
                dragState.boardFrames = frames
            }
            .onPreferenceChange(RackSlotFrameKey.self) { frames in
                dragState.rackFrames = frames
            }
            // Single unified drag gesture on the entire game area
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("gameArea"))
                    .onChanged { value in
                        if !dragState.isDragging {
                            // Try to start a drag from whatever is under the start point
                            tryStartDrag(at: value.startLocation)
                        }
                        if dragState.isDragging {
                            dragState.updateDrag(location: value.location)
                        }
                    }
                    .onEnded { _ in
                        if dragState.isDragging {
                            handleDragEnd()
                        }
                    }
            )
        }
        .sheet(isPresented: $showExchange) {
            ExchangeSheetView(
                rack: engine.currentPlayerRack,
                isPresented: $showExchange,
                onConfirm: { tiles in
                    let playerName = engine.gameState.currentPlayer.name
                    engine.exchangeTiles(tiles)
                    let caption = MessageComposer.captionForExchange(playerName: playerName, count: tiles.count)
                    let subcaption = MessageComposer.subcaption(state: engine.gameState)
                    sendAction.send(caption: caption, subcaption: subcaption)
                }
            )
        }
        .sheet(isPresented: $engine.showBlankPicker) {
            BlankPickerView(
                isPresented: $engine.showBlankPicker,
                onLetterSelected: { letter in
                    engine.assignBlankAndPlace(letter: letter)
                }
            )
        }
        .alert("Pass Turn?", isPresented: $showPassConfirm) {
            Button("Pass", role: .destructive) {
                let playerName = engine.gameState.currentPlayer.name
                engine.passTurn()
                let caption = MessageComposer.captionForPass(playerName: playerName)
                let subcaption = MessageComposer.subcaption(state: engine.gameState)
                sendAction.send(caption: caption, subcaption: subcaption)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to pass your turn?")
        }
    }

    // MARK: - Computed properties

    /// The local player's rack, regardless of whose turn it is
    private var localPlayerRack: [Tile] {
        guard let idx = engine.localPlayerIndex else { return engine.currentPlayerRack }
        return engine.gameState.players[idx].rack
    }

    /// The player index for the local player's rack
    private var localPlayerRackIndex: Int {
        engine.localPlayerIndex ?? engine.gameState.currentPlayerIndex
    }

    private var pendingPositionSet: Set<String> {
        Set(engine.pendingPlacements.map { "\($0.row),\($0.col)" })
    }

    private var boardDropTarget: (row: Int, col: Int)? {
        guard dragState.isDragging, case .board(let row, let col) = dragState.dropTarget else {
            return nil
        }
        return (row, col)
    }

    private var rackDraggedTileID: UUID? {
        guard dragState.isDragging else { return nil }
        return dragState.draggedTile?.id
    }

    private var rackDropTargetIndex: Int? {
        guard dragState.isDragging, case .rack(let index) = dragState.dropTarget else {
            return nil
        }
        return index
    }

    // MARK: - Unified drag handling

    private func tryStartDrag(at location: CGPoint) {
        guard !engine.gameState.isGameOver else { return }

        // Check rack tiles — allowed even when waiting for opponent (for reordering)
        let rack = localPlayerRack
        for (index, frame) in dragState.rackFrames {
            if frame.contains(location) && index < rack.count {
                let tile = rack[index]
                selectedTile = nil
                dragState.startDrag(tile: tile, source: .rack(index: index), location: location)
                return
            }
        }

        // Check pending board tiles — only when it's our turn
        guard engine.isLocalPlayerTurn else { return }
        for (key, frame) in dragState.boardFrames {
            if frame.contains(location) {
                let parts = key.split(separator: ",")
                if parts.count == 2, let row = Int(parts[0]), let col = Int(parts[1]) {
                    if let placement = engine.pendingPlacements.first(where: { $0.row == row && $0.col == col }) {
                        engine.removePlacedTile(at: row, col: col)
                        var tile = placement.tile
                        if tile.isBlank { tile.assignedLetter = nil }
                        dragState.startDrag(tile: tile, source: .board(row: row, col: col), location: location)
                        return
                    }
                }
            }
        }
    }

    private func handleDragEnd() {
        guard let result = dragState.endDrag() else { return }
        let tile = result.tile
        let source = result.source
        let target = result.target

        let rackIdx = localPlayerRackIndex

        switch target {
        case .board(let row, let col):
            // Only allow board drops on our turn
            if engine.isLocalPlayerTurn && !engine.gameState.board.isOccupied(row: row, col: col) {
                engine.placeTile(tile, at: row, col: col)
            } else {
                returnTileToSource(tile: tile, source: source)
            }

        case .rack(let targetIndex):
            switch source {
            case .rack(let sourceIndex):
                // Rearrange within rack
                var rack = engine.gameState.players[rackIdx].rack
                guard sourceIndex < rack.count else { break }
                let moved = rack.remove(at: sourceIndex)
                let insertAt = min(targetIndex, rack.count)
                rack.insert(moved, at: insertAt)
                engine.gameState.players[rackIdx].rack = rack

            case .board:
                // Tile was already removed from board and returned to rack
                if let currentIndex = engine.gameState.players[rackIdx].rack.firstIndex(where: { $0.id == tile.id }) {
                    var rack = engine.gameState.players[rackIdx].rack
                    let moved = rack.remove(at: currentIndex)
                    let insertAt = min(targetIndex, rack.count)
                    rack.insert(moved, at: insertAt)
                    engine.gameState.players[rackIdx].rack = rack
                }
            }

        case .none:
            returnTileToSource(tile: tile, source: source)
        }
    }

    private func returnTileToSource(tile: Tile, source: DragSource) {
        switch source {
        case .rack:
            // Tile is still in rack — nothing to do
            break
        case .board(let row, let col):
            // Put it back where it was
            engine.placeTile(tile, at: row, col: col)
        }
    }

    private func shuffleLocalPlayerRack() {
        engine.gameState.players[localPlayerRackIndex].rack.shuffle()
    }

    // MARK: - Tap handling

    private func handleSquareTap(row: Int, col: Int) {
        guard !dragState.isDragging else { return }

        if engine.pendingPlacements.contains(where: { $0.row == row && $0.col == col }) {
            engine.removePlacedTile(at: row, col: col)
            return
        }

        if let tile = selectedTile {
            engine.placeTile(tile, at: row, col: col)
            selectedTile = nil
        }
    }

    private func handleSubmit() {
        let playerName = engine.gameState.currentPlayer.name
        let result = engine.submitMove()
        switch result {
        case .success(let move):
            selectedTile = nil
            let caption = MessageComposer.captionForMove(playerName: playerName, move: move)
            let subcaption = MessageComposer.subcaption(state: engine.gameState)
            sendAction.send(caption: caption, subcaption: subcaption)
        case .failure:
            break
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 8) {
            Text("Game Over!")
                .font(.title2.bold())

            let p0 = engine.gameState.players[0]
            let p1 = engine.gameState.players[1]
            if p0.score > p1.score {
                Text("\(p0.name) wins!")
                    .font(.headline)
                    .foregroundColor(.blue)
            } else if p1.score > p0.score {
                Text("\(p1.name) wins!")
                    .font(.headline)
                    .foregroundColor(.blue)
            } else {
                Text("It's a tie!")
                    .font(.headline)
            }

            Text("\(p0.score) - \(p1.score)")
                .font(.title3)
        }
        .padding()
    }
}
