# DriveMate - Voice Copilot for Drivers

DriveMate is a voice-powered AI copilot for drivers. Speak naturally while driving and get concise, helpful responses read aloud. Powered by Google Gemini AI.

Available for **iOS** (SwiftUI + CarPlay) and **Android** (Jetpack Compose + Android Auto).

## Features

- **Voice-first interaction**: Tap the mic, speak, and get AI responses read aloud
- **Google Gemini AI**: Uses the free tier (15 requests/minute) — no cost to use
- **10 Gemini models**: From Gemini 1.5 Flash to Gemini 3.1 Pro Preview
- **Multi-language**: Spanish, English, French, German, Portuguese
- **Hands-free mode**: Continuous listening — the app re-listens after each response
- **Dark mode**: Forced dark theme for night driving
- **CarPlay / Android Auto**: Ready for in-car integration
- **No external dependencies**: Built entirely with native platform APIs
- **Offline-capable STT/TTS**: Speech recognition and synthesis work without internet (AI responses require connection)

## Project Structure

```
CopilotCar/
├── DriveMate/                  # iOS app (SwiftUI, iOS 17+)
│   ├── DriveMate.xcodeproj
│   └── DriveMate/
│       ├── Models/             # Message, AppSettings, GeminiModel
│       ├── Services/           # GeminiService, SpeechRecognizer, SpeechSynthesizer
│       ├── ViewModels/         # ConversationViewModel
│       ├── Views/              # ContentView, SettingsView, Components/
│       └── CarPlay/            # CarPlaySceneDelegate
├── DriveMateAndroid/           # Android app (Jetpack Compose, API 26+)
│   └── app/src/main/
│       └── java/com/drivemate/
│           ├── model/          # Message, AppSettings, AppLanguage, GeminiModel
│           ├── service/        # GeminiService, SpeechRecognizerService, SpeechSynthesizerService
│           ├── viewmodel/      # ConversationViewModel
│           └── ui/             # MainScreen, SettingsScreen, components/, theme/
├── README.md
├── CHANGELOG.md
└── USER_MANUAL.md
```

## Quick Start

### iOS

1. Open `DriveMate/DriveMate.xcodeproj` in Xcode 15+
2. Select your target device (iPhone or simulator)
3. Build and run (Cmd+R)
4. Go to Settings (gear icon) and enter your Gemini API key

### Android

1. Open `DriveMateAndroid/` in Android Studio Hedgehog+
2. Sync Gradle and build the project
3. Run on a device or emulator (API 26+)
4. Go to Settings and enter your Gemini API key

### Getting a Gemini API Key (Free)

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key and paste it in DriveMate Settings

The free tier includes **15 requests/minute** and **1,500 requests/day**.

## Tech Stack

| Feature | iOS | Android |
|---------|-----|---------|
| UI Framework | SwiftUI | Jetpack Compose |
| Design System | iOS Native | Material 3 |
| AI Backend | Google Gemini REST API | Google Gemini REST API |
| Speech-to-Text | Apple Speech Framework | Android SpeechRecognizer |
| Text-to-Speech | AVSpeechSynthesizer | Android TextToSpeech |
| Networking | URLSession | HttpURLConnection |
| Settings | UserDefaults | SharedPreferences |
| Car Integration | CarPlay (CPTemplate) | Android Auto |
| Min Version | iOS 17 | API 26 (Android 8.0) |

## Architecture

Both platforms follow the same architecture:

```
User speaks → SpeechRecognizer → ViewModel → GeminiService → ViewModel → SpeechSynthesizer → User hears
```

- **Model**: Data classes (Message, AppSettings, AppLanguage, GeminiModel)
- **Service**: Platform-specific implementations (Gemini API, STT, TTS)
- **ViewModel**: Orchestrates the conversation flow and manages state
- **View/UI**: Declarative UI (SwiftUI / Compose) driven by ViewModel state

## License

MIT License
