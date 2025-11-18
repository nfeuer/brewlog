# ⚡ Quick Start Guide

Get BrewLog running in 3 simple steps!

## Prerequisites
- Flutter SDK installed
- iOS Simulator or Android Emulator running (or physical device connected)

## 🚀 3-Step Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App
```bash
flutter run
```

That's it! 🎉

## What Happens on First Launch?

1. **Hive Database Initialized** - Local storage is set up
2. **Sample Data Generated** - 3 coffee bags with 12 cups are created automatically
3. **User Profile Created** - A default free user account is created

You can immediately explore all features with the pre-loaded sample data!

## Exploring Features

### Sample Data Included
- **Ethiopian Yirgacheffe** - 5 cups with fruity, floral notes
- **Colombian Huila** - 4 cups with balanced, caramel sweetness
- **Sumatra Mandheling** - 3 cups with bold, earthy character

### Things to Try
1. **Switch View Modes** - Try Grid, List, and Rolodex views
2. **Add a New Cup** - Tap "New Cup" on any bag
3. **Create a New Bag** - Tap the "New Bag" FAB on home screen
4. **Check Statistics** - View your profile to see stats
5. **Change Rating Scale** - Try 1-5 stars, 1-10, or 1-100 scales
6. **Take Photos** - Add photos to your cups
7. **Mark Best Cup** - Star your favorite recipe

## No Internet Required!

The app works completely offline. All your data is stored locally on your device.

## Want Premium Features?

To enable cloud sync and QR code sharing:
1. See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for Firebase setup
2. Configure Firebase for your project
3. Upgrade to Premium in the app

## Troubleshooting

### Error: "Cannot find type adapter"
You forgot step 2. Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "No connected devices"
Start an emulator or connect a physical device, then run `flutter run` again.

### Photos not working
On iOS, the app needs camera permissions. Allow permissions when prompted.

### Want to reset data?
Delete and reinstall the app, or use the app's data management features (coming soon).

## Next Steps

- Read the full [README.md](README.md) for more details
- Check [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for advanced setup
- See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for Firebase configuration

## Development Mode

For continuous code generation during development:
```bash
flutter pub run build_runner watch
```

This will automatically regenerate files when you modify models.

---

**Enjoy tracking your coffee journey! ☕️**
