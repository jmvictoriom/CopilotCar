import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Language
                Section {
                    Picker("Idioma", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                } header: {
                    Text("Idioma")
                } footer: {
                    Text("Cambia el idioma del reconocimiento de voz, la respuesta de la IA y la síntesis de voz.")
                }

                // API Key
                Section {
                    SecureField("API Key", text: $settings.geminiAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Google Gemini API")
                } footer: {
                    Text("Obtén tu clave gratuita en aistudio.google.com/apikey. Gratis: 15 peticiones/minuto.")
                }

                // Model
                Section {
                    Picker("Modelo", selection: $settings.geminiModel) {
                        ForEach(GeminiModel.allCases) { model in
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                Text(model.tierInfo)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Modelo de IA")
                } footer: {
                    Text("Modelo actual: \(settings.geminiModel.displayName). Los modelos \"Preview\" pueden ser inestables.")
                }

                // Voice
                Section {
                    VStack(alignment: .leading) {
                        Text("Velocidad de voz: \(String(format: "%.1f", settings.speechRate))")
                        Slider(value: $settings.speechRate, in: 0.1...0.75, step: 0.05)
                    }

                    Toggle("Modo manos libres", isOn: $settings.handsFreeMode)
                } header: {
                    Text("Voz")
                } footer: {
                    Text("En modo manos libres, la app vuelve a escuchar automáticamente después de cada respuesta.")
                }

                // Appearance
                Section("Apariencia") {
                    Toggle("Modo oscuro forzado", isOn: $settings.forceDarkMode)
                }

                // About
                Section("Acerca de") {
                    LabeledContent("Versión", value: "1.0.0")
                    LabeledContent("IA", value: settings.geminiModel.displayName)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}
