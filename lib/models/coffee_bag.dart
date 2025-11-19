import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'coffee_bag.g.dart';

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
    this.bagStatusIndex = 0, // Default to active
    this.totalCups = 0,
    this.avgScore,
    this.bestCupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.fieldVisibility,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Getters for enum conversion
  BagStatus get status => BagStatus.values[bagStatusIndex];
  set status(BagStatus status) => bagStatusIndex = status.index;

  // Update timestamp helper
  void touch() {
    updatedAt = DateTime.now();
  }

  // Recalculate stats based on cups
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

  // Get display title (falls back to coffee name if custom title is empty)
  String get displayTitle {
    return customTitle.isNotEmpty ? customTitle : coffeeName;
  }

  // Convert to/from JSON for Firebase sync
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
      'status': status.name,
      'totalCups': totalCups,
      'avgScore': avgScore,
      'bestCupId': bestCupId,
      'fieldVisibility': fieldVisibility,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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

  // Create a copy with updated fields
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
