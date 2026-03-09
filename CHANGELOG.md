# Changelog

All notable changes to the ConversaVoice Flutter app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-09

### Added - P0 Critical Fixes
- **API Authentication**: Added X-API-Key header to all requests for backend authentication
- **Singleton Pattern**: Implemented ApiClient singleton for consistent API configuration
- **Retry Logic**: Added exponential backoff retry mechanism for network failures
- **Deprecation Fixes**: Replaced 77 instances of deprecated `.withOpacity()` with `.withValues(alpha:)`
- **Loading Timeout UI**: Added 90-second timeout with cancel button and progress indicator
- **Code Cleanup**: Removed dead code files (api_service.dart, chat_screen.dart)

### Added - P1 Important Improvements
- **State Management**: Integrated Riverpod for reactive state management throughout the app
- **Offline Support**: Implemented scenario caching with 24-hour validity for graceful offline degradation
- **Scenario Filtering**: Added category and difficulty filters with color-coded badges
- **Voice Gender Fix**: Added voiceGender field to match persona gender with voice and avatar
- **Dependency Injection**: VoiceService and ApiClient now injectable via providers
- **Offline Banner**: Display offline mode indicator when using cached data

### Added - P2 Future Enhancements
- **Progress Tracking**: Complete simulation history with trend charts and statistics
  - Score trend line chart (last 10 simulations)
  - Skills breakdown across 5 competencies
  - Recent simulations list
  - Stats overview (total sims, avg score, grade A count)
- **Gamification**: Achievement system with 6 unlockable badges
  - 🎯 First Steps (complete first simulation)
  - 🏆 Expert Challenge (complete expert scenario)
  - 🔥 5-Day Streak (practice 5 days in a row)
  - 💙 Empathy Expert (avg empathy score ≥ 8)
  - 🧘 De-escalation Pro (avg de-escalation score ≥ 8)
  - ⭐ Perfect Score (achieve score of 10/10)
- **Streak Tracking**: Daily practice counter with persistence
- **Real-time Coaching**: Live contextual hints during simulations
  - Corrective hints for detected issues
  - Positive reinforcement for good techniques
  - Emotion-based guidance
- **Theme Toggle**: Dark/Light mode with persistent preference
- **Settings Screen**: Comprehensive app configuration
  - Theme toggle
  - Custom backend URL override
  - Clear scenario cache
  - Clear all progress (with confirmation)
  - App version display
  - Current backend URL display

### Changed
- **Home Screen**: Added "My Progress" button and Settings icon
- **Scenario List**: Integrated Riverpod providers, added offline mode banner
- **Active Simulation**: Added real-time coaching overlay and timeout handling
- **Feedback Screen**: Auto-saves progress results after each simulation
- **Main App**: Converted to ConsumerWidget with theme mode support

### Technical Improvements
- Added flutter_riverpod (2.6.1) for state management
- Added shared_preferences (2.3.4) for local storage
- Added fl_chart (0.69.2) for data visualization
- Implemented provider-based dependency injection
- Added retry helper with configurable attempts
- Improved error handling and user feedback
- Enhanced offline experience with caching

### Documentation
- Updated README with comprehensive feature documentation
- Added installation and configuration instructions
- Documented API endpoints and backend integration
- Included tech stack and project structure
- Added architectural decision records

## [Unreleased]

### Planned
- Empty state illustrations for better UX
- Widget tests for core components
- Leaderboard functionality
- Cloud sync for progress data
- Additional achievement badges
- Custom scenario builder integration
- SSE streaming for real-time responses

---

**Full Changelog**: https://github.com/Speech-Synthesis/ConversaApp/commits/karthik
