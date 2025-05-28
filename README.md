# Gamestagram

A Flutter-based social gaming platform that allows users to discover, play, and interact with web-based games.

## Features

- **Game Discovery**: Browse through 589+ games across 27 different categories
- **Social Interactions**: Like, comment, save, and share games
- **User Authentication**: Register and login with persistent sessions
- **Deep Linking**: Share specific games via custom URLs
- **WebView Gaming**: Play games directly within the app
- **Responsive UI**: Modern dark theme with glassmorphism effects
- **Offline Fallback**: Built-in offline games when network issues occur

## Network & SSL Error Handling

The app includes robust error handling for network connectivity and SSL certificate issues:

### SSL Certificate Issues
- **Automatic Fallback**: When SSL handshake fails, the app gracefully falls back to placeholder content
- **User-Friendly Messages**: Clear error messages explain SSL certificate problems
- **Continued Functionality**: Games remain playable even when images fail to load due to SSL issues

### Connection Error Handling
- **Timeout Management**: 10-second connection timeout with 30-second idle timeout
- **Error Classification**: Distinguishes between SSL errors, connection timeouts, and network unavailability
- **Visual Feedback**: Different icons and messages for different error types
- **Offline Games**: Automatic fallback to built-in HTML5 games when external URLs fail

### Development vs Production
- **Development Mode**: Relaxed SSL verification for testing with self-signed certificates
- **Production Ready**: Configurable for strict SSL validation in production environments

## Game Database

The app now uses a comprehensive JSON-based game database with:

- **589 total games** across **27 categories**
- Each game includes: ID, title, description, image URL, game URL, and genre
- Categories include: Action, Adventure, Arcade, Sports, Puzzle, Strategy, and more
- Games are loaded from `assets/games.json` for better performance and maintainability

### Game Categories Breakdown

| Category | Games | Category | Games |
|----------|-------|----------|-------|
| Action | 20 | Adventure | 23 |
| Arcade | 22 | Baseball | 23 |
| Basketball | 23 | Board Games | 21 |
| Boxing | 22 | Bubble Shooter | 22 |
| Card | 22 | Christmas | 21 |
| Clicker | 21 | Cooking | 22 |
| Fighting | 25 | Flying | 20 |
| Football | 21 | Golf | 21 |
| Mahjong | 22 | Platform | 20 |
| Puzzle | 22 | Racing | 21 |
| Shooter | 22 | Simulation | 20 |
| Space | 24 | Sports | 20 |
| Strategy | 20 | Survival | 24 |
| Tower Defense | 25 | | |

## Project Structure

```
lib/
├── application/
│   └── view_models/          # State management (Provider pattern)
│       ├── auth_view_model.dart
│       └── game_view_model.dart
├── data/
│   └── models/               # Data models
│       ├── game_model.dart
│       ├── user_model.dart
│       └── interaction_model.dart
├── presentation/
│   ├── screens/              # UI screens
│   │   ├── welcome_screen.dart
│   │   ├── home_screen.dart
│   │   ├── game_details_screen.dart
│   │   └── ...
│   └── widgets/              # Reusable UI components
│       ├── game_frame_widget.dart
│       └── comment_panel_widget.dart
├── services/                 # Business logic and data services
│   ├── auth_service.dart
│   ├── game_service.dart
│   └── social_service.dart
└── main.dart                 # App entry point

assets/
└── games.json               # Game database
```

## Key Components

### GameService
- Loads games from JSON asset file
- Provides caching for better performance
- Supports search, filtering by genre, and pagination
- Methods: `fetchGames()`, `getGameById()`, `searchGames()`, etc.

### GameFrameWidget
- Comprehensive game display widget
- WebView-based game playback with lifecycle management
- Social interaction buttons (like, comment, share, save)
- Full-view mode toggle for immersive browsing

### Deep Linking
- Custom URL scheme: `gamestagram://game/{gameId}`
- Automatic navigation to specific games
- Share functionality with deep links

## Getting Started

### Prerequisites
- Flutter SDK (>=3.7.2)
- Dart SDK
- iOS Simulator / Android Emulator or physical device

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd gamestagram
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Dependencies

- **provider**: State management
- **shared_preferences**: Local data persistence
- **google_fonts**: Custom typography
- **webview_flutter**: In-app web browsing
- **share_plus**: Social sharing functionality
- **app_links**: Deep linking support

## Architecture

The app follows a clean architecture pattern with:

- **Presentation Layer**: UI components and screens
- **Application Layer**: ViewModels for state management
- **Data Layer**: Models and data structures
- **Service Layer**: Business logic and external integrations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
