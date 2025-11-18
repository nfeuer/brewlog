import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_setup.dart';
import '../services/database_service.dart';
import 'user_provider.dart';

/// Provider for all equipment setups
final equipmentProvider =
    StateNotifierProvider<EquipmentNotifier, List<EquipmentSetup>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return EquipmentNotifier(db);
});

class EquipmentNotifier extends StateNotifier<List<EquipmentSetup>> {
  final DatabaseService _db;

  EquipmentNotifier(this._db) : super([]) {
    _loadEquipment();
  }

  void _loadEquipment() {
    state = _db.getAllEquipment();
  }

  /// Create new equipment setup
  Future<String> createEquipment(EquipmentSetup equipment) async {
    final id = await _db.createEquipment(equipment);
    _loadEquipment();
    return id;
  }

  /// Update existing equipment setup
  Future<void> updateEquipment(EquipmentSetup equipment) async {
    await _db.updateEquipment(equipment);
    _loadEquipment();
  }

  /// Delete equipment setup
  Future<void> deleteEquipment(String equipmentId) async {
    await _db.deleteEquipment(equipmentId);
    _loadEquipment();
  }

  /// Set equipment as default
  Future<void> setAsDefault(String equipmentId) async {
    await _db.setEquipmentAsDefault(equipmentId);
    _loadEquipment();
  }

  /// Refresh equipment from database
  void refresh() {
    _loadEquipment();
  }
}

/// Provider for a single equipment setup by ID
final equipmentByIdProvider =
    Provider.family<EquipmentSetup?, String>((ref, equipmentId) {
  final equipment = ref.watch(equipmentProvider);
  try {
    return equipment.firstWhere((e) => e.id == equipmentId);
  } catch (e) {
    return null;
  }
});

/// Provider for default equipment setup
final defaultEquipmentProvider = Provider<EquipmentSetup?>((ref) {
  final equipment = ref.watch(equipmentProvider);
  try {
    return equipment.firstWhere((e) => e.isDefault);
  } catch (e) {
    return equipment.isNotEmpty ? equipment.first : null;
  }
});

/// Provider to check if user has any equipment setups
final hasEquipmentProvider = Provider<bool>((ref) {
  final equipment = ref.watch(equipmentProvider);
  return equipment.isNotEmpty;
});
