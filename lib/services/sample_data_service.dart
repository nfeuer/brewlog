import 'package:uuid/uuid.dart';
import '../models/coffee_bag.dart';
import '../models/cup.dart';
import '../utils/constants.dart';
import 'database_service.dart';

/// Service to generate sample data for testing and demo purposes
class SampleDataService {
  final _uuid = const Uuid();
  final _db = DatabaseService();

  /// Generate and insert complete sample data set
  Future<void> generateSampleData() async {
    print('Generating sample data...');

    // Get current user
    final user = _db.getCurrentUser();
    if (user == null) {
      print('No user found');
      return;
    }

    // Create 3 sample coffee bags with cups
    await _createBag1(user.id);
    await _createBag2(user.id);
    await _createBag3(user.id);

    print('Sample data generated successfully!');
  }

  /// Bag 1: Ethiopian Yirgacheffe - Light roast, fruity
  Future<void> _createBag1(String userId) async {
    final bagId = _uuid.v4();
    final now = DateTime.now();

    final bag = CoffeeBag(
      id: bagId,
      userId: userId,
      customTitle: 'Morning Favorite',
      coffeeName: 'Yirgacheffe Natural',
      roaster: 'Blue Bottle Coffee',
      farmer: 'Worka Cooperative',
      variety: 'Heirloom',
      elevation: '1,900-2,200m',
      beanAroma: 'Blueberry, Jasmine, Bergamot',
      datePurchased: now.subtract(const Duration(days: 14)),
      price: 22.00,
      bagSizeGrams: 340,
      roastDate: now.subtract(const Duration(days: 17)),
      openDate: now.subtract(const Duration(days: 13)),
      bagStatusIndex: BagStatus.active.index,
    );

    await _db.createBag(bag);

    // Create 5 cups for this bag
    final cups = [
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'V60',
        grindLevel: 'Medium-Fine',
        waterTempCelsius: 93,
        gramsUsed: 20,
        finalVolumeMl: 320,
        brewTimeSeconds: 180,
        bloomTimeSeconds: 30,
        score1to5: 4.5,
        score1to10: 9.0,
        score1to100: 90,
        tastingNotes: 'Amazing blueberry notes with a bright, clean finish. Floral jasmine aroma. Best cup yet!',
        flavorTags: ['fruity', 'berry', 'floral', 'bright', 'clean', 'sweet'],
        isBest: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'V60',
        grindLevel: 'Medium',
        waterTempCelsius: 95,
        gramsUsed: 20,
        finalVolumeMl: 320,
        brewTimeSeconds: 165,
        score1to5: 4.0,
        score1to10: 8.0,
        score1to100: 80,
        tastingNotes: 'Good but a bit too hot. Less fruit complexity than previous brews.',
        flavorTags: ['fruity', 'floral', 'bright'],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'AeroPress',
        grindLevel: 'Fine',
        waterTempCelsius: 85,
        gramsUsed: 17,
        finalVolumeMl: 240,
        brewTimeSeconds: 120,
        score1to5: 3.5,
        score1to10: 7.0,
        score1to100: 70,
        tastingNotes: 'Smooth and rich but lost some of the floral notes. Still good.',
        flavorTags: ['fruity', 'smooth', 'sweet'],
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'V60',
        grindLevel: 'Medium-Fine',
        waterTempCelsius: 91,
        gramsUsed: 20,
        finalVolumeMl: 320,
        brewTimeSeconds: 190,
        bloomTimeSeconds: 35,
        score1to5: 4.0,
        score1to10: 8.0,
        score1to100: 80,
        tastingNotes: 'Solid brew. Nice balance but not as complex as the best cup.',
        flavorTags: ['fruity', 'berry', 'floral', 'clean'],
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'V60',
        grindLevel: 'Medium',
        waterTempCelsius: 92,
        gramsUsed: 19,
        finalVolumeMl: 300,
        brewTimeSeconds: 175,
        bloomTimeSeconds: 30,
        score1to5: 3.5,
        score1to10: 7.0,
        score1to100: 70,
        tastingNotes: 'First cup from this bag. Good but still dialing in the recipe.',
        flavorTags: ['fruity', 'bright'],
        createdAt: now.subtract(const Duration(days: 13)),
      ),
    ];

