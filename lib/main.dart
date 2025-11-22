import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/database_service.dart';
import 'services/firebase_service.dart';
import 'services/sample_data_service.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  // NOTE: These will be generated when you run:
  // flutter pub run build_runner build --delete-conflicting-outputs
  //
  // Uncomment these lines after running build_runner:
  // Hive.registerAdapter(UserProfileAdapter());
  // Hive.registerAdapter(UserStatsAdapter());
  // Hive.registerAdapter(CoffeeBagAdapter());
  // Hive.registerAdapter(CupAdapter());
  // Hive.registerAdapter(SharedCupAdapter());

  // Initialize database service
  final db = DatabaseService();
  await db.initialize();

  // Try to initialize Firebase (optional)
  final firebaseService = FirebaseService();
  final firebaseAvailable = await firebaseService.initialize();
  if (firebaseAvailable) {
    print('Firebase initialized successfully - Premium features available');
  } else {
    print('Firebase not configured - Running in local-only mode');
    print('See SETUP_INSTRUCTIONS.md for Firebase setup');
  }

  runApp(
    const ProviderScope(
      child: BrewLogApp(),
    ),
  );

  // Generate sample data in debug mode only (non-blocking)
  // This will NOT run in production release builds
  if (kDebugMode) {
    _generateSampleDataIfNeeded();
  }
}

/// Generate sample data in the background without blocking app startup
/// Only runs in debug mode - production builds start with a clean database
Future<void> _generateSampleDataIfNeeded() async {
  try {
    final sampleDataService = SampleDataService();
    final hasSampleData = await sampleDataService.hasSampleData();
    if (!hasSampleData) {
      print('🧪 DEBUG MODE: Generating sample data for testing...');
      await sampleDataService.generateSampleData();
      print('✅ Sample data generated!');
    }
  } catch (e) {
    print('❌ Error generating sample data: $e');
  }
}

class BrewLogApp extends StatelessWidget {
  const BrewLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrewLog',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
