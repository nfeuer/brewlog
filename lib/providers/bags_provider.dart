import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bag.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'user_provider.dart';

/// **Coffee Bag State Management**
///
/// This file provides Riverpod providers for managing coffee bag state throughout
/// the application. It handles CRUD operations, filtering, sorting, and searching.
///
/// **Available Providers:**
///
/// - [bagsProvider] - Main state provider for all bags (StateNotifierProvider)
/// - [bagProvider] - Get single bag by ID (Provider.family)
/// - [activeBagsProvider] - Filter active bags only
/// - [finishedBagsProvider] - Filter finished bags only
/// - [sortedBagsProvider] - Sort bags by latest/alphabetical/score
/// - [searchedBagsProvider] - Filter bags by search query
///
/// **Usage Examples:**
///
/// ```dart
/// // Watch all bags (auto-rebuilds on changes)
/// final bags = ref.watch(bagsProvider);
///
/// // Get single bag by ID
/// final bag = ref.watch(bagProvider('bag-id-123'));
///
/// // Create new bag
/// await ref.read(bagsProvider.notifier).createBag(newBag);
///
/// // Update bag status
/// await ref.read(bagsProvider.notifier).markAsFinished(bagId);
///
/// // Search bags
/// ref.read(bagSearchQueryProvider.notifier).state = 'ethiopia';
/// final results = ref.watch(searchedBagsProvider);
/// ```
///
/// **See Also:**
/// - [CoffeeBag] model definition
/// - [DatabaseService] for persistence layer
/// - [CODEBASE_GUIDE.md] section "State Management"

/// Provider for all coffee bags.
///
/// This is the main state provider. It loads bags from [DatabaseService]
/// and automatically refreshes the UI when bags are created, updated, or deleted.
final bagsProvider = StateNotifierProvider<BagsNotifier, List<CoffeeBag>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return BagsNotifier(db);
});

/// State notifier for managing coffee bag operations.
///
/// Handles CRUD operations and delegates to [DatabaseService] for persistence.
/// Automatically reloads state after each operation to keep UI in sync.
class BagsNotifier extends StateNotifier<List<CoffeeBag>> {
  final DatabaseService _db;

  BagsNotifier(this._db) : super([]) {
    _loadBags();
  }

  void _loadBags() {
    state = _db.getAllBags();
  }

  /// Create new bag
  Future<String> createBag(CoffeeBag bag) async {
    final id = await _db.createBag(bag);
    _loadBags();
    return id;
  }

  /// Update existing bag
  Future<void> updateBag(CoffeeBag bag) async {
    await _db.updateBag(bag);
    _loadBags();
  }

  /// Delete bag
  Future<void> deleteBag(String bagId) async {
    await _db.deleteBag(bagId);
    _loadBags();
  }

  /// Refresh bags from database
  void refresh() {
    _loadBags();
  }

  /// Mark bag as finished
  Future<void> markAsFinished(String bagId) async {
    final bag = _db.getBag(bagId);
    if (bag == null) return;

    final updated = bag.copyWith(
      status: BagStatus.finished,
      finishedDate: DateTime.now(),
    );

    await updateBag(updated);
  }

  /// Mark bag as active
  Future<void> markAsActive(String bagId) async {
    final bag = _db.getBag(bagId);
    if (bag == null) return;

    final updated = bag.copyWith(
      status: BagStatus.active,
      finishedDate: null,
    );

    await updateBag(updated);
  }
}

/// Provider for a single bag by ID
final bagProvider = Provider.family<CoffeeBag?, String>((ref, bagId) {
  final bags = ref.watch(bagsProvider);
  try {
    return bags.firstWhere((bag) => bag.id == bagId);
  } catch (e) {
    return null;
  }
});

/// Provider for active bags only
final activeBagsProvider = Provider<List<CoffeeBag>>((ref) {
  final bags = ref.watch(bagsProvider);
  return bags.where((bag) => bag.status == BagStatus.active).toList();
});

/// Provider for finished bags only
final finishedBagsProvider = Provider<List<CoffeeBag>>((ref) {
  final bags = ref.watch(bagsProvider);
  return bags.where((bag) => bag.status == BagStatus.finished).toList();
});

/// Provider for bags sorted by different criteria
enum BagSortOption {
  latest,
  alphabetical,
  score,
}

final bagSortOptionProvider = StateProvider<BagSortOption>((ref) {
  return BagSortOption.latest;
});

final sortedBagsProvider = Provider<List<CoffeeBag>>((ref) {
  final bags = ref.watch(activeBagsProvider);
  final sortOption = ref.watch(bagSortOptionProvider);

  final sortedList = List<CoffeeBag>.from(bags);

  switch (sortOption) {
    case BagSortOption.latest:
      sortedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case BagSortOption.alphabetical:
      sortedList.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
      break;
    case BagSortOption.score:
      sortedList.sort((a, b) {
        final aScore = a.avgScore ?? 0;
        final bScore = b.avgScore ?? 0;
        return bScore.compareTo(aScore);
      });
      break;
  }

  return sortedList;
});

/// Provider for searching bags
final bagSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedBagsProvider = Provider<List<CoffeeBag>>((ref) {
  final bags = ref.watch(sortedBagsProvider);
  final query = ref.watch(bagSearchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return bags;
  }

  return bags.where((bag) {
    return bag.displayTitle.toLowerCase().contains(query) ||
        bag.coffeeName.toLowerCase().contains(query) ||
        bag.roaster.toLowerCase().contains(query);
  }).toList();
});
