import SwiftUI

struct ContentView: View {
    var viewModel: ConversationViewModel
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Messages
                messagesSection

                // Current transcription
                if !viewModel.currentTranscription.isEmpty || viewModel.speechRecognizer.isListening {
                    transcriptionBar
                }

                // Waveform
                if viewModel.state == .listening || viewModel.state == .speaking {
                    WaveformView(
                        isActive: true,
                        color: viewModel.state == .listening ? .red : .green
                    )
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Bottom controls
                bottomControls
            }
        }
        .preferredColorScheme(viewModel.settings.forceDarkMode ? .dark : nil)
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: viewModel.settings)
        }
        .onAppear {
            viewModel.requestPermissions()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DriveMate")
                    .font(.title2.bold())
                Text(viewModel.stateLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Messages

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("¡Hola! Soy DriveMate")
                .font(.title3.bold())
            Text("Tu copiloto de voz. Pulsa el micrófono\ny pregúntame lo que quieras.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Transcription

    private var transcriptionBar: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(.red)
            Text(viewModel.speechRecognizer.transcribedText.isEmpty
                 ? "..."
                 : viewModel.speechRecognizer.transcribedText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            PulsingMicButton(state: viewModel.state) {
                viewModel.toggleListening()
            }

            if !viewModel.messages.isEmpty {
                Button("Limpiar conversación") {
                    viewModel.clearConversation()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    ContentView(viewModel: ConversationViewModel())
}
