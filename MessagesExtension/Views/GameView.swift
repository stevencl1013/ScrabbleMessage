import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine
    @EnvironmentObject var sendAction: SendMessageAction
    @State private var selectedTile: Tile?
    @State private var showExchange = false
    @State private var showPassConfirm = false

    var body: some View {
        GeometryReader { geometry in
            let boardWidth = min(geometry.size.width - 8, geometry.size.height * 0.6)
            let squareSize = boardWidth / CGFloat(ScrabbleConstants.boardSize)

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

                if engine.isLocalPlayerTurn && !engine.gameState.isGameOver {
                    // Rack
                    RackView(
                        tiles: engine.currentPlayerRack,
                        selectedTileID: selectedTile?.id,
                        onTileTap: { tile in
                            if selectedTile?.id == tile.id {
                                selectedTile = nil
                            } else {
                                selectedTile = tile
                            }
                        }
                    )

                    // Controls
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
                } else if engine.gameState.isGameOver {
                    gameOverView
                } else {
                    Text("Waiting for opponent...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
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

    private var pendingPositionSet: Set<String> {
        Set(engine.pendingPlacements.map { "\($0.row),\($0.col)" })
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

    private func handleSquareTap(row: Int, col: Int) {
        // If tapping a pending tile, recall it
        if engine.pendingPlacements.contains(where: { $0.row == row && $0.col == col }) {
            engine.removePlacedTile(at: row, col: col)
            return
        }

        // If a tile is selected from the rack, place it
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
}
