import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechRecognizer {
    var transcribedText: String = ""
    var isListening: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var onSpeechFinished: ((String) -> Void)?

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }

    func startListening(locale: String, onFinished: @escaping (String) -> Void) throws {
        stopListening()

        self.onSpeechFinished = onFinished
        self.transcribedText = ""

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        try configureAudioSession()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = text
                    self.resetSilenceTimer()
                }

                if result.isFinal {
                    self.finishListening(with: text)
                }
            }

            if let error {
                // Ignore cancellation errors from manual stop
                if (error as NSError).code != 216 {
                    self.finishListening(with: self.transcribedText)
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isListening = true
        }

        resetSilenceTimer()
    }

    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [
            .defaultToSpeaker,
            .allowBluetooth,
            .allowBluetoothA2DP
        ])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            let text = self.transcribedText
            if !text.isEmpty {
                self.finishListening(with: text)
            }
        }
    }

    private func finishListening(with text: String) {
        stopListening()
        if !text.isEmpty {
            onSpeechFinished?(text)
        }
        onSpeechFinished = nil
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case requestCreationFailed
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable: return "Reconocimiento de voz no disponible para este idioma."
            case .requestCreationFailed: return "No se pudo iniciar el reconocimiento de voz."
            case .notAuthorized: return "Permiso de reconocimiento de voz denegado."
            }
        }
    }
}
