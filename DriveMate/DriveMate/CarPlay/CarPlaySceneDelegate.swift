import Foundation
import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var observationTask: Task<Void, Never>?
    private var viewModel: ConversationViewModel { DriveMateApp.sharedViewModel }

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        let listTemplate = makeListTemplate()
        interfaceController.setRootTemplate(listTemplate, animated: true, completion: nil)
        startObservingState()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        observationTask?.cancel()
        observationTask = nil
        self.interfaceController = nil
    }

    // MARK: - Templates

    private func makeListTemplate() -> CPListTemplate {
        let item = CPListItem(
            text: "Toca para hablar",
            detailText: "DriveMate - Tu copiloto de voz",
            image: UIImage(systemName: "mic.fill")
        )
        item.handler = { [weak self] _, completion in
            Task { @MainActor in
                self?.viewModel.toggleListening()
            }
            completion()
        }
        let section = CPListSection(items: [item])
        let template = CPListTemplate(title: "DriveMate", sections: [section])
        return template
    }

    private func makeVoiceControlTemplate() -> CPVoiceControlTemplate {
        CPVoiceControlTemplate(voiceControlStates: makeVoiceStates())
    }

    private func makeVoiceStates() -> [CPVoiceControlState] {
        let listeningState = CPVoiceControlState(
            identifier: "listening",
            titleVariants: ["Escuchando..."],
            image: UIImage(systemName: "waveform"),
            repeats: true
        )
        let processingState = CPVoiceControlState(
            identifier: "processing",
            titleVariants: ["Pensando..."],
            image: UIImage(systemName: "brain"),
            repeats: true
        )
        let speakingState = CPVoiceControlState(
            identifier: "speaking",
            titleVariants: ["Hablando..."],
            image: UIImage(systemName: "speaker.wave.2.fill"),
            repeats: false
        )
        return [listeningState, processingState, speakingState]
    }

    // MARK: - State Observation

    private func startObservingState() {
        observationTask = Task { @MainActor [weak self] in
            var previousState: ConversationState = .idle
            while !Task.isCancelled {
                guard let self else { return }
                let currentState = self.viewModel.state
                if currentState != previousState {
                    self.handleStateChange(from: previousState, to: currentState)
                    previousState = currentState
                }
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            }
        }
    }

    private func handleStateChange(from oldState: ConversationState, to newState: ConversationState) {
        guard let interfaceController else { return }

        switch newState {
        case .listening, .processing, .speaking:
            if oldState == .idle {
                let voiceTemplate = makeVoiceControlTemplate()
                interfaceController.pushTemplate(voiceTemplate, animated: true, completion: nil)
            }
            let stateId: String
            switch newState {
            case .listening: stateId = "listening"
            case .processing: stateId = "processing"
            case .speaking: stateId = "speaking"
            default: stateId = "listening"
            }
            if let voiceTemplate = interfaceController.topTemplate as? CPVoiceControlTemplate {
                voiceTemplate.activateVoiceControlState(withIdentifier: stateId)
            }
        case .idle:
            if oldState != .idle {
                interfaceController.popTemplate(animated: true, completion: nil)
            }
        }
    }
}
