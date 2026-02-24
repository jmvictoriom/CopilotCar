# Changelog

All notable changes to DriveMate will be documented in this file.

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
