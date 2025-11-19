import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Provider for database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for current user profile
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return UserProfileNotifier(db);
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final DatabaseService _db;

  UserProfileNotifier(this._db) : super(null) {
    _loadUser();
  }

  void _loadUser() {
    state = _db.getCurrentUser();
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    await _db.updateUser(profile);
    state = profile;
  }

  /// Update username
  Future<void> updateUsername(String username) async {
    if (state == null) return;

    final updated = UserProfile(
      id: state!.id,
      username: username,
      email: state!.email,
      isPaid: state!.isPaid,
      isAdmin: state!.isAdmin,
      ratingScaleIndex: state!.ratingScaleIndex,
      defaultVisibleFields: state!.defaultVisibleFields,
      viewPreferenceIndex: state!.viewPreferenceIndex,
      stats: state!.stats,
      customBrewTypes: state!.customBrewTypes,
      cupFieldVisibility: state!.cupFieldVisibility,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );

    await updateProfile(updated);
  }

  /// Update rating scale preference
  Future<void> updateRatingScale(RatingScale scale) async {
    if (state == null) return;

    final updated = UserProfile(
      id: state!.id,
      username: state!.username,
      email: state!.email,
      isPaid: state!.isPaid,
      isAdmin: state!.isAdmin,
      ratingScaleIndex: scale.index,
      defaultVisibleFields: state!.defaultVisibleFields,
      viewPreferenceIndex: state!.viewPreferenceIndex,
      stats: state!.stats,
      customBrewTypes: state!.customBrewTypes,
      cupFieldVisibility: state!.cupFieldVisibility,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );

    await updateProfile(updated);
  }

  /// Update view preference
  Future<void> updateViewPreference(ViewPreference pref) async {
    if (state == null) return;

    final updated = UserProfile(
      id: state!.id,
      username: state!.username,
      email: state!.email,
      isPaid: state!.isPaid,
      isAdmin: state!.isAdmin,
      ratingScaleIndex: state!.ratingScaleIndex,
      defaultVisibleFields: state!.defaultVisibleFields,
      viewPreferenceIndex: pref.index,
      stats: state!.stats,
      customBrewTypes: state!.customBrewTypes,
      cupFieldVisibility: state!.cupFieldVisibility,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );

    await updateProfile(updated);
  }

  /// Update cup field visibility preferences
  Future<void> updateCupFieldVisibility(Map<String, bool> visibility) async {
    if (state == null) return;

    final updated = UserProfile(
      id: state!.id,
      username: state!.username,
      email: state!.email,
      isPaid: state!.isPaid,
      isAdmin: state!.isAdmin,
      ratingScaleIndex: state!.ratingScaleIndex,
      defaultVisibleFields: state!.defaultVisibleFields,
      viewPreferenceIndex: state!.viewPreferenceIndex,
      stats: state!.stats,
      customBrewTypes: state!.customBrewTypes,
      cupFieldVisibility: visibility,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );

    await updateProfile(updated);
  }

  /// Add custom brew type
  Future<void> addCustomBrewType(String brewType) async {
    if (state == null) return;

    if (!state!.customBrewTypes.contains(brewType)) {
      final updated = UserProfile(
        id: state!.id,
        username: state!.username,
        email: state!.email,
        isPaid: state!.isPaid,
        isAdmin: state!.isAdmin,
        ratingScaleIndex: state!.ratingScaleIndex,
        defaultVisibleFields: state!.defaultVisibleFields,
        viewPreferenceIndex: state!.viewPreferenceIndex,
        stats: state!.stats,
        customBrewTypes: [...state!.customBrewTypes, brewType],
        cupFieldVisibility: state!.cupFieldVisibility,
        createdAt: state!.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateProfile(updated);
    }
  }

  /// Upgrade to paid account
  Future<void> upgradeToPaid(String email) async {
    if (state == null) return;

    final updated = UserProfile(
      id: state!.id,
      username: state!.username,
      email: email,
      isPaid: true,
      isAdmin: state!.isAdmin,
      ratingScaleIndex: state!.ratingScaleIndex,
      defaultVisibleFields: state!.defaultVisibleFields,
      viewPreferenceIndex: state!.viewPreferenceIndex,
      stats: state!.stats,
      customBrewTypes: state!.customBrewTypes,
      cupFieldVisibility: state!.cupFieldVisibility,
      createdAt: state!.createdAt,
      updatedAt: DateTime.now(),
    );

    await updateProfile(updated);
  }

  /// Refresh user from database
  void refresh() {
    _loadUser();
  }
}

/// Provider for user statistics
final userStatsProvider = Provider<UserStats?>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.stats;
});

/// Provider for checking if user is paid
final isPaidUserProvider = Provider<bool>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.isPaid ?? false;
});

/// Provider for user's rating scale preference
final ratingScaleProvider = Provider<RatingScale>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.ratingScale ?? RatingScale.oneToFive;
});

/// Provider for user's view preference
final viewPreferenceProvider = Provider<ViewPreference>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.viewPreference ?? ViewPreference.grid;
});

/// Provider for all brew types (default + custom)
final allBrewTypesProvider = Provider<List<String>>((ref) {
  final user = ref.watch(userProfileProvider);
  return user?.allBrewTypes ?? defaultBrewTypes;
});

/// Provider for cup field visibility preferences
/// Returns merged visibility map (user preferences + defaults)
final cupFieldVisibilityProvider = Provider<Map<String, bool>>((ref) {
  final user = ref.watch(userProfileProvider);

  // Start with defaults
  final visibility = Map<String, bool>.from(defaultFieldVisibility);

  // Merge with user preferences if they exist
  if (user?.cupFieldVisibility != null) {
    visibility.addAll(user!.cupFieldVisibility!);
  }

  return visibility;
});
