import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bag.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'user_provider.dart';

/// Provider for all coffee bags
final bagsProvider = StateNotifierProvider<BagsNotifier, List<CoffeeBag>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return BagsNotifier(db);
});

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
