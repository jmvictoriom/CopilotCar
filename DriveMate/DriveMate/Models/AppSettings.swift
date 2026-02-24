import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es-ES"
    case english = "en-US"
    case french = "fr-FR"
    case german = "de-DE"
    case portuguese = "pt-BR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        }
    }

    var systemPromptLanguage: String {
        switch self {
        case .spanish: return "español"
        case .english: return "English"
        case .french: return "français"
        case .german: return "Deutsch"
        case .portuguese: return "português"
        }
    }
}

enum GeminiModel: String, CaseIterable, Identifiable {
    case flash15 = "gemini-1.5-flash"
    case pro15 = "gemini-1.5-pro"
    case flash20 = "gemini-2.0-flash"
    case flashLite20 = "gemini-2.0-flash-lite"
    case flash25 = "gemini-2.5-flash"
    case flashLite25 = "gemini-2.5-flash-lite"
    case pro25 = "gemini-2.5-pro"
    case flash3 = "gemini-3-flash-preview"
    case pro3 = "gemini-3-pro-preview"
    case pro31 = "gemini-3.1-pro-preview"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flash15: return "Gemini 1.5 Flash"
        case .pro15: return "Gemini 1.5 Pro"
        case .flash20: return "Gemini 2.0 Flash"
        case .flashLite20: return "Gemini 2.0 Flash Lite"
        case .flash25: return "Gemini 2.5 Flash"
        case .flashLite25: return "Gemini 2.5 Flash Lite"
        case .pro25: return "Gemini 2.5 Pro"
        case .flash3: return "Gemini 3 Flash (Preview)"
        case .pro3: return "Gemini 3 Pro (Preview)"
        case .pro31: return "Gemini 3.1 Pro (Preview)"
        }
    }

    var apiPath: String {
        "models/\(rawValue):generateContent"
    }

    var tierInfo: String {
        switch self {
        case .flash15: return "Gratuito - Estable"
        case .pro15: return "Gratuito - Estable"
        case .flash20: return "Gratuito - Recomendado"
        case .flashLite20: return "Gratuito - Ultra rápido"
        case .flash25: return "Gratuito - Mejor calidad/velocidad"
        case .flashLite25: return "Gratuito - Ligero"
        case .pro25: return "Gratuito - Máxima calidad"
        case .flash3: return "Preview - Nueva generación"
        case .pro3: return "Preview - Nueva generación"
        case .pro31: return "Preview - Lo más nuevo"
        }
    }
}

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "language") }
    }

    var geminiAPIKey: String {
        didSet { defaults.set(geminiAPIKey, forKey: "geminiAPIKey") }
    }

    var geminiModel: GeminiModel {
        didSet { defaults.set(geminiModel.rawValue, forKey: "geminiModel") }
    }

    var speechRate: Float {
        didSet { defaults.set(speechRate, forKey: "speechRate") }
    }

    var handsFreeMode: Bool {
        didSet { defaults.set(handsFreeMode, forKey: "handsFreeMode") }
    }

    var forceDarkMode: Bool {
        didSet { defaults.set(forceDarkMode, forKey: "forceDarkMode") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let langRaw = defaults.string(forKey: "language") ?? AppLanguage.spanish.rawValue
        self.language = AppLanguage(rawValue: langRaw) ?? .spanish
        self.geminiAPIKey = defaults.string(forKey: "geminiAPIKey") ?? ""
        let modelRaw = defaults.string(forKey: "geminiModel") ?? GeminiModel.flash20.rawValue
        self.geminiModel = GeminiModel(rawValue: modelRaw) ?? .flash20
        self.speechRate = defaults.object(forKey: "speechRate") as? Float ?? 0.5
        self.handsFreeMode = defaults.bool(forKey: "handsFreeMode")
        self.forceDarkMode = defaults.object(forKey: "forceDarkMode") as? Bool ?? true
    }
}
