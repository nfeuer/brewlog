import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'coffee_bag.g.dart';

/// Represents a physical bag of coffee beans purchased and tracked by the user.
///
/// This is the primary entity for organizing brews. Each bag contains comprehensive
/// information about the coffee's origin, processing, roasting, and tracking details.
/// All cups (brews) are associated with a specific bag.
///
/// **Key Features:**
/// - 31 tracked fields from basic info to detailed bean characteristics
/// - Automatic statistics calculation (total cups, average score, best cup)
/// - Status tracking (active vs finished bags)
/// - Customizable field visibility per bag
/// - Full JSON serialization for cloud sync
///
/// **Lifecycle:**
/// 1. Created when user purchases new coffee
/// 2. Marked active and tracked as cups are brewed
/// 3. Statistics auto-update as cups are added/removed
/// 4. Marked finished when bag is empty
///
/// **Example:**
/// ```dart
/// final bag = CoffeeBag(
///   id: uuid.v4(),
///   userId: currentUser.id,
///   customTitle: 'Morning Blend',
///   coffeeName: 'Ethiopia Yirgacheffe',
///   roaster: 'Local Roasters',
///   variety: 'Heirloom',
///   processingMethods: ['Washed'],
///   roastLevel: 'Light',
/// );
/// await db.createBag(bag);
/// ```
@HiveType(typeId: HiveTypeIds.coffeeBag)
class CoffeeBag extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  // Display Info
  @HiveField(2)
  String customTitle;

  @HiveField(3)
  String? labelPhotoPath; // local path or Firebase Storage URL

  // Coffee Details (carries over to all cups in this bag)
  @HiveField(4)
  String coffeeName;

  @HiveField(5)
  String roaster;

  @HiveField(6)
  String? farmer;

  @HiveField(7)
  String? variety;

  @HiveField(8)
  String? elevation;

  @HiveField(9)
  String? beanAroma;

  // Purchase & Tracking
  @HiveField(10)
  DateTime? datePurchased;

  @HiveField(11)
  double? price;

  @HiveField(12)
  double? bagSizeGrams;

  @HiveField(13)
  DateTime? roastDate;

  @HiveField(14)
  DateTime? openDate;

  @HiveField(15)
  DateTime? finishedDate;

  @HiveField(16)
  int bagStatusIndex; // Store as index for Hive compatibility

  // Calculated Stats
  @HiveField(17)
  int totalCups;

  @HiveField(18)
  double? avgScore;

  @HiveField(19)
  String? bestCupId;

  @HiveField(20)
  DateTime createdAt;

  @HiveField(21)
  DateTime updatedAt;

  // Field visibility settings for this bag (overrides user defaults)
  @HiveField(22)
  Map<String, bool>? fieldVisibility;

  @HiveField(23)
  int? recommendedRestDays; // Days to rest after roasting

  // Additional Bean Details
  @HiveField(24)
  List<String>? processingMethods; // Multiple selections: Washed, Natural, Honey, Anaerobic

  @HiveField(25)
  String? region; // Region/country/farm location

  @HiveField(26)
  DateTime? harvestDate; // When the coffee was harvested

  @HiveField(27)
  String? roastLevel; // Light, Medium, Dark, or numeric (e.g., "2/5")

  @HiveField(28)
  String? roastProfile; // Roast profile notes (development time, etc.)

  @HiveField(29)
  String? beanSize; // Screen size (e.g., "17/18")

  @HiveField(30)
  List<String>? certifications; // Organic, Fair Trade, etc.

  @HiveField(31)
  String? customProcessingMethod; // Custom processing method text

  CoffeeBag({
    required this.id,
    required this.userId,
    required this.customTitle,
    this.labelPhotoPath,
    required this.coffeeName,
    required this.roaster,
    this.farmer,
    this.variety,
    this.elevation,
    this.beanAroma,
    this.datePurchased,
    this.price,
    this.bagSizeGrams,
    this.roastDate,
    this.openDate,
    this.finishedDate,
    this.recommendedRestDays,
    this.processingMethods,
    this.customProcessingMethod,
    this.region,
    this.harvestDate,
    this.roastLevel,
    this.roastProfile,
    this.beanSize,
    this.certifications,
    this.bagStatusIndex = 0, // Default to active
    this.totalCups = 0,
    this.avgScore,
    this.bestCupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.fieldVisibility,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Converts the bag status index to a [BagStatus] enum value.
  ///
  /// Hive stores enums as integers, so this getter converts back to the enum.
  BagStatus get status => BagStatus.values[bagStatusIndex];

  /// Sets the bag status and stores it as an index for Hive compatibility.
  set status(BagStatus status) => bagStatusIndex = status.index;

  /// Updates the [updatedAt] timestamp to the current time.
  ///
  /// Call this whenever the bag is modified to maintain accurate timestamps.
  /// Most update operations call this automatically.
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Recalculates and updates statistics based on the cups in this bag.
  ///
  /// This method is typically called by [DatabaseService] after cups are
  /// added, removed, or updated for this bag.
  ///
  /// **Parameters:**
  /// - [cups]: List of Cup objects belonging to this bag
  /// - [newAvgScore]: Pre-calculated average score (optional)
  /// - [newBestCupId]: ID of the best-rated cup (optional)
  ///
  /// **Updates:**
  /// - [totalCups]: Total count of cups
  /// - [avgScore]: Average rating across all cups
  /// - [bestCupId]: ID of the highest-rated cup
  /// - [updatedAt]: Timestamp automatically updated
  void updateStats({
    required List<dynamic> cups, // List of Cup objects
    double? newAvgScore,
    String? newBestCupId,
  }) {
    totalCups = cups.length;
    if (newAvgScore != null) avgScore = newAvgScore;
    if (newBestCupId != null) bestCupId = newBestCupId;
    touch();
  }

  /// Returns the display title for this bag.
  ///
  /// Falls back to [coffeeName] if [customTitle] is empty.
  /// This allows users to have both a custom nickname and the official name.
  ///
  /// **Example:**
  /// ```dart
  /// bag.customTitle = 'Daily Brew';
  /// bag.coffeeName = 'Ethiopia Yirgacheffe';
  /// print(bag.displayTitle); // 'Daily Brew'
  ///
  /// bag.customTitle = '';
  /// print(bag.displayTitle); // 'Ethiopia Yirgacheffe'
  /// ```
  String get displayTitle {
    return customTitle.isNotEmpty ? customTitle : coffeeName;
  }

  /// Converts this bag to a JSON map for Firebase synchronization.
  ///
  /// **Usage:**
  /// - Cloud sync for premium users
  /// - Data export features
  /// - Deep link sharing
  ///
  /// **Note:** Converts enums to string names and DateTime to ISO 8601 format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'customTitle': customTitle,
      'labelPhotoPath': labelPhotoPath,
      'coffeeName': coffeeName,
      'roaster': roaster,
      'farmer': farmer,
      'variety': variety,
      'elevation': elevation,
      'beanAroma': beanAroma,
      'datePurchased': datePurchased?.toIso8601String(),
      'price': price,
      'bagSizeGrams': bagSizeGrams,
      'roastDate': roastDate?.toIso8601String(),
      'openDate': openDate?.toIso8601String(),
      'finishedDate': finishedDate?.toIso8601String(),
      'recommendedRestDays': recommendedRestDays,
      'processingMethods': processingMethods,
      'customProcessingMethod': customProcessingMethod,
      'region': region,
      'harvestDate': harvestDate?.toIso8601String(),
      'roastLevel': roastLevel,
      'roastProfile': roastProfile,
      'beanSize': beanSize,
      'certifications': certifications,
      'status': status.name,
      'totalCups': totalCups,
      'avgScore': avgScore,
      'bestCupId': bestCupId,
      'fieldVisibility': fieldVisibility,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a [CoffeeBag] instance from a JSON map.
  ///
  /// Used for Firebase sync and data import. Handles:
  /// - DateTime parsing from ISO 8601 strings
  /// - Enum conversion from string names
  /// - Null safety for optional fields
  /// - Migration from old field names (e.g., single processingMethod to processingMethods list)
  ///
  /// **Example:**
  /// ```dart
  /// final json = await firestore.collection('bags').doc(id).get();
  /// final bag = CoffeeBag.fromJson(json.data()!);
  /// ```
  factory CoffeeBag.fromJson(Map<String, dynamic> json) {
    return CoffeeBag(
      id: json['id'] as String,
      userId: json['userId'] as String,
      customTitle: json['customTitle'] as String,
      labelPhotoPath: json['labelPhotoPath'] as String?,
      coffeeName: json['coffeeName'] as String,
      roaster: json['roaster'] as String,
      farmer: json['farmer'] as String?,
      variety: json['variety'] as String?,
      elevation: json['elevation'] as String?,
      beanAroma: json['beanAroma'] as String?,
      datePurchased: json['datePurchased'] != null
          ? DateTime.parse(json['datePurchased'] as String)
          : null,
      price: json['price']?.toDouble(),
      bagSizeGrams: json['bagSizeGrams']?.toDouble(),
      roastDate: json['roastDate'] != null
          ? DateTime.parse(json['roastDate'] as String)
          : null,
      openDate: json['openDate'] != null
          ? DateTime.parse(json['openDate'] as String)
          : null,
      finishedDate: json['finishedDate'] != null
          ? DateTime.parse(json['finishedDate'] as String)
          : null,
      recommendedRestDays: json['recommendedRestDays'] as int?,
      processingMethods: json['processingMethods'] != null
          ? List<String>.from(json['processingMethods'])
          : (json['processingMethod'] != null ? [json['processingMethod'] as String] : null), // Migration from old field
      customProcessingMethod: json['customProcessingMethod'] as String?,
      region: json['region'] as String?,
      harvestDate: json['harvestDate'] != null
          ? DateTime.parse(json['harvestDate'] as String)
          : null,
      roastLevel: json['roastLevel'] as String?,
      roastProfile: json['roastProfile'] as String?,
      beanSize: json['beanSize'] as String?,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : null,
      bagStatusIndex:
          BagStatus.values.indexWhere((e) => e.name == json['status']),
      totalCups: json['totalCups'] as int? ?? 0,
      avgScore: json['avgScore']?.toDouble(),
      bestCupId: json['bestCupId'] as String?,
      fieldVisibility: json['fieldVisibility'] != null
          ? Map<String, bool>.from(json['fieldVisibility'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Creates a copy of this bag with specified fields updated.
  ///
  /// This is the preferred method for updating bags because it:
  /// - Maintains immutability patterns
  /// - Preserves unchanged fields
  /// - Automatically updates [updatedAt] timestamp
  /// - Keeps original [id], [userId], [createdAt]
  ///
  /// **Example:**
  /// ```dart
  /// final updated = bag.copyWith(
  ///   status: BagStatus.finished,
  ///   finishedDate: DateTime.now(),
  /// );
  /// await db.updateBag(updated);
  /// ```
  CoffeeBag copyWith({
    String? customTitle,
    String? labelPhotoPath,
    String? coffeeName,
    String? roaster,
    String? farmer,
    String? variety,
    String? elevation,
    String? beanAroma,
    DateTime? datePurchased,
    double? price,
    double? bagSizeGrams,
    DateTime? roastDate,
    DateTime? openDate,
    DateTime? finishedDate,
    int? recommendedRestDays,
    List<String>? processingMethods,
    String? customProcessingMethod,
    String? region,
    DateTime? harvestDate,
    String? roastLevel,
    String? roastProfile,
    String? beanSize,
    List<String>? certifications,
    BagStatus? status,
    int? totalCups,
    double? avgScore,
    String? bestCupId,
    Map<String, bool>? fieldVisibility,
  }) {
    return CoffeeBag(
      id: id,
      userId: userId,
      customTitle: customTitle ?? this.customTitle,
      labelPhotoPath: labelPhotoPath ?? this.labelPhotoPath,
      coffeeName: coffeeName ?? this.coffeeName,
      roaster: roaster ?? this.roaster,
      farmer: farmer ?? this.farmer,
      variety: variety ?? this.variety,
      elevation: elevation ?? this.elevation,
      beanAroma: beanAroma ?? this.beanAroma,
      datePurchased: datePurchased ?? this.datePurchased,
      price: price ?? this.price,
      bagSizeGrams: bagSizeGrams ?? this.bagSizeGrams,
      roastDate: roastDate ?? this.roastDate,
      openDate: openDate ?? this.openDate,
      finishedDate: finishedDate ?? this.finishedDate,
      recommendedRestDays: recommendedRestDays ?? this.recommendedRestDays,
      processingMethods: processingMethods ?? this.processingMethods,
      customProcessingMethod: customProcessingMethod ?? this.customProcessingMethod,
      region: region ?? this.region,
      harvestDate: harvestDate ?? this.harvestDate,
      roastLevel: roastLevel ?? this.roastLevel,
      roastProfile: roastProfile ?? this.roastProfile,
      beanSize: beanSize ?? this.beanSize,
      certifications: certifications ?? this.certifications,
      bagStatusIndex: status?.index ?? bagStatusIndex,
      totalCups: totalCups ?? this.totalCups,
      avgScore: avgScore ?? this.avgScore,
      bestCupId: bestCupId ?? this.bestCupId,
      fieldVisibility: fieldVisibility ?? this.fieldVisibility,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
