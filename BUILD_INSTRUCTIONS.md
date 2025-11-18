# Build Instructions

## Important: Generate Hive Adapters First

Before you can run the app, you **must** generate Hive type adapters using build_runner.

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/models/user_profile.g.dart`
- `lib/models/coffee_bag.g.dart`
- `lib/models/cup.g.dart`
- `lib/models/shared_cup.g.dart`

### Step 3: Update main.dart

After generating the adapters, you need to uncomment the adapter registration in `lib/main.dart`:

```dart
// Uncomment these lines after running build_runner:
Hive.registerAdapter(UserProfileAdapter());
Hive.registerAdapter(UserStatsAdapter());
Hive.registerAdapter(CoffeeBagAdapter());
Hive.registerAdapter(CupAdapter());
Hive.registerAdapter(SharedCupAdapter());
```

### Step 4: Run the App
```bash
flutter run
```

## If You Get Errors

### "Cannot find type adapter" errors
This means the Hive adapters haven't been generated yet. Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Unresolved import" errors for .g.dart files
This is expected before running build_runner. The files will be created when you run the build_runner command.

### Build runner conflicts
If you see conflicts, use the `--delete-conflicting-outputs` flag:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Clean and rebuild
If issues persist:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Development Workflow

### Watch mode for continuous generation
During development, you can run build_runner in watch mode:
```bash
flutter pub run build_runner watch
```

This will automatically regenerate adapters when you modify model files.

### Clean generated files
To remove all generated files:
```bash
flutter pub run build_runner clean
```

## iOS/Android Specific Setup

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save coffee photos</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take coffee photos</string>
```

### Android Permissions
Permissions are automatically handled by the image_picker plugin.

## Building for Release

### Android
```bash
flutter build apk --release
# or for Play Store:
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### "MissingPluginException"
Run:
```bash
flutter clean
flutter pub get
```

### Photos not saving
- Check permissions in device settings
- Ensure photo_service has write access

### Firebase errors
If you haven't configured Firebase, the app will run in local-only mode. This is expected and the app will work normally without Firebase.

## Quick Start Commands

For a fresh setup:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

That's it! The app will launch with sample data ready to explore.
