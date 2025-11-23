# BrewLog Codebase Guide

**Quick Start Guide for Developers**
This document provides a comprehensive overview of the BrewLog codebase architecture, helping you quickly understand how everything works without reading through all the code.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Directory Structure](#directory-structure)
3. [Data Flow](#data-flow)
4. [Core Concepts](#core-concepts)
5. [Key Files & Their Purposes](#key-files--their-purposes)
6. [State Management](#state-management)
7. [Data Models](#data-models)
8. [Services Layer](#services-layer)
9. [UI Layer](#ui-layer)
10. [Adding New Features](#adding-new-features)

---

## Architecture Overview

BrewLog follows a **clean architecture pattern** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│           UI Layer (Screens/Widgets)        │
│  - User interactions                        │
│  - Display logic only                       │
└─────────────────┬───────────────────────────┘
                  │ reads/writes
┌─────────────────▼───────────────────────────┐
│     State Management (Riverpod Providers)   │
│  - Business logic                           │
│  - State updates                            │
│  - Computed values                          │
└─────────────────┬───────────────────────────┘
                  │ calls
┌─────────────────▼───────────────────────────┐
│        Services Layer (Business Logic)      │
│  - DatabaseService (Hive)                   │
│  - FirebaseService (Cloud sync)             │
│  - ShareService (QR codes)                  │
│  - PhotoService (Images)                    │
└─────────────────┬───────────────────────────┘
                  │ operates on
┌─────────────────▼───────────────────────────┐
│         Data Models (Domain Objects)        │
│  - CoffeeBag, Cup, UserProfile             │
│  - DrinkRecipe, EquipmentSetup              │
│  - JSON serialization                       │
└─────────────────────────────────────────────┘
```

### Key Architectural Principles

1. **Offline-First**: All data stored in Hive locally first, Firebase is optional for paid users
2. **Reactive State**: Riverpod providers automatically update UI when data changes
3. **Type Safety**: Strong typing with Dart, enums for constants, null safety enabled
4. **Separation of Concerns**: Each layer has a single responsibility
5. **Dependency Injection**: Riverpod providers manage dependencies

---

## Directory Structure

```
lib/
├── main.dart                    # App entry point, initialization
│
├── models/                      # Data models (7 files)
│   ├── coffee_bag.dart          # Coffee bag data structure (31 fields)
│   ├── cup.dart                 # Brew/cup data structure (50+ fields)
│   ├── user_profile.dart        # User account and preferences
│   ├── drink_recipe.dart        # Drink recipes for coffee beverages
│   ├── equipment_setup.dart     # Equipment tracking
│   ├── shared_cup.dart          # Shared cups from QR codes
│   └── [model_name].g.dart     # Generated Hive adapters
│
├── providers/                   # Riverpod state management (6 files)
│   ├── bags_provider.dart       # Coffee bags state & filtering
│   ├── cups_provider.dart       # Brew tracking state
│   ├── user_provider.dart       # User profile state
│   ├── drink_recipes_provider.dart
│   ├── equipment_provider.dart
│   └── shared_cups_provider.dart
│
├── services/                    # Business logic layer (5 files)
│   ├── database_service.dart    # Hive local database operations
│   ├── firebase_service.dart    # Cloud sync & authentication
│   ├── share_service.dart       # QR code generation & deep links
│   ├── photo_service.dart       # Photo capture and storage
│   └── sample_data_service.dart # Debug data generation
│
├── screens/                     # UI screens (12 files)
│   ├── home_screen.dart         # Main tab navigation
│   ├── bag_detail_screen.dart   # Individual bag view
│   ├── cup_card_screen.dart     # Brew entry form (86KB!)
│   ├── profile_screen.dart      # User settings & stats
│   ├── bag_form_screen.dart     # Create/edit bag
│   ├── drink_recipe_book_screen.dart
│   ├── equipment_screen.dart
│   ├── equipment_form_screen.dart
│   ├── scan_qr_screen.dart      # QR code scanner
│   ├── shared_tab.dart          # Shared cups tab
│   └── auth/
│       ├── login_screen.dart
│       └── signup_screen.dart
│
├── widgets/                     # Reusable UI components (7 files)
│   ├── bag_card.dart            # Coffee bag display card
│   ├── cup_summary_card.dart    # Brew summary
│   ├── rating_input.dart        # Adaptive rating widget
│   ├── temperature_dial.dart    # Temperature selector
│   ├── pour_schedule_timer.dart # Pour-over timing
│   ├── photo_viewer.dart        # Image gallery
│   └── username_prompt_dialog.dart
│
└── utils/                       # Utilities & constants (3 files)
    ├── constants.dart           # Enums, default values, type IDs
    ├── theme.dart               # Material Design theme
    └── helpers.dart             # Helper functions

assets/                          # Images and resources
├── images/                      # App images
└── icons/                       # App icons

test/                            # Unit and widget tests
├── models/                      # Model tests
├── services/                    # Service tests
└── widgets/                     # Widget tests
```

---

## Data Flow

### User Creates a Coffee Bag

```
1. User fills form → BagFormScreen
2. Taps save → calls ref.read(bagsProvider.notifier).createBag(bag)
3. BagsNotifier → calls DatabaseService.createBag(bag)
4. DatabaseService → saves to Hive box as JSON
5. DatabaseService → updates user stats
6. BagsNotifier → reloads bags from database
7. Riverpod → automatically rebuilds UI
8. User sees new bag in HomeScreen
```

### User Records a Brew

```
1. User taps bag → BagDetailScreen
2. Taps "+" → CupCardScreen(mode: create)
3. Fills brew parameters → saves
4. CupsNotifier → calls DatabaseService.createCup(cup)
5. DatabaseService → saves cup, updates user stats, recalculates bag stats
6. UI automatically updates showing new cup count
```

### Data Syncs to Firebase (Premium)

```
1. User makes change → saved to Hive first
2. If user.isPaid → FirebaseService.syncToCloud()
3. FirebaseService → uploads to Firestore collection
4. On other device → FirebaseService detects change
5. Downloads → DatabaseService stores in Hive
6. Riverpod → rebuilds UI with synced data
```

---

## Core Concepts

### 1. Coffee Bags
A "bag" represents a physical bag of coffee beans you purchased. Each bag has:
- **Identity**: roaster, coffee name, custom title
- **Bean Details**: variety, processing method, roast level, elevation
- **Tracking**: purchase date, roast date, open date, finished date
- **Statistics**: total cups made, average score, best cup

### 2. Cups
A "cup" represents a single brew you made from a bag. Each cup has:
- **Basic Brew**: brew type, grind level, temperature, grams, volume, time
- **Advanced Parameters**: TDS, extraction yield, pressure, bloom, pour schedule
- **Rating**: Supports 3 scales (1-5, 1-10, 1-100) stored simultaneously
- **SCA Cupping**: 11-point professional cupping protocol
- **Environment**: room temp, humidity, altitude, time of day
- **Tasting**: notes, flavor tags, photos

### 3. Rating System
Users can rate brews on three different scales:
- **1-5 stars**: Quick, casual rating
- **1-10**: Medium granularity
- **1-100**: High precision for enthusiasts

All three values are stored simultaneously and auto-converted. User chooses preferred display scale.

### 4. Field Visibility
Users can customize which fields appear on cup cards:
- **Global defaults**: Set in user profile
- **Per-bag overrides**: Each bag can have custom visibility
- **Per-cup overrides**: Each cup can show/hide specific fields

### 5. View Modes
Coffee bags can be displayed in three ways:
- **Grid**: Card grid layout (default)
- **List**: Detailed list view
- **Rolodex**: Animated carousel/swiper

### 6. Equipment Setups
Users can save equipment configurations:
- Grinder (brand, model, type)
- Brewer (brand, model, filter type)
- Kettle (type, temperature control)
- Scale (brand, accuracy)
- Water (type, TDS)
- Marked as "default" to auto-populate new cups

### 7. Drink Recipes
Save and share coffee drink recipes:
- Base coffee (espresso, pour over, etc.)
- Milk type and amount
- Syrups and sweeteners
- Ice and other additions
- Instructions
- Usage tracking

### 8. Sharing (Premium)
QR code and deep link sharing:
- **Cups**: Share brew recipes via QR code
- **Drink Recipes**: Share drink recipes
- **Deep Links**: `brewlog://` URLs
- **Import**: Scan QR to add to your collection

---

## Key Files & Their Purposes

### main.dart
**Purpose**: Application entry point and initialization
**Key Responsibilities**:
- Initialize Hive database
- Initialize Firebase (optional)
- Set up deep link handling
- Generate sample data in debug mode
- Schedule username prompt for new users

**Important Notes**:
- Hive adapter registration is commented out until build_runner is run
- Firebase initialization is graceful (doesn't crash if not configured)
- Deep links use `brewlog://` scheme

### models/coffee_bag.dart
**Purpose**: Coffee bag data model
**Key Features**:
- 31 HiveFields for comprehensive coffee tracking
- JSON serialization for Firebase
- Enum-to-index conversion for BagStatus
- `copyWith()` for immutable updates
- `touch()` helper to update timestamps
- `displayTitle` getter with fallback

### models/cup.dart
**Purpose**: Brew/cup data model
**Key Features**:
- 50+ fields for advanced brewing
- Triple rating system (1-5, 1-10, 1-100)
- SCA cupping protocol (11 attributes)
- Conditional fields based on brew type
- Photo management
- Field visibility settings

### models/user_profile.dart
**Purpose**: User account and preferences
**Key Features**:
- Account info (username, email, isPaid, isAdmin)
- Preferences (rating scale, view mode)
- Statistics (cups made, grams used, brew type breakdown)
- Custom brew types
- Field visibility defaults
- Username prompt management

### services/database_service.dart
**Purpose**: Local database operations using Hive
**Pattern**: Singleton
**Key Responsibilities**:
- CRUD operations for all models
- Statistics calculation
- Relationship management (bags → cups)
- Cascade deletes
- Transaction-like operations

**Important Methods**:
- `initialize()`: Opens Hive boxes, creates default user
- `recalculateBagStats()`: Updates bag statistics from cups
- `recalculateUserStats()`: Rebuilds user stats from all data
- `clearAllData()`: Full database reset

### services/firebase_service.dart
**Purpose**: Cloud sync and authentication
**Status**: Methods stubbed, not fully active
**Key Responsibilities**:
- Firebase authentication (email/password)
- Firestore sync for bags, cups, recipes
- Cloud photo storage
- Real-time updates

**Important Notes**:
- Gracefully handles missing Firebase configuration
- Returns stub/mock data when not initialized
- Premium feature (only for paid users)

### services/share_service.dart
**Purpose**: QR code and deep link handling
**Key Features**:
- `encodeCup()`: Converts cup to QR-safe JSON
- `decodeCup()`: Parses QR data
- `encodeShareUrl()`: Creates brewlog:// URLs
- `parseDeepLink()`: Handles incoming links
- Version checking for future compatibility

### providers/bags_provider.dart
**Purpose**: Coffee bag state management
**Providers**:
- `bagsProvider`: All bags (StateNotifierProvider)
- `bagProvider`: Single bag by ID (Provider.family)
- `activeBagsProvider`: Active bags only
- `finishedBagsProvider`: Finished bags only
- `sortedBagsProvider`: Sorted by latest/alpha/score
- `searchedBagsProvider`: Filtered by search query

### providers/cups_provider.dart
**Purpose**: Cup state management
**Similar structure to bags_provider**:
- CRUD operations
- Filtering by bag
- Sorting and searching
- Statistics calculation

### screens/home_screen.dart
**Purpose**: Main app screen with tab navigation
**Structure**:
- AppBar with search and profile buttons
- TabBar: "My Bags" and "Shared"
- FAB for add/scan based on tab
- View mode toggle (grid/list/rolodex)
- Sort dropdown

### screens/cup_card_screen.dart
**Purpose**: Comprehensive brew entry form (largest file: 86KB)
**Sections**:
1. Basic brew parameters
2. Advanced brewing (conditional by brew type)
3. Environmental conditions
4. SCA cupping scores
5. Rating and tasting notes
6. Photos
7. Field visibility settings

**Important**: This is the most complex screen in the app

---

## State Management

BrewLog uses **Riverpod** for reactive state management.

### Provider Types Used

1. **Provider**: Immutable computed values
   ```dart
   final activeBagsProvider = Provider<List<CoffeeBag>>((ref) {
     final bags = ref.watch(bagsProvider);
     return bags.where((bag) => bag.status == BagStatus.active).toList();
   });
   ```

2. **StateProvider**: Simple mutable state
   ```dart
   final bagSortOptionProvider = StateProvider<BagSortOption>((ref) {
     return BagSortOption.latest;
   });
   ```

3. **StateNotifierProvider**: Complex mutable state
   ```dart
   final bagsProvider = StateNotifierProvider<BagsNotifier, List<CoffeeBag>>((ref) {
     final db = ref.watch(databaseServiceProvider);
     return BagsNotifier(db);
   });
   ```

4. **Provider.family**: Parameterized providers
   ```dart
   final bagProvider = Provider.family<CoffeeBag?, String>((ref, bagId) {
     final bags = ref.watch(bagsProvider);
     return bags.firstWhere((bag) => bag.id == bagId);
   });
   ```

### Reading Providers

```dart
// In a ConsumerWidget
final bags = ref.watch(bagsProvider);  // Rebuilds when bags change
final user = ref.read(userProfileProvider);  // One-time read

// Calling notifier methods
await ref.read(bagsProvider.notifier).createBag(newBag);
```

---

## Data Models

### Inheritance & Interfaces

All models extend `HiveObject` (not directly, but through adapters) and include:
- `toJson()`: Convert to Map for Firebase
- `fromJson()`: Create from Map
- `copyWith()`: Immutable updates
- `touch()`: Update timestamp

### Hive Type IDs

Each model has a unique typeId for Hive:
```dart
class HiveTypeIds {
  static const userProfile = 0;
  static const userStats = 1;
  static const coffeeBag = 2;
  static const cup = 3;
  static const sharedCup = 4;
  static const equipmentSetup = 8;
  static const drinkRecipe = 9;
}
```

### JSON Serialization

Models use manual JSON serialization (not json_serializable) because:
1. Need custom logic for enums
2. Handle DateTime conversions
3. Nested object serialization
4. Backward compatibility for migrations

---

## Services Layer

### DatabaseService (Singleton)

**Initialization**:
```dart
final db = DatabaseService();
await db.initialize();  // Opens boxes, creates default user
```

**CRUD Pattern**:
```dart
// Create
final id = await db.createBag(bag);

// Read
final bag = db.getBag(bagId);
final allBags = db.getAllBags();

// Update
await db.updateBag(updatedBag);

// Delete
await db.deleteBag(bagId);
```

**Relationship Management**:
- Deleting a bag also deletes all its cups (cascade)
- Creating a cup updates bag statistics
- Creating a cup updates user statistics
- Using a drink recipe increments its usage count

### FirebaseService (Singleton)

**Graceful Degradation**:
```dart
final firebaseService = FirebaseService();
final isAvailable = await firebaseService.initialize();
if (isAvailable) {
  // Use Firebase features
} else {
  // Continue in offline-only mode
}
```

### ShareService (Static Methods)

**QR Code Flow**:
```dart
// Encoding
final qrData = ShareService.encodeCup(cup);
// Generate QR widget with qrData

// Decoding
final cup = ShareService.decodeCup(scannedData);
if (cup != null) {
  // Import cup
}
```

---

## UI Layer

### Screen Navigation

BrewLog uses Navigator 1.0 with MaterialPageRoute:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BagDetailScreen(bagId: bag.id),
  ),
);
```

### ConsumerWidget Pattern

All screens and widgets that need state extend `ConsumerWidget` or `ConsumerStatefulWidget`:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bags = ref.watch(bagsProvider);
    return ListView(children: bags.map((bag) => BagCard(bag: bag)).toList());
  }
}
```

### Common UI Patterns

**Adaptive Widgets**: Widgets adapt to view mode
```dart
isGridView ? _buildGridView() : _buildListView()
```

**Conditional Rendering**: Premium features
```dart
if (user?.isPaid == true) {
  // Show premium features
}
```

**Loading States**: Futures with builders
```dart
FutureBuilder(
  future: loadData(),
  builder: (context, snapshot) {
    if (snapshot.hasData) return DataView();
    return CircularProgressIndicator();
  },
)
```

---

## Adding New Features

### 1. Adding a New Field to Cup

1. **Update Model** (`lib/models/cup.dart`):
   ```dart
   @HiveField(60)  // Use next available field ID
   String? myNewField;
   ```

2. **Update Constructor**: Add to constructor and copyWith()

3. **Update JSON**: Add to toJson() and fromJson()

4. **Run Build Runner**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Update UI**: Add input field in cup_card_screen.dart

6. **Update Visibility**: Add to constants.dart defaultFieldVisibility

### 2. Adding a New Provider

1. **Create File** (`lib/providers/my_feature_provider.dart`):
   ```dart
   final myFeatureProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
     final db = ref.watch(databaseServiceProvider);
     return MyNotifier(db);
   });

   class MyNotifier extends StateNotifier<MyState> {
     final DatabaseService _db;
     MyNotifier(this._db) : super(MyState.initial());

     Future<void> doSomething() async {
       // Business logic
       state = newState;
     }
   }
   ```

2. **Use in UI**:
   ```dart
   final myData = ref.watch(myFeatureProvider);
   ```

### 3. Adding a New Screen

1. **Create File** (`lib/screens/my_screen.dart`):
   ```dart
   class MyScreen extends ConsumerStatefulWidget {
     @override
     ConsumerState<MyScreen> createState() => _MyScreenState();
   }

   class _MyScreenState extends ConsumerState<MyScreen> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('My Feature')),
         body: // Your UI
       );
     }
   }
   ```

2. **Navigate to it**:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (context) => MyScreen()),
   );
   ```

### 4. Adding a New Service

1. **Create Singleton** (`lib/services/my_service.dart`):
   ```dart
   class MyService {
     static final MyService _instance = MyService._internal();
     factory MyService() => _instance;
     MyService._internal();

     Future<void> initialize() async {
       // Setup
     }

     Future<Result> doSomething() async {
       // Business logic
     }
   }
   ```

2. **Provide via Riverpod**:
   ```dart
   final myServiceProvider = Provider((ref) => MyService());
   ```

---

## Testing

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/models/coffee_bag_test.dart

# With coverage
flutter test --coverage
```

### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoffeeBag', () {
    test('should create with required fields', () {
      final bag = CoffeeBag(/* ... */);
      expect(bag.coffeeName, 'Test Coffee');
    });

    test('should serialize to JSON', () {
      final json = bag.toJson();
      final restored = CoffeeBag.fromJson(json);
      expect(restored.id, bag.id);
    });
  });
}
```

---

## Common Tasks Quick Reference

### Get Current User
```dart
final user = ref.watch(userProfileProvider);
```

### Get All Active Bags
```dart
final bags = ref.watch(activeBagsProvider);
```

### Create New Bag
```dart
final newBag = CoffeeBag(/* fields */);
await ref.read(bagsProvider.notifier).createBag(newBag);
```

### Get Cups for a Bag
```dart
final cups = ref.watch(cupsForBagProvider(bagId));
```

### Update User Preferences
```dart
await ref.read(userProfileProvider.notifier).updateUser(updatedUser);
```

### Generate QR Code
```dart
final qrData = ShareService.encodeCup(cup);
// Use with QrImageView widget
```

### Take Photo
```dart
final photoPath = await PhotoService().capturePhoto();
```

---

## Troubleshooting

### Hive Adapters Not Found
**Problem**: `Cannot find adapter for type X`
**Solution**: Run build_runner to generate adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Not Initializing
**Problem**: Firebase features not working
**Solution**: Check SETUP_INSTRUCTIONS.md for Firebase configuration

### State Not Updating
**Problem**: UI not rebuilding when data changes
**Solution**: Use `ref.watch()` not `ref.read()` in build method

### Deep Links Not Working
**Problem**: brewlog:// URLs don't open app
**Solution**: Check platform-specific configuration in android/ios folders

---

## Further Reading

- **README.md**: Project overview and quick start
- **SETUP_INSTRUCTIONS.md**: Detailed development setup
- **BUILD_INSTRUCTIONS.md**: Build and deployment guide
- **AUTHENTICATION_IMPLEMENTATION.md**: Auth system details
- **FIREBASE_BACKEND_ACTIVATED.md**: Firebase integration status
- **PREMIUM_FEATURES_ROADMAP.md**: Premium features plan
- **claude.md**: Development history and roadmap

---

## Key Takeaways

1. **Offline-first architecture**: Everything works without internet
2. **Riverpod for state**: Reactive, type-safe state management
3. **Hive for storage**: Fast, embedded NoSQL database
4. **Firebase is optional**: Only for premium users
5. **Models are rich**: 50+ fields per cup for advanced tracking
6. **Three rating scales**: All stored simultaneously
7. **Field visibility**: Highly customizable UI
8. **QR sharing**: Premium feature for sharing brews
9. **Clean architecture**: Clear separation of layers
10. **Type-safe**: Strong typing throughout

---

**Last Updated**: 2025-11-22
**Version**: 1.0.0
**Maintainer**: BrewLog Development Team
