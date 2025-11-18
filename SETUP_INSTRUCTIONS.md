# BrewLog Setup Instructions

## Prerequisites
- Flutter SDK (latest stable version)
- iOS/Android development environment
- Firebase account (for paid features - optional for local testing)

## Initial Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Hive Adapters
The project uses Hive for local storage. You need to generate type adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/models/user_profile.g.dart`
- `lib/models/coffee_bag.g.dart`
- `lib/models/cup.g.dart`
- `lib/models/shared_cup.g.dart`

### 3. Firebase Setup (Optional - for Paid Features)

#### A. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add iOS and Android apps to your Firebase project

#### B. Download Configuration Files

**For Android:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`

**For iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`

**For Web (Paid users only):**
1. Get your Firebase web configuration
2. Update `web/index.html` with Firebase config

#### C. Enable Firebase Services
In Firebase Console, enable:
- **Authentication**: Email/Password provider
- **Firestore Database**: Start in test mode (change to production rules later)
- **Storage**: Start in test mode (change to production rules later)

#### D. Update Firebase Configuration
If Firebase is NOT configured, the app will run in local-only mode automatically. To enable Firebase:

1. Uncomment Firebase initialization in `lib/main.dart`
2. Update `lib/services/firebase_service.dart` with your configuration

### 4. Running the App

#### Local-Only Mode (No Firebase)
```bash
flutter run
```

The app will automatically detect missing Firebase configuration and run in local-only mode with sample data.

#### With Firebase (Paid Features)
After completing Firebase setup:
```bash
flutter run
```

The app will sync with Firebase when internet is available.

## Project Structure

```
brewlog/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models with Hive adapters
│   ├── providers/                # Riverpod state management
│   ├── services/                 # Business logic services
│   ├── screens/                  # UI screens
│   ├── widgets/                  # Reusable UI components
│   └── utils/                    # Constants and helpers
├── test/                         # Unit and widget tests
├── assets/                       # Images and resources
└── pubspec.yaml                  # Dependencies
```

## Development Workflow

### Testing Local Features
1. Run app without Firebase configuration
2. App loads with sample data (3 coffee bags, multiple cups)
3. Test all features:
   - Creating/editing bags and cups
   - Photo capture
   - Statistics tracking
   - View modes (grid, list, rolodex)
   - Rating scales
   - Field visibility

### Testing Paid Features
1. Complete Firebase setup
2. Create test account in app
3. Test:
   - Cloud sync
   - QR code sharing
   - Multi-device access
   - Photo backup

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Hive Type Adapter Errors
If you see errors like "Cannot find type adapter":
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Initialization Errors
- Ensure configuration files are in correct locations
- Check that Firebase services are enabled in console
- Verify package name matches Firebase project

### Photo Picker Issues
- **iOS**: Add permissions to `ios/Runner/Info.plist`:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need access to your photo library to save coffee photos</string>
  <key>NSCameraUsageDescription</key>
  <string>We need access to your camera to take coffee photos</string>
  ```

- **Android**: Permissions are handled automatically by the plugin

### QR Scanner Issues
- **iOS**: Add camera permission to `Info.plist` (same as above)
- **Android**: Camera permission handled automatically

## Sample Data

When running without Firebase, the app generates sample data including:
- 3 coffee bags with different roasters
- 8-10 cups per bag with varied parameters
- Realistic ratings and tasting notes
- Sample statistics

## Payment Integration (Future)

To add subscription payments:

1. **iOS**: Set up StoreKit in App Store Connect
2. **Android**: Set up Google Play Billing
3. **Web**: Integrate Stripe
4. Update subscription logic in `lib/services/subscription_service.dart` (to be created)

## Firebase Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /bags/{bagId} {
      allow read, write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }

    match /cups/{cupId} {
      allow read, write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }

    // Shared cups can be read by anyone with the link
    match /shared/{sharedId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Architecture Notes

### Offline-First Design
- All data stored in Hive (local database)
- Free users: Local storage only
- Paid users: Local storage + Firebase sync
- Sync happens automatically when online

### State Management
- Using Riverpod for reactive state management
- Providers in `lib/providers/` directory
- Services handle business logic

### Photo Management
- Local photos: Stored in app documents directory
- Paid users: Uploaded to Firebase Storage
- Images compressed to 1024px max width

## Next Steps

1. Run `flutter pub get`
2. Run `flutter pub run build_runner build`
3. Run `flutter run` to test the app
4. Create Firebase project when ready to test paid features

## Support

For issues or questions:
- Check Flutter documentation: https://docs.flutter.dev/
- Firebase docs: https://firebase.flutter.dev/
- Hive docs: https://docs.hivedb.dev/
