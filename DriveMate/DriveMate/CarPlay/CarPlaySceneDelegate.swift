import Foundation
import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private let viewModel = ConversationViewModel()

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        presentVoiceControlTemplate()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Templates

    private func presentVoiceControlTemplate() {
        let voiceTemplate = CPVoiceControlTemplate(voiceControlStates: makeVoiceStates())
        interfaceController?.setRootTemplate(voiceTemplate, animated: true, completion: nil)
    }

    private func makeVoiceStates() -> [CPVoiceControlState] {
        let idleState = CPVoiceControlState(
            identifier: "idle",
            titleVariants: ["Toca para hablar"],
            image: nil,
            repeats: false
        )

        let listeningState = CPVoiceControlState(
            identifier: "listening",
            titleVariants: ["Escuchando..."],
            image: nil,
            repeats: true
        )

        let processingState = CPVoiceControlState(
            identifier: "processing",
            titleVariants: ["Pensando..."],
            image: nil,
            repeats: true
        )

        let speakingState = CPVoiceControlState(
            identifier: "speaking",
            titleVariants: ["Hablando..."],
            image: nil,
            repeats: false
        )

        return [idleState, listeningState, processingState, speakingState]
    }
}
