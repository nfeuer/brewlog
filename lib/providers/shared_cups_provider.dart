import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_cup.dart';
import '../services/database_service.dart';
import 'user_provider.dart';

/// Provider for all shared cups
final sharedCupsProvider =
    StateNotifierProvider<SharedCupsNotifier, List<SharedCup>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SharedCupsNotifier(db);
});

class SharedCupsNotifier extends StateNotifier<List<SharedCup>> {
  final DatabaseService _db;

  SharedCupsNotifier(this._db) : super([]) {
    _loadSharedCups();
  }

  void _loadSharedCups() {
    state = _db.getSharedCups();
  }

  /// Add shared cup from QR code
  Future<String> addSharedCup(SharedCup sharedCup) async {
    final id = await _db.addSharedCup(sharedCup);
    _loadSharedCups();
    return id;
  }

  /// Delete shared cup
  Future<void> deleteSharedCup(String sharedCupId) async {
    await _db.deleteSharedCup(sharedCupId);
    _loadSharedCups();
  }

  /// Refresh shared cups from database
  void refresh() {
    _loadSharedCups();
  }
}

/// Provider for a single shared cup by ID
final sharedCupProvider = Provider.family<SharedCup?, String>((ref, sharedCupId) {
  final sharedCups = ref.watch(sharedCupsProvider);
  try {
    return sharedCups.firstWhere((cup) => cup.id == sharedCupId);
  } catch (e) {
    return null;
  }
});

/// Provider for shared cups count
final sharedCupsCountProvider = Provider<int>((ref) {
  final sharedCups = ref.watch(sharedCupsProvider);
  return sharedCups.length;
});
