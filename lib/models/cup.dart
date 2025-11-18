import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'cup.g.dart';

@HiveType(typeId: HiveTypeIds.cup)
class Cup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bagId;

  @HiveField(2)
  String userId;

  // Brew Parameters
  @HiveField(3)
  String brewType; // from user-customizable picklist

  @HiveField(4)
  String? grindLevel;

  @HiveField(5)
  double? waterTempCelsius;

  @HiveField(6)
  double? gramsUsed;

  @HiveField(7)
  double? finalVolumeMl;

  @HiveField(8)
  double? ratio; // auto-calculated: finalVolumeMl / gramsUsed

  // Timing (optional fields)
  @HiveField(9)
  int? brewTimeSeconds;

  @HiveField(10)
  int? bloomTimeSeconds;

  // Rating (store all three scales)
  @HiveField(11)
  double? score1to5;

  @HiveField(12)
  double? score1to10;

  @HiveField(13)
  double? score1to100;

  // Tasting
  @HiveField(14)
  String? tastingNotes;

  @HiveField(15)
  List<String> flavorTags;

  // Photos
  @HiveField(16)
  List<String> photoPaths; // local paths or Firebase Storage URLs

  // Status
  @HiveField(17)
  bool isBest; // marked as best recipe for this bag

  // Sharing (for paid users)
  @HiveField(18)
  int shareCount;

  @HiveField(19)
  String? sharedByUserId; // if this cup was received via share

  @HiveField(20)
  String? sharedByUsername;

  // Metadata
  @HiveField(21)
  DateTime createdAt;

  @HiveField(22)
  DateTime updatedAt;

  // Custom title for the cup
  @HiveField(23)
  String? customTitle;

  // Equipment setup used for this brew
  @HiveField(24)
  String? equipmentSetupId;

  // Notes for adapting recipe to different equipment
  @HiveField(25)
  String? adaptationNotes;

  Cup({
    required this.id,
    required this.bagId,
    required this.userId,
    required this.brewType,
    this.grindLevel,
    this.waterTempCelsius,
    this.gramsUsed,
    this.finalVolumeMl,
    this.ratio,
    this.brewTimeSeconds,
    this.bloomTimeSeconds,
    this.score1to5,
    this.score1to10,
    this.score1to100,
    this.tastingNotes,
    List<String>? flavorTags,
    List<String>? photoPaths,
    this.isBest = false,
    this.shareCount = 0,
    this.sharedByUserId,
    this.sharedByUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.customTitle,
    this.equipmentSetupId,
    this.adaptationNotes,
  })  : flavorTags = flavorTags ?? [],
        photoPaths = photoPaths ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Auto-calculate ratio if both grams and volume are provided
    _updateRatio();
  }

  // Update timestamp helper
  void touch() {
    updatedAt = DateTime.now();
  }

  // Auto-calculate ratio
  void _updateRatio() {
    if (gramsUsed != null && gramsUsed! > 0 && finalVolumeMl != null) {
      ratio = finalVolumeMl! / gramsUsed!;
    } else {
      ratio = null;
    }
  }

  // Update rating based on user's preferred scale
  void updateRating(double value, RatingScale scale) {
    switch (scale) {
      case RatingScale.oneToFive:
        score1to5 = value;
        score1to10 = value * 2;
        score1to100 = value * 20;
        break;
      case RatingScale.oneToTen:
        score1to10 = value;
        score1to5 = value / 2;
        score1to100 = value * 10;
        break;
      case RatingScale.oneToHundred:
        score1to100 = value;
        score1to5 = value / 20;
        score1to10 = value / 10;
        break;
    }
    touch();
  }

  // Get rating based on user's preferred scale
  double? getRating(RatingScale scale) {
    switch (scale) {
      case RatingScale.oneToFive:
        return score1to5;
      case RatingScale.oneToTen:
        return score1to10;
      case RatingScale.oneToHundred:
        return score1to100;
    }
  }

  // Get formatted ratio string (e.g., "1:16.7")
  String get ratioString {
    if (ratio == null) return '-';
    return '1:${ratio!.toStringAsFixed(1)}';
  }

  // Get display title (falls back to brew type and date if no custom title)
  String get displayTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      return customTitle!;
    }
    return '$brewType - ${_formatDate(createdAt)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Check if this is a shared cup (received from another user)
  bool get isShared => sharedByUserId != null;

  // Convert to/from JSON for Firebase sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bagId': bagId,
      'userId': userId,
      'brewType': brewType,
      'grindLevel': grindLevel,
      'waterTempCelsius': waterTempCelsius,
      'gramsUsed': gramsUsed,
      'finalVolumeMl': finalVolumeMl,
      'ratio': ratio,
      'brewTimeSeconds': brewTimeSeconds,
      'bloomTimeSeconds': bloomTimeSeconds,
      'score1to5': score1to5,
      'score1to10': score1to10,
      'score1to100': score1to100,
      'tastingNotes': tastingNotes,
      'flavorTags': flavorTags,
      'photoPaths': photoPaths,
      'isBest': isBest,
      'shareCount': shareCount,
      'sharedByUserId': sharedByUserId,
      'sharedByUsername': sharedByUsername,
      'customTitle': customTitle,
      'equipmentSetupId': equipmentSetupId,
      'adaptationNotes': adaptationNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Cup.fromJson(Map<String, dynamic> json) {
    return Cup(
      id: json['id'] as String,
      bagId: json['bagId'] as String,
      userId: json['userId'] as String,
      brewType: json['brewType'] as String,
      grindLevel: json['grindLevel'] as String?,
      waterTempCelsius: json['waterTempCelsius']?.toDouble(),
      gramsUsed: json['gramsUsed']?.toDouble(),
      finalVolumeMl: json['finalVolumeMl']?.toDouble(),
      ratio: json['ratio']?.toDouble(),
      brewTimeSeconds: json['brewTimeSeconds'] as int?,
      bloomTimeSeconds: json['bloomTimeSeconds'] as int?,
      score1to5: json['score1to5']?.toDouble(),
      score1to10: json['score1to10']?.toDouble(),
      score1to100: json['score1to100']?.toDouble(),
      tastingNotes: json['tastingNotes'] as String?,
      flavorTags: List<String>.from(json['flavorTags'] ?? []),
      photoPaths: List<String>.from(json['photoPaths'] ?? []),
      isBest: json['isBest'] as bool? ?? false,
      shareCount: json['shareCount'] as int? ?? 0,
      sharedByUserId: json['sharedByUserId'] as String?,
      sharedByUsername: json['sharedByUsername'] as String?,
      customTitle: json['customTitle'] as String?,
      equipmentSetupId: json['equipmentSetupId'] as String?,
      adaptationNotes: json['adaptationNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a copy with updated fields
  Cup copyWith({
    String? brewType,
    String? grindLevel,
    double? waterTempCelsius,
    double? gramsUsed,
    double? finalVolumeMl,
    int? brewTimeSeconds,
    int? bloomTimeSeconds,
    double? score1to5,
    double? score1to10,
    double? score1to100,
    String? tastingNotes,
    List<String>? flavorTags,
    List<String>? photoPaths,
    bool? isBest,
    int? shareCount,
    String? customTitle,
    String? equipmentSetupId,
    String? adaptationNotes,
  }) {
    final cup = Cup(
      id: id,
      bagId: bagId,
      userId: userId,
      brewType: brewType ?? this.brewType,
      grindLevel: grindLevel ?? this.grindLevel,
      waterTempCelsius: waterTempCelsius ?? this.waterTempCelsius,
      gramsUsed: gramsUsed ?? this.gramsUsed,
      finalVolumeMl: finalVolumeMl ?? this.finalVolumeMl,
      brewTimeSeconds: brewTimeSeconds ?? this.brewTimeSeconds,
      bloomTimeSeconds: bloomTimeSeconds ?? this.bloomTimeSeconds,
      score1to5: score1to5 ?? this.score1to5,
      score1to10: score1to10 ?? this.score1to10,
      score1to100: score1to100 ?? this.score1to100,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      flavorTags: flavorTags ?? this.flavorTags,
      photoPaths: photoPaths ?? this.photoPaths,
      isBest: isBest ?? this.isBest,
      shareCount: shareCount ?? this.shareCount,
      sharedByUserId: sharedByUserId,
      sharedByUsername: sharedByUsername,
      customTitle: customTitle ?? this.customTitle,
      equipmentSetupId: equipmentSetupId ?? this.equipmentSetupId,
      adaptationNotes: adaptationNotes ?? this.adaptationNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
    return cup;
  }

  // Create a copy for sharing (strips personal info, generates new ID)
  Cup copyForSharing({
    required String newId,
    required String receiverUserId,
    required String sharerUsername,
  }) {
    return Cup(
      id: newId,
      bagId: '', // Shared cups don't belong to a bag initially
      userId: receiverUserId,
      brewType: brewType,
      grindLevel: grindLevel,
      waterTempCelsius: waterTempCelsius,
      gramsUsed: gramsUsed,
      finalVolumeMl: finalVolumeMl,
      ratio: ratio,
      brewTimeSeconds: brewTimeSeconds,
      bloomTimeSeconds: bloomTimeSeconds,
      score1to5: score1to5,
      score1to10: score1to10,
      score1to100: score1to100,
      tastingNotes: tastingNotes,
      flavorTags: List.from(flavorTags),
      photoPaths: List.from(photoPaths),
      isBest: false,
      shareCount: 0,
      sharedByUserId: userId,
      sharedByUsername: sharerUsername,
      customTitle: customTitle,
      equipmentSetupId: equipmentSetupId, // Include equipment info in shares
      adaptationNotes: adaptationNotes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
