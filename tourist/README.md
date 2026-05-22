# TravelTrek Tourist Mobile App

This is the Flutter-based cross-platform mobile application for tourists. It provides offline tracking, multi-layer SOS activation, digital tourist IDs, and background synchronization features.

## 📁 Architecture Overview

The app uses **Clean Architecture** combined with **Feature-First Organization** to ensure features are self-contained, testable, and can be developed simultaneously.

```text
lib/
├── main.dart                       # App entry point & initialization
├── core/                           # Shared infrastructure & utilities
│   ├── constants/                  # Colors, dimensions, asset keys
│   ├── database/                   # Hive & SQLite database helpers
│   ├── errors/                     # Exceptions & failure types
│   ├── network/                    # API clients & WebSocket managers
│   └── theme/                      # App theme data
└── features/                       # Self-contained modules (domain-driven)
    ├── auth/                       # KYC verification & registration
    ├── contacts/                   # Emergency contacts management
    ├── home/                       # User profile, safety score, quick SOS access
    ├── itinerary/                  # Travel route planner & tracker
    ├── map/                        # Geo-fencing & real-time tracking
    ├── settings/                   # App configurations & preferences
    └── sos/                        # SOS broadcast managers (WiFi/Data, SMS, BLE, Audio)
        ├── data/
        ├── domain/
        └── presentation/
```

### Clean Architecture Layers per Feature
Each complex feature directory can be split into three layers:
1. **Data Layer**: Responsible for data sources (remote API, local DB), mapping JSON models, and repository implementations.
2. **Domain Layer**: Contains business logic, domain entities (pure Dart models), and repository interfaces.
3. **Presentation Layer**: UI elements (Widgets, Pages) and state management (Riverpod Providers).

## 🚀 Getting Started

1. Set up the Flutter SDK: [Flutter Setup](https://docs.flutter.dev/get-started/install)
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Generate code (for Hive JSON generators):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```
