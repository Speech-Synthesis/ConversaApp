# ConversaVoice App 🎙️

A premium, voice-enabled AI chat interface built with Flutter. This application serves as the frontend for the ConversaVoice system, providing a sleek, dark-themed UI for interacting with the AI.

## ✨ Features

- **Premium UI**: Modern dark theme with glassmorphism effects, mesh gradients, and smooth animations.
- **Smart Chat Interface**:
  - Real-time message bubbles with timestamps.
  - Interactive "Welcome" screen with suggestion chips.
  - Typing indicators and auto-scrolling.
- **Robust Networking**:
  - **Live Mode**: Connects to a local FastAPI backend for real AI responses.
  - **Demo Mode**: Automatically falls back to a mock simulation if the backend is unreachable, ensuring the UI is always testable.
- **Cross-Platform**: Designed for Android, iOS, and Web.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Latest Stable)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Speech-Synthesis/ConversaApp.git
   cd ConversaApp
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   - **Web (Chrome)**:
     ```bash
     flutter run -d chrome
     ```
   - **Android Emulator**:
     Ensure an emulator is running, then:
     ```bash
     flutter run
     ```

## 🔌 Backend Integration

By default, the app tries to connect to a generic local API backend.

- **Emulator URL**: `http://10.0.2.2:8000`
- **Web URL**: `http://127.0.0.1:8000`

You can modify the API configuration in `lib/api_service.dart`.

If no backend is running, the app will gracefully switch to **Demo Mode**, allowing you to explore the UI features without a server.

## 🛠️ Tech Stack

- **Framework**: Flutter & Dart
- **Styling**: Google Fonts (`Outfit`), Flutter Animate
- **Networking**: `http` package
- **Icons**: Material Design Icons

## 📱 Screenshots

*(Add your screenshots here)*

---
Developed by [Your Name/Organization]