    for (final cup in cups) {
      await _db.createCup(cup);
    }
  }

  /// Bag 2: Colombian - Medium roast, balanced
  Future<void> _createBag2(String userId) async {
    final bagId = _uuid.v4();
    final now = DateTime.now();

    final bag = CoffeeBag(
      id: bagId,
      userId: userId,
      customTitle: 'Daily Driver',
      coffeeName: 'Huila Supremo',
      roaster: 'Counter Culture',
      farmer: 'José Garcia',
      variety: 'Caturra, Castillo',
      elevation: '1,700m',
      beanAroma: 'Caramel, Brown Sugar, Orange',
      datePurchased: now.subtract(const Duration(days: 30)),
      price: 18.50,
      bagSizeGrams: 340,
      roastDate: now.subtract(const Duration(days: 33)),
      openDate: now.subtract(const Duration(days: 28)),
      finishedDate: now.subtract(const Duration(days: 3)),
      bagStatusIndex: BagStatus.finished.index,
    );

    await _db.createBag(bag);

    // Create 4 cups for this bag
    final cups = [
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'Chemex',
        grindLevel: 'Medium-Coarse',
        waterTempCelsius: 94,
        gramsUsed: 42,
        finalVolumeMl: 680,
        brewTimeSeconds: 240,
        bloomTimeSeconds: 45,
        score1to5: 4.5,
        score1to10: 9.0,
        score1to100: 90,
        tastingNotes: 'Perfect balance! Caramel sweetness with bright citrus acidity. Clean and smooth.',
        flavorTags: ['caramel', 'citrus', 'sweet', 'smooth', 'clean'],
        isBest: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'French Press',
        grindLevel: 'Coarse',
        waterTempCelsius: 93,
        gramsUsed: 30,
        finalVolumeMl: 480,
        brewTimeSeconds: 240,
        score1to5: 4.0,
        score1to10: 8.0,
        score1to100: 80,
        tastingNotes: 'Rich body, chocolate notes. Great for a lazy morning.',
        flavorTags: ['chocolatey', 'nutty', 'smooth', 'creamy'],
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'Drip Coffee',
        grindLevel: 'Medium',
        waterTempCelsius: 96,
        gramsUsed: 60,
        finalVolumeMl: 900,
        brewTimeSeconds: 300,
        score1to5: 3.5,
        score1to10: 7.0,
        score1to100: 70,
        tastingNotes: 'Made a big batch. Decent but not special. Good for getting work done.',
        flavorTags: ['caramel', 'nutty', 'smooth'],
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'Chemex',
        grindLevel: 'Medium',
        waterTempCelsius: 95,
        gramsUsed: 42,
        finalVolumeMl: 680,
        brewTimeSeconds: 220,
        bloomTimeSeconds: 40,
        score1to5: 4.0,
        score1to10: 8.0,
        score1to100: 80,
        tastingNotes: 'First Chemex brew with this bag. Turned out great!',
        flavorTags: ['caramel', 'citrus', 'sweet', 'clean'],
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    ];

    for (final cup in cups) {
      await _db.createCup(cup);
    }
  }

  /// Bag 3: Sumatra - Dark roast, earthy
  Future<void> _createBag3(String userId) async {
    final bagId = _uuid.v4();
    final now = DateTime.now();

    final bag = CoffeeBag(
      id: bagId,
      userId: userId,
      customTitle: 'Bold & Dark',
      coffeeName: 'Sumatra Mandheling',
      roaster: 'Stumptown Coffee',
      variety: 'Typica, Catimor',
      elevation: '1,100-1,300m',
      beanAroma: 'Dark Chocolate, Cedar, Tobacco',
      datePurchased: now.subtract(const Duration(days: 7)),
      price: 16.00,
      bagSizeGrams: 340,
      roastDate: now.subtract(const Duration(days: 10)),
      openDate: now.subtract(const Duration(days: 5)),
      bagStatusIndex: BagStatus.active.index,
    );

    await _db.createBag(bag);

    // Create 3 cups for this bag
    final cups = [
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'French Press',
        grindLevel: 'Coarse',
        waterTempCelsius: 94,
        gramsUsed: 28,
        finalVolumeMl: 450,
        brewTimeSeconds: 240,
        score1to5: 4.0,
        score1to10: 8.0,
        score1to100: 80,
        tastingNotes: 'Full-bodied and earthy. Perfect dark roast character. Great with milk.',
        flavorTags: ['earthy', 'chocolatey', 'creamy', 'smooth', 'wine-like'],
        isBest: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'Moka Pot',
        grindLevel: 'Fine',
        waterTempCelsius: 100,
        gramsUsed: 18,
        finalVolumeMl: 120,
        brewTimeSeconds: 300,
        score1to5: 4.5,
        score1to10: 9.0,
        score1to100: 90,
        tastingNotes: 'Incredibly rich and intense. Almost espresso-like. Amazing!',
        flavorTags: ['chocolatey', 'earthy', 'creamy', 'bitter', 'smooth'],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Cup(
        id: _uuid.v4(),
        bagId: bagId,
        userId: userId,
        brewType: 'French Press',
        grindLevel: 'Coarse',
        waterTempCelsius: 92,
        gramsUsed: 30,
        finalVolumeMl: 480,
        brewTimeSeconds: 240,
        score1to5: 3.5,
        score1to10: 7.0,
        score1to100: 70,
        tastingNotes: 'First cup. Good but could be better. Trying different ratios next time.',
        flavorTags: ['earthy', 'chocolatey', 'smooth'],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final cup in cups) {
      await _db.createCup(cup);
    }
  }

  /// Check if sample data already exists
  Future<bool> hasSampleData() async {
    final bags = _db.getAllBags();
    return bags.isNotEmpty;
  }

  /// Clear all data and regenerate sample data
  Future<void> resetToSampleData() async {
    await _db.clearAllData();
    await generateSampleData();
  }
}
