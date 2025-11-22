import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';

import 'services/database_service.dart';
import 'services/firebase_service.dart';
import 'services/sample_data_service.dart';
import 'services/share_service.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'models/drink_recipe.dart';
import 'models/cup.dart';
import 'models/bag.dart';
import 'providers/drink_recipes_provider.dart';
import 'providers/bags_provider.dart';
import 'providers/cups_provider.dart';

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

class BrewLogApp extends ConsumerStatefulWidget {
  const BrewLogApp({super.key});

  @override
  ConsumerState<BrewLogApp> createState() => _BrewLogAppState();
}

class _BrewLogAppState extends ConsumerState<BrewLogApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link if app was opened from a deep link
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('Error getting initial app link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    print('Received deep link: $uri');

    final deepLinkData = ShareService.parseDeepLink(uri.toString());
    if (deepLinkData == null) {
      print('Invalid deep link format');
      return;
    }

    final String type = deepLinkData['type'];
    final String jsonData = deepLinkData['data'];

    if (type == 'drink_recipe') {
      final DrinkRecipe? recipe = ShareService.decodeDrinkRecipe(jsonData);
      if (recipe != null) {
        _showImportRecipeDialog(recipe);
      }
    } else if (type == 'cup') {
      final Cup? cup = ShareService.decodeCup(jsonData);
      if (cup != null) {
        _showImportCupDialog(cup);
      }
    }
  }

  void _showImportRecipeDialog(DrinkRecipe recipe) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import this drink recipe?'),
            const SizedBox(height: 16),
            Text(
              recipe.name ?? 'Unnamed Recipe',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (recipe.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.summary,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(drinkRecipesProvider.notifier).addRecipe(recipe);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showMessage('Recipe "${recipe.name ?? "Unnamed"}" imported successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  _showMessage('Failed to import recipe: $e');
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showImportCupDialog(Cup cup) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    // Get user's bags
    final bags = ref.read(bagsProvider);

    if (bags.isEmpty) {
      // No bags available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Bags Available'),
          content: const Text(
            'You need to have at least one coffee bag to import tasting notes. '
            'Please add a bag first, then try importing again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show bag selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tasting Notes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select which bag to add these tasting notes to:'),
              const SizedBox(height: 16),
              // Cup preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cup.coffeeName != null) ...[
                      Text(
                        cup.coffeeName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (cup.roaster != null) ...[
                      Text(
                        cup.roaster!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (cup.rating != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${cup.rating}/5',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to bag:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Bag selection dropdown
              ...bags.map((bag) => ListTile(
                    title: Text(bag.coffeeName),
                    subtitle: bag.roaster != null ? Text(bag.roaster!) : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await _importCupToBag(cup, bag);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCupToBag(Cup cup, Bag bag) async {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    try {
      // Create a new cup with the selected bagId
      final importedCup = Cup(
        id: cup.id, // Will get a new ID when added
        userId: cup.userId, // Will be set to current user
        bagId: bag.id, // Use the selected bag
        brewMethod: cup.brewMethod,
        waterAmount: cup.waterAmount,
        coffeeAmount: cup.coffeeAmount,
        brewTime: cup.brewTime,
        waterTemp: cup.waterTemp,
        grindSize: cup.grindSize,
        tastingNotes: cup.tastingNotes,
        rating: cup.rating,
        favorite: cup.favorite,
        notes: cup.notes,
        photoPaths: [], // Photos don't transfer
        createdAt: cup.createdAt,
        updatedAt: DateTime.now(),
        // Cupping scores
        fragranceAroma: cup.fragranceAroma,
        flavor: cup.flavor,
        aftertaste: cup.aftertaste,
        acidity: cup.acidity,
        body: cup.body,
        balance: cup.balance,
        uniformity: cup.uniformity,
        cleanCup: cup.cleanCup,
        sweetness: cup.sweetness,
        overall: cup.overall,
        defects: cup.defects,
        // Drink recipe
        drinkRecipeId: cup.drinkRecipeId,
      );

      // Add the cup
      await ref.read(cupsNotifierProvider.notifier).addCup(importedCup);

      _showMessage('Tasting notes imported to ${bag.coffeeName}');
    } catch (e) {
      _showMessage('Failed to import tasting notes: $e');
    }
  }

  void _showMessage(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'BrewLog',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
