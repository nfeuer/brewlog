import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';
import '../services/database_service.dart';
import 'user_provider.dart';
import 'bags_provider.dart';

/// Provider for cups of a specific bag
final cupsForBagProvider =
    Provider.family<List<Cup>, String>((ref, bagId) {
  final db = ref.watch(databaseServiceProvider);
  return db.getCupsForBag(bagId);
});

/// Provider for a single cup by ID
final cupProvider = Provider.family<Cup?, String>((ref, cupId) {
  final db = ref.watch(databaseServiceProvider);
  return db.getCup(cupId);
});

/// Notifier for cup operations
final cupsNotifierProvider = Provider<CupsNotifier>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final bagsNotifier = ref.watch(bagsProvider.notifier);
  final userNotifier = ref.watch(userProfileProvider.notifier);
  return CupsNotifier(db, bagsNotifier, userNotifier);
});

class CupsNotifier {
  final DatabaseService _db;
  final BagsNotifier _bagsNotifier;
  final UserProfileNotifier _userNotifier;

  CupsNotifier(this._db, this._bagsNotifier, this._userNotifier);

  /// Create new cup
  Future<String> createCup(Cup cup) async {
    final id = await _db.createCup(cup);

    // Refresh bags to update stats
    _bagsNotifier.refresh();
    _userNotifier.refresh();

    return id;
  }

  /// Update existing cup
  Future<void> updateCup(Cup cup) async {
    await _db.updateCup(cup);

    // Refresh bags to update stats
    _bagsNotifier.refresh();
    _userNotifier.refresh();
  }

  /// Delete cup
  Future<void> deleteCup(String cupId) async {
    await _db.deleteCup(cupId);

    // Refresh bags to update stats
    _bagsNotifier.refresh();
    _userNotifier.refresh();
  }

  /// Copy cup
  Future<String> copyCup(String cupId) async {
    final id = await _db.copyCup(cupId);

    // Refresh bags to update stats
    _bagsNotifier.refresh();
    _userNotifier.refresh();

    return id;
  }

  /// Mark cup as best
  Future<void> markAsBest(String cupId) async {
    await _db.markCupAsBest(cupId);

    // Refresh bags to update stats
    _bagsNotifier.refresh();
  }

  /// Increment share count
  Future<void> incrementShareCount(String cupId) async {
    await _db.incrementShareCount(cupId);
  }
}

/// Provider for best cup of a bag
final bestCupProvider = Provider.family<Cup?, String>((ref, bagId) {
  final cups = ref.watch(cupsForBagProvider(bagId));
  try {
    return cups.firstWhere((cup) => cup.isBest);
  } catch (e) {
    // If no best cup, return highest rated
    if (cups.isEmpty) return null;

    final sortedByScore = List<Cup>.from(cups)
      ..sort((a, b) {
        final aScore = a.score1to5 ?? 0;
        final bScore = b.score1to5 ?? 0;
        return bScore.compareTo(aScore);
      });

    return sortedByScore.first;
  }
});

/// Provider for cup count by brew type
final cupCountByBrewTypeProvider = Provider<Map<String, int>>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.stats.cupsByBrewType ?? {};
});

/// Provider for most used brew type
final mostUsedBrewTypeProvider = Provider<String?>((ref) {
  final cupsByType = ref.watch(cupCountByBrewTypeProvider);

  if (cupsByType.isEmpty) return null;

  var maxCount = 0;
  String? mostUsed;

  cupsByType.forEach((type, count) {
    if (count > maxCount) {
      maxCount = count;
      mostUsed = type;
    }
  });

  return mostUsed;
});

/// Provider for total cups made
final totalCupsMadeProvider = Provider<int>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.stats.totalCupsMade ?? 0;
});

/// Provider for favorite bag (most cups made)
final favoriteBagProvider = Provider<String?>((ref) {
  final bags = ref.watch(bagsProvider);

  if (bags.isEmpty) return null;

  final sortedByTotalCups = List<CoffeeBag>.from(bags)
    ..sort((a, b) => b.totalCups.compareTo(a.totalCups));

  return sortedByTotalCups.first.displayTitle;
});
