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

  // Generate sample data if database is empty
  final sampleDataService = SampleDataService();
  final hasSampleData = await sampleDataService.hasSampleData();
  if (!hasSampleData) {
    print('Generating sample data for testing...');
    await sampleDataService.generateSampleData();
    print('Sample data generated!');
  }

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
