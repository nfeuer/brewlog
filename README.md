# BrewLog - Coffee Tracking App

A comprehensive mobile-first coffee tracking application built with Flutter and Firebase. Track your brewing experiments, recipes, and coffee bean collections with an offline-first architecture.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/Riverpod-00ADD8?style=flat&logo=flutter&logoColor=white)

## 🌟 Features

### Core Features (All Users)
- ✅ **Coffee Bag Management** - Track multiple coffee bags with detailed information
- ✅ **Cup/Brew Tracking** - Record detailed brewing parameters and tasting notes
- ✅ **Multiple View Modes** - Grid, List, and Rolodex views
- ✅ **Rating System** - Flexible rating scales (1-5 stars, 1-10, 1-100)
- ✅ **Statistics Dashboard** - Track your coffee journey with comprehensive stats
- ✅ **Photo Management** - Capture and store photos of bags and brews
- ✅ **Offline-First** - Full functionality without internet connection
- ✅ **Sample Data** - Automatically generated test data for exploring features

### Premium Features (Paid Users)
- 🔒 **Cloud Sync** - Backup and sync across devices via Firebase
- 🔒 **QR Code Sharing** - Share your favorite recipes with other users
- 🔒 **Multi-Device Access** - Access your data on multiple devices
- 🔒 **Web Access** - View and manage your collection on the web

## 📱 Screenshots

*(Screenshots would go here once the app is running)*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK 3.0 or higher
- iOS/Android development environment set up
- Firebase account (optional, for premium features)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd brewlog
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

The app will automatically generate sample data on first launch!

## 📚 Documentation

**For Developers:**
- **[CODEBASE_GUIDE.md](CODEBASE_GUIDE.md)** - Comprehensive architecture overview and developer guide
  - Quick start for new developers
  - Architecture patterns and data flow
  - Directory structure and file purposes
  - Adding new features guide
  - Common tasks reference

**For Setup & Deployment:**
- **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - Detailed development setup and Firebase configuration
- **[BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)** - Build commands and troubleshooting
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute quick start guide

**For Features & Implementation:**
- **[AUTHENTICATION_IMPLEMENTATION.md](AUTHENTICATION_IMPLEMENTATION.md)** - Authentication system details
- **[FIREBASE_BACKEND_ACTIVATED.md](FIREBASE_BACKEND_ACTIVATED.md)** - Firebase integration status
- **[PREMIUM_FEATURES_ROADMAP.md](PREMIUM_FEATURES_ROADMAP.md)** - Premium features roadmap

All code files include comprehensive inline documentation with DartDoc comments explaining:
- Class purposes and responsibilities
- Method functionality and parameters
- Usage examples
- Architecture patterns

## 📖 Detailed Setup Instructions

For comprehensive setup instructions including Firebase configuration, see [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md).

## 🏗️ Project Structure

```
brewlog/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models with Hive adapters
│   │   ├── user_profile.dart
│   │   ├── coffee_bag.dart
│   │   ├── cup.dart
│   │   └── shared_cup.dart
│   ├── providers/                # Riverpod state management
│   │   ├── user_provider.dart
│   │   ├── bags_provider.dart
│   │   ├── cups_provider.dart
│   │   └── shared_cups_provider.dart
│   ├── services/                 # Business logic services
│   │   ├── database_service.dart
│   │   ├── firebase_service.dart
│   │   ├── photo_service.dart
│   │   └── sample_data_service.dart
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── bag_detail_screen.dart
│   │   ├── cup_card_screen.dart
│   │   ├── profile_screen.dart
│   │   └── shared_tab.dart
│   ├── widgets/                  # Reusable UI components
│   │   ├── bag_card.dart
│   │   ├── cup_summary_card.dart
│   │   └── rating_input.dart
│   └── utils/                    # Constants and helpers
│       ├── constants.dart
│       ├── helpers.dart
│       └── theme.dart
├── test/                         # Unit and widget tests
├── assets/                       # Images and resources
└── pubspec.yaml                  # Dependencies
```

## 🔑 Key Technologies

- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management solution
- **Hive** - Fast, lightweight local database
- **Firebase** - Cloud backend (optional)
  - Firestore - Cloud database
  - Storage - File storage
  - Authentication - User management
- **image_picker** - Photo capture and selection
- **qr_flutter** - QR code generation
- **mobile_scanner** - QR code scanning

## 💾 Data Models

### Coffee Bag
Stores information about each coffee bag:
- Basic info (name, roaster, custom title)
- Coffee details (farmer, variety, elevation, aroma)
- Purchase tracking (date, price, size)
- Statistics (total cups, average score, best cup)

### Cup (Brew)
Records each brewing session:
- Brew parameters (type, grind, temperature, ratio)
- Timing (brew time, bloom time)
- Rating (stored in all three scales)
- Tasting notes and flavor tags
- Photos
- Sharing information

### User Profile
Manages user preferences and statistics:
- User info (username, email, subscription status)
- Preferences (rating scale, view mode, visible fields)
- Statistics (total cups, grams used, cups by brew type)

## 🎨 User Interface

### Home Screen
- Tab-based navigation (My Bags | Shared)
- Three view modes:
  - **Grid** - 2-column card layout
  - **List** - Detailed single-column view
  - **Rolodex** - Animated carousel view
- Search and sort functionality
- Quick access to create new bags

### Bag Detail Screen
- Bag information and statistics
- Swipeable horizontal list of cups
- Quick actions (New Cup, View Best Cup)
- Visual summary of brewing history

### Cup Card Screen
- Comprehensive data entry form
- Collapsible sections for organization
- Photo gallery
- Rating input adapted to user preference
- Flavor tag selection
- Field visibility management

### Profile Screen
- User statistics dashboard
- Brew type breakdown chart
- Settings (rating scale, view preference)
- Premium upgrade information

## 🔄 Offline-First Architecture

The app is designed to work seamlessly without internet:

1. **Free Users**: All data stored locally in Hive database
2. **Paid Users**: Local database + Firebase cloud sync
3. **Automatic Sync**: Data syncs when connection is available
4. **No Data Loss**: All operations work offline and sync later

## 📊 Sample Data

On first launch, the app generates realistic sample data:
- 3 coffee bags (Ethiopian, Colombian, Sumatran)
- 12 cups with varied brewing parameters
- Realistic ratings and tasting notes
- Sample statistics

This helps you explore all features before adding your own data!

## 🔐 Firebase Setup (Optional)

Premium features require Firebase configuration:

1. Create a Firebase project
2. Add iOS/Android apps
3. Download and add configuration files
4. Enable Firestore, Storage, and Authentication
5. See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for details

**Note**: The app runs perfectly without Firebase in local-only mode.

## 🧪 Testing

Run tests with:
```bash
flutter test
```

Build for release:
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🎯 Roadmap

### Phase 1: MVP ✅
- [x] Local database with Hive
- [x] Core UI screens
- [x] Photo management
- [x] Statistics tracking
- [x] Multiple view modes

### Phase 2: Enhanced UX ✅
- [x] Search and sorting
- [x] Rating system with multiple scales
- [x] Field visibility management
- [x] Copy cup functionality

### Phase 3: Premium Features 🚧
- [ ] Firebase authentication
- [ ] Cloud sync implementation
- [ ] Payment integration
- [ ] QR code sharing with scanning

### Phase 4: Advanced Features 📋
- [ ] Export data (CSV/PDF)
- [ ] Brew timers
- [ ] Notifications
- [ ] Web app for paid users

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Coffee community for inspiration
- Flutter team for amazing framework
- Riverpod for elegant state management
- Firebase for cloud infrastructure

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Happy Brewing! ☕️**
