import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'user_profile.g.dart';

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

  // Helper methods for updating stats
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
  })  : defaultVisibleFields = defaultVisibleFields ?? [],
        stats = stats ?? UserStats(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        customBrewTypes = customBrewTypes ?? [];

  // Getters for enum conversion
  RatingScale get ratingScale => RatingScale.values[ratingScaleIndex];
  set ratingScale(RatingScale scale) => ratingScaleIndex = scale.index;

  ViewPreference get viewPreference => ViewPreference.values[viewPreferenceIndex];
  set viewPreference(ViewPreference pref) => viewPreferenceIndex = pref.index;

  // Get all brew types (default + custom)
  List<String> get allBrewTypes {
    return [...defaultBrewTypes, ...customBrewTypes];
  }

  // Update timestamp helper
  void touch() {
    updatedAt = DateTime.now();
  }

  // Convert to/from JSON for Firebase sync
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
