import UIKit
import SwiftUI
import Messages

class MessagesViewController: MSMessagesAppViewController {

    private var engine: GameEngine?
    private var session: MSSession?
    private var hostingController: UIViewController?

    // MARK: - Lifecycle

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)

        let gameState: GameState
        if let message = conversation.selectedMessage, let url = message.url,
           let decoded = GameStateCoder.decode(from: url) {
            gameState = decoded
            session = message.session
        } else {
            gameState = GameState.newGame()
            session = MSSession()
        }

        let engine = GameEngine(gameState: gameState)

        // Map local participant to a player index
        let localID = conversation.localParticipantIdentifier.uuidString
        if engine.gameState.playerIdentifiers[0].isEmpty {
            engine.gameState.playerIdentifiers[0] = localID
            engine.localPlayerIndex = 0
        } else if engine.gameState.playerIdentifiers[0] == localID {
            engine.localPlayerIndex = 0
        } else if engine.gameState.playerIdentifiers[1].isEmpty {
            engine.gameState.playerIdentifiers[1] = localID
            engine.localPlayerIndex = 1
        } else if engine.gameState.playerIdentifiers[1] == localID {
            engine.localPlayerIndex = 1
        }

        self.engine = engine
        presentUI(for: presentationStyle, conversation: conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        guard let conversation = activeConversation else { return }
        presentUI(for: presentationStyle, conversation: conversation)
    }

    // MARK: - UI Presentation

    private func presentUI(for style: MSMessagesAppPresentationStyle, conversation: MSConversation) {
        // Remove existing hosted view
        if let existing = hostingController {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
            hostingController = nil
        }

        guard let engine = engine else { return }

        let view: AnyView
        if style == .compact {
            view = AnyView(
                CompactView(
                    gameState: engine.gameState,
                    isLocalPlayerTurn: engine.isLocalPlayerTurn
                )
                .onTapGesture {
                    self.requestPresentationStyle(.expanded)
                }
            )
        } else {
            view = AnyView(
                GameView(engine: engine)
                    .environmentObject(SendMessageAction(handler: { [weak self] caption, subcaption in
                        self?.sendMessage(caption: caption, subcaption: subcaption)
                    }))
            )
        }

        let hosting = UIHostingController(rootView: view)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    // MARK: - Message Sending

    private func sendMessage(caption: String, subcaption: String) {
        guard let engine = engine,
              let session = session,
              let conversation = activeConversation else { return }

        let message = MessageComposer.compose(
            state: engine.gameState,
            session: session,
            caption: caption,
            subcaption: subcaption
        )

        conversation.insert(message) { error in
            if let error = error {
                print("Failed to insert message: \(error.localizedDescription)")
            }
        }

        dismiss()
    }
}

// MARK: - Send Message Action

class SendMessageAction: ObservableObject {
    let handler: (String, String) -> Void

    init(handler: @escaping (String, String) -> Void) {
        self.handler = handler
    }

    func send(caption: String, subcaption: String) {
        handler(caption, subcaption)
    }
}
