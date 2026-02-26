# Changelog

All notable changes to DriveMate will be documented in this file.

## [1.1.0] - 2026-02-26

### Added

#### iOS
- CarPlay entitlements file (`com.apple.developer.carplay-audio`)
- List template as CarPlay root with "Toca para hablar" action
- Voice control template push/pop on conversation state changes
- Real-time state observation in CarPlay (listening, processing, speaking)
- System images for CarPlay voice control states (waveform, brain, speaker)
- UIWindowSceneSessionRoleApplication scene configuration in Info.plist

#### Android
- Full Android Auto support via `androidx.car.app` library (v1.4.0)
- `DriveMateCarAppService` — Car App Service entry point
- `DriveMateCarSession` — session management for Android Auto
- `DriveMateCarScreen` — PaneTemplate UI with mic action and state display
- `ConversationManager` — shared service extracted from ViewModel for cross-component access
- Microphone vector drawable (`ic_mic.xml`) for car UI
- Car app service declaration in AndroidManifest.xml

### Changed

#### iOS
- `ConversationViewModel` is now a shared singleton via `DriveMateApp.sharedViewModel`
- `ContentView` receives ViewModel as parameter instead of creating its own
- `CarPlaySceneDelegate` uses shared ViewModel instead of a separate instance

#### Android
- `ConversationViewModel` now delegates to `ConversationManager` (thin wrapper)
- `DriveMateApp` initializes shared `ConversationManager` in `onCreate()`
- `ConversationState` enum moved from `viewmodel` to `service` package
- `automotive_app_desc.xml` changed from `voice` to `template` type

## [1.0.0] - 2026-02-24

### Added

#### iOS
- Initial iOS app with SwiftUI (iOS 17+)
- Voice conversation flow: speech-to-text, Gemini AI, text-to-speech
- Google Gemini API integration with conversation history (up to 20 messages)
- Support for 10 Gemini models (1.5 Flash to 3.1 Pro Preview)
- Multi-language support: Spanish, English, French, German, Portuguese
- Hands-free mode with continuous listening
- Animated pulsing microphone button with state-based colors
- Waveform audio visualization during listening/speaking
- Chat-style message bubbles with timestamps
- Settings screen with language, API key, model, voice speed, and dark mode
- CarPlay integration with CPVoiceControlTemplate
- Dark mode forced by default for night driving
- Silence detection (2s) for automatic speech end
- Error handling for rate limits, network errors, and missing API key
- Unit and integration test suite

#### Android
- Initial Android app with Jetpack Compose (API 26+)
- Voice conversation flow matching iOS feature parity
- Google Gemini API integration with identical conversation management
- Material 3 design system with dark/light theme support
- Animated pulsing microphone button with pulse ring effects
- Waveform audio visualization
- Chat message bubbles with timestamps
- Settings screen with dropdowns for language and model selection
- Navigation with Jetpack Navigation Compose
- Android Auto metadata configuration
- Runtime permission handling for microphone access
- Edge-to-edge display support
