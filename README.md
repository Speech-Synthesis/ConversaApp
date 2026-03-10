# ConversaVoice App 🎙️

A premium customer service training simulator built with Flutter. This application provides AI-powered voice simulations for training customer care representatives with real-time feedback and performance analytics.

## ✨ Features

### Core Training Features
- **AI-Powered Scenarios**: Multiple training scenarios with varying difficulty levels (Easy → Expert)
- **Voice Interaction**: Real-time voice recording, transcription, and AI responses
- **Live Coaching**: Real-time hints during conversations based on detected techniques and issues
- **Performance Analysis**: Detailed scoring across 5 dimensions (empathy, de-escalation, communication, problem-solving, efficiency)
- **Emotion Tracking**: Monitor customer emotion changes throughout the conversation

### Progress & Gamification
- **Progress Tracking**: Complete history of all simulations with trend charts
- **Achievement Badges**: 6 unlockable badges for milestones (First Steps, Expert Challenge, 5-Day Streak, etc.)
- **Streak Counter**: Track daily practice consistency
- **Skills Dashboard**: Visual breakdown of strengths across all competencies

### State Management & Reliability
- **Riverpod Integration**: Reactive state management throughout the app
- **Offline Mode**: Cached scenarios with graceful degradation when backend is unavailable
- **Retry Logic**: Automatic retry with exponential backoff for network failures
- **Loading Timeout UI**: 90-second timeout with cancel button and progress indicator

### UX Enhancements
- **Dark/Light Theme**: Toggle between themes with persistent preference
- **Scenario Filtering**: Filter by category and difficulty level
- **Custom Backend URL**: Override backend URL for local development/testing
- **Settings Screen**: Clear cache, clear progress, theme toggle, app version info

### Premium UI
- **Modern Design**: Glassmorphism effects, mesh gradients, smooth animations
- **Dark Theme**: Primary dark theme with optional light mode
- **Google Fonts**: Outfit font family throughout
- **Responsive Layout**: Optimized for mobile, tablet, and web

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) v3.41.2 or higher
- Android Studio / VS Code with Flutter extensions
- API key for backend authentication (set via environment variable)

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

3. **Configure Environment**
   Create a `.env` file in the project root:
   ```env
   API_SECRET_KEY=your_api_key_here
   ```

4. **Run the App**
   - **Web (Chrome)**:
     ```bash
     flutter run -d chrome --dart-define=API_SECRET_KEY=your_key
     ```
   - **Android Emulator**:
     ```bash
     flutter run --dart-define=API_SECRET_KEY=your_key
     ```

## 🔌 Backend Integration

The app connects to the ConversaVoice backend API:
## 🔌 Backend Integration

The app connects to the ConversaVoice backend API:

- **Production**: Deployed on Render (URL configured in `lib/core/config.dart`)
- **Local Development**: Override URL in Settings screen
- **Authentication**: All requests include `X-API-Key` header
- **Offline Support**: Scenarios cached locally with 24-hour validity

### API Endpoints Used
- `GET /api/health` - Backend health check
- `GET /api/scenarios` - Fetch available training scenarios
- `POST /api/simulations/start` - Start a new simulation session
- `POST /api/simulations/{session_id}/respond` - Send trainee response
- `POST /api/simulations/{session_id}/end` - End simulation
- `GET /api/simulations/{session_id}/analysis` - Get performance analysis
- `POST /api/voice/transcribe` - Transcribe audio to text
- `POST /api/voice/synthesize` - Generate AI voice response

## 🛠️ Tech Stack

- **Framework**: Flutter 3.41.2 & Dart 3.11.0
- **State Management**: Riverpod 2.6.1
- **Styling**: Google Fonts (Outfit), Flutter Animate
- **Charts**: FL Chart 0.69.2
- **Voice**: Just Audio, Record
- **Storage**: SharedPreferences, Flutter Secure Storage
- **HTTP Client**: http package with retry logic
- **UI**: Material Design 3

## 📁 Project Structure

```
lib/
├── core/              # Core utilities (API client, config, error handling)
├── features/          # Feature modules
│   ├── home/         # Home screen with health check
│   ├── simulation/   # Scenario list, active simulation, feedback
│   ├── progress/     # Progress tracking screen with charts
│   └── settings/     # App settings and configuration
├── models/           # Data models (Scenario, Analysis, ProgressResult, etc.)
├── providers/        # Riverpod providers for state management
├── services/         # Business logic (caching, progress tracking, voice)
└── widgets/          # Reusable UI components
```

## 🎯 Key Architectural Decisions

1. **Singleton Pattern**: ApiClient uses singleton to ensure consistent configuration
2. **Provider-Based DI**: All services injected via Riverpod providers
3. **Offline-First**: Scenarios cached locally for graceful degradation
4. **Retry Logic**: Exponential backoff for transient network failures
5. **Separation of Concerns**: Clear separation between UI, business logic, and data layers

## 📱 Screenshots

*(Screenshots coming soon)*

---

**Developed by the ConversaVoice Team**  
Training tomorrow's customer care professionals today.