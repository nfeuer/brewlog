import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'user_profile.g.dart';

/// Tracks cumulative brewing statistics for a user.
///
/// This class maintains running totals of brewing activity and is embedded
/// within [UserProfile]. Statistics automatically update as cups are created,
/// updated, or deleted through [DatabaseService].
///
/// **Tracked Metrics:**
/// - Total cups brewed across all bags
/// - Total coffee used (grams)
/// - Total volume produced (ml)
/// - Breakdown by brew type (pour over, espresso, etc.)
/// - Total bags purchased
///
/// **Example:**
/// ```dart
/// print('Total cups: ${user.stats.totalCupsMade}');
/// print('Total coffee: ${user.stats.totalGramsUsed}g');
/// print('Espresso shots: ${user.stats.cupsByBrewType['Espresso'] ?? 0}');
/// ```
@HiveType(typeId: HiveTypeIds.userStats)
class UserStats extends HiveObject {
  @HiveField(0)
  int totalCupsMade;

  @HiveField(1)
  double totalGramsUsed;

  @HiveField(2)
  double totalMlConsumed;

  @HiveField(3)
  Map<String, int> cupsByBrewType; // e.g., {"pour_over": 45, "espresso": 32}

  @HiveField(4)
  int totalBagsPurchased;

  UserStats({
    this.totalCupsMade = 0,
    this.totalGramsUsed = 0.0,
    this.totalMlConsumed = 0.0,
    Map<String, int>? cupsByBrewType,
    this.totalBagsPurchased = 0,
  }) : cupsByBrewType = cupsByBrewType ?? {};

  /// Increments statistics when a new cup is brewed.
  ///
  /// Called automatically by [DatabaseService.createCup].
  ///
  /// **Updates:**
  /// - Increments [totalCupsMade]
  /// - Adds to [totalGramsUsed] if provided
  /// - Adds to [totalMlConsumed] if provided
  /// - Increments brew type counter in [cupsByBrewType]
  ///
  /// **Parameters:**
  /// - [brewType]: Type of brew (e.g., 'Pour Over', 'Espresso')
  /// - [gramsUsed]: Coffee weight in grams (optional)
  /// - [mlConsumed]: Final volume in ml (optional)
  void addCup({
    required String brewType,
    double? gramsUsed,
    double? mlConsumed,
  }) {
    totalCupsMade++;
    if (gramsUsed != null) totalGramsUsed += gramsUsed;
    if (mlConsumed != null) totalMlConsumed += mlConsumed;
    cupsByBrewType[brewType] = (cupsByBrewType[brewType] ?? 0) + 1;
  }

  /// Decrements statistics when a cup is deleted or updated.
  ///
  /// Called automatically by [DatabaseService.deleteCup] and [DatabaseService.updateCup].
  ///
  /// **Updates:**
  /// - Decrements [totalCupsMade] (minimum 0)
  /// - Subtracts from [totalGramsUsed] if provided (minimum 0)
  /// - Subtracts from [totalMlConsumed] if provided (minimum 0)
  /// - Decrements brew type counter, removes key if count reaches 0
  ///
  /// **Parameters:**
  /// - [brewType]: Type of brew being removed
  /// - [gramsUsed]: Coffee weight to subtract (optional)
  /// - [mlConsumed]: Volume to subtract (optional)
  void removeCup({
    required String brewType,
    double? gramsUsed,
    double? mlConsumed,
  }) {
    if (totalCupsMade > 0) totalCupsMade--;
    if (gramsUsed != null && totalGramsUsed >= gramsUsed) {
      totalGramsUsed -= gramsUsed;
    }
    if (mlConsumed != null && totalMlConsumed >= mlConsumed) {
      totalMlConsumed -= mlConsumed;
    }
    if (cupsByBrewType.containsKey(brewType) && cupsByBrewType[brewType]! > 0) {
      cupsByBrewType[brewType] = cupsByBrewType[brewType]! - 1;
      if (cupsByBrewType[brewType] == 0) {
        cupsByBrewType.remove(brewType);
      }
    }
  }
}

/// Represents a user account with preferences, statistics, and customization.
///
/// This is the central user entity containing all account information,
/// preferences, and cumulative statistics. There is typically only one
/// [UserProfile] per device (stored as 'current_user' in Hive).
///
/// **Key Sections:**
/// - **Account**: id, username, email, isPaid, isAdmin, firebaseUid
/// - **Preferences**: rating scale, view mode, field visibility
/// - **Statistics**: embedded [UserStats] object
/// - **Customization**: custom brew types, profile picture, bio
/// - **Username Management**: tracking for username prompt dialog
///
/// **Premium Features:**
/// When [isPaid] is true, the user gets access to:
/// - Cloud sync via Firebase
/// - QR code sharing
/// - Multi-device access
/// - Cloud photo storage
///
/// **Example:**
/// ```dart
/// final user = ref.watch(userProfileProvider);
/// if (user.isPaid) {
///   // Show premium features
/// }
/// print('You\'ve made ${user.stats.totalCupsMade} cups!');
/// ```
@HiveType(typeId: HiveTypeIds.userProfile)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? username;

  @HiveField(2)
  String? email;

  @HiveField(3)
  bool isPaid;

  @HiveField(4)
  bool isAdmin;

  // Preferences
  @HiveField(5)
  int ratingScaleIndex; // Store as index for Hive compatibility

  @HiveField(6)
  List<String> defaultVisibleFields;

  @HiveField(7)
  int viewPreferenceIndex; // Store as index for Hive compatibility

  // Stats
  @HiveField(8)
  UserStats stats;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  // Custom brew types added by user
  @HiveField(11)
  List<String> customBrewTypes;

  // Cup field visibility preferences
  @HiveField(12)
  Map<String, bool>? cupFieldVisibility;

  // Profile customization
  @HiveField(13)
  String? profilePicturePath;

  @HiveField(14)
  String? bio; // Short bio (max 25 characters)

  // Username prompt tracking
  @HiveField(15)
  bool hasBeenAskedForUsername;

  @HiveField(16)
  bool neverAskForUsername;

  // Firebase authentication
  @HiveField(17)
  String? firebaseUid; // Firebase Auth user ID

  // Haptic feedback preference
  @HiveField(18)
  bool hapticsEnabled;

  // Profile display name (separate from username)
  @HiveField(19)
  String? profileName; // Display name shown on profile (e.g., "Nick the Coffee Enthusiast")

  UserProfile({
    required this.id,
    this.username,
    this.email,
    this.isPaid = false,
    this.isAdmin = false,
    this.ratingScaleIndex = 0, // Default to oneToFive
    List<String>? defaultVisibleFields,
    this.viewPreferenceIndex = 0, // Default to grid
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? customBrewTypes,
    this.cupFieldVisibility,
    this.profilePicturePath,
    this.bio,
    this.hasBeenAskedForUsername = false,
    this.neverAskForUsername = false,
    this.firebaseUid,
    this.hapticsEnabled = true, // Default to enabled
    this.profileName,
  })  : defaultVisibleFields = defaultVisibleFields ?? [],
        stats = stats ?? UserStats(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        customBrewTypes = customBrewTypes ?? [];

  /// Converts the rating scale index to a [RatingScale] enum value.
  ///
  /// Hive stores enums as integers for efficiency. This getter provides
  /// type-safe access to the user's preferred rating scale.
  RatingScale get ratingScale => RatingScale.values[ratingScaleIndex];

  /// Sets the rating scale preference and stores it as an index for Hive.
  set ratingScale(RatingScale scale) => ratingScaleIndex = scale.index;

  /// Converts the view preference index to a [ViewPreference] enum value.
  ///
  /// User can choose between:
  /// - [ViewPreference.grid]: Card grid layout
  /// - [ViewPreference.list]: Detailed list view
  /// - [ViewPreference.rolodex]: Animated carousel
  ViewPreference get viewPreference => ViewPreference.values[viewPreferenceIndex];

  /// Sets the view preference and stores it as an index for Hive.
  set viewPreference(ViewPreference pref) => viewPreferenceIndex = pref.index;

  /// Returns all available brew types (default + user-added custom types).
  ///
  /// **Default types** are defined in [constants.dart]:
  /// Pour Over, Espresso, French Press, AeroPress, etc.
  ///
  /// **Custom types** are added by the user and stored in [customBrewTypes].
  ///
  /// **Example:**
  /// ```dart
  /// final types = user.allBrewTypes;
  /// DropdownButton<String>(
  ///   items: types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
  /// )
  /// ```
  List<String> get allBrewTypes {
    return [...defaultBrewTypes, ...customBrewTypes];
  }

  /// Updates the [updatedAt] timestamp to the current time.
  ///
  /// Called automatically by most update operations.
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Converts this profile to a JSON map for Firebase synchronization.
  ///
  /// **Includes:**
  /// - All account fields
  /// - Nested [UserStats] as a map
  /// - Enum values as string names
  /// - DateTime as ISO 8601 strings
  ///
  /// **Usage:**
  /// - Cloud sync for premium users
  /// - User data backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isPaid': isPaid,
      'isAdmin': isAdmin,
      'ratingScale': ratingScale.name,
      'defaultVisibleFields': defaultVisibleFields,
      'viewPreference': viewPreference.name,
      'stats': {
        'totalCupsMade': stats.totalCupsMade,
        'totalGramsUsed': stats.totalGramsUsed,
        'totalMlConsumed': stats.totalMlConsumed,
        'cupsByBrewType': stats.cupsByBrewType,
        'totalBagsPurchased': stats.totalBagsPurchased,
      },
      'customBrewTypes': customBrewTypes,
      'cupFieldVisibility': cupFieldVisibility,
      'profilePicturePath': profilePicturePath,
      'profileName': profileName,
      'bio': bio,
      'hasBeenAskedForUsername': hasBeenAskedForUsername,
      'neverAskForUsername': neverAskForUsername,
      'firebaseUid': firebaseUid,
      'hapticsEnabled': hapticsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      ratingScaleIndex: RatingScale.values
          .indexWhere((e) => e.name == json['ratingScale']),
      defaultVisibleFields:
          List<String>.from(json['defaultVisibleFields'] ?? []),
      viewPreferenceIndex: ViewPreference.values
          .indexWhere((e) => e.name == json['viewPreference']),
      stats: UserStats(
        totalCupsMade: json['stats']?['totalCupsMade'] ?? 0,
        totalGramsUsed: (json['stats']?['totalGramsUsed'] ?? 0.0).toDouble(),
        totalMlConsumed: (json['stats']?['totalMlConsumed'] ?? 0.0).toDouble(),
        cupsByBrewType:
            Map<String, int>.from(json['stats']?['cupsByBrewType'] ?? {}),
        totalBagsPurchased: json['stats']?['totalBagsPurchased'] ?? 0,
      ),
      customBrewTypes: List<String>.from(json['customBrewTypes'] ?? []),
      cupFieldVisibility: json['cupFieldVisibility'] != null
          ? Map<String, bool>.from(json['cupFieldVisibility'])
          : null,
      profilePicturePath: json['profilePicturePath'] as String?,
      profileName: json['profileName'] as String?,
      bio: json['bio'] as String?,
      hasBeenAskedForUsername: json['hasBeenAskedForUsername'] as bool? ?? false,
      neverAskForUsername: json['neverAskForUsername'] as bool? ?? false,
      firebaseUid: json['firebaseUid'] as String?,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
