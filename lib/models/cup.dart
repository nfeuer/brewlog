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

  // Advanced Brewing Parameters (brew-type specific)
  @HiveField(26)
  int? preInfusionTimeSeconds; // Espresso: pre-infusion duration

  @HiveField(27)
  double? pressureBars; // Espresso: brew pressure

  @HiveField(28)
  double? yieldGrams; // Espresso: output weight

  @HiveField(29)
  double? bloomAmountGrams; // Pour over: bloom water amount

  @HiveField(30)
  String? pourSchedule; // Pour over: pour timing notes

  @HiveField(31)
  double? tds; // Total Dissolved Solids (requires refractometer)

  @HiveField(32)
  double? extractionYield; // Extraction yield percentage

  // Environmental Conditions
  @HiveField(33)
  double? roomTempCelsius; // Room temperature during brewing

  @HiveField(34)
  double? humidity; // Relative humidity percentage

  @HiveField(35)
  int? altitudeMeters; // Altitude of brewing location

  @HiveField(36)
  String? timeOfDay; // Time of day (morning, afternoon, evening, night)

  // SCA Cupping Scores (all optional, each 0-10 scale)
  @HiveField(37)
  double? cuppingFragrance; // Dry aroma

  @HiveField(38)
  double? cuppingAroma; // Wet aroma

  @HiveField(39)
  double? cuppingFlavor; // Overall flavor

  @HiveField(40)
  double? cuppingAftertaste; // Lingering flavors

  @HiveField(41)
  double? cuppingAcidity; // Acidity quality/intensity

  @HiveField(42)
  double? cuppingBody; // Mouthfeel/texture

  @HiveField(43)
  double? cuppingBalance; // How components work together

  @HiveField(44)
  double? cuppingSweetness; // Natural sweetness

  @HiveField(45)
  double? cuppingCleanCup; // Lack of defects

  @HiveField(46)
  double? cuppingUniformity; // Consistency

  @HiveField(47)
  double? cuppingOverall; // Holistic impression

  @HiveField(48)
  double? cuppingTotal; // Total SCA score (0-100, auto-calculated)

  @HiveField(49)
  String? cuppingDefects; // Notes on any defects

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
    this.preInfusionTimeSeconds,
    this.pressureBars,
    this.yieldGrams,
    this.bloomAmountGrams,
    this.pourSchedule,
    this.tds,
    this.extractionYield,
    this.roomTempCelsius,
    this.humidity,
    this.altitudeMeters,
    this.timeOfDay,
    this.cuppingFragrance,
    this.cuppingAroma,
    this.cuppingFlavor,
    this.cuppingAftertaste,
    this.cuppingAcidity,
    this.cuppingBody,
    this.cuppingBalance,
    this.cuppingSweetness,
    this.cuppingCleanCup,
    this.cuppingUniformity,
    this.cuppingOverall,
    this.cuppingTotal,
    this.cuppingDefects,
  })  : flavorTags = flavorTags ?? [],
        photoPaths = photoPaths ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Auto-calculate ratio if both grams and volume are provided
    _updateRatio();
    // Auto-calculate cupping total if individual scores are provided
    _updateCuppingTotal();
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

  // Auto-calculate SCA cupping total score (sum of all cupping scores)
  void _updateCuppingTotal() {
    final scores = [
      cuppingFragrance,
      cuppingAroma,
      cuppingFlavor,
      cuppingAftertaste,
      cuppingAcidity,
      cuppingBody,
      cuppingBalance,
      cuppingSweetness,
      cuppingCleanCup,
      cuppingUniformity,
      cuppingOverall,
    ];

    // Only calculate if at least one score is provided
    final validScores = scores.where((s) => s != null).toList();
    if (validScores.isNotEmpty) {
      // SCA scoring: each category 0-10, total = sum of all (max 110, but typically reported as 0-100)
      // We'll use simple sum for now
      cuppingTotal = validScores.fold<double>(0.0, (sum, score) => sum + score!);
    } else {
      cuppingTotal = null;
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
      'preInfusionTimeSeconds': preInfusionTimeSeconds,
      'pressureBars': pressureBars,
      'yieldGrams': yieldGrams,
      'bloomAmountGrams': bloomAmountGrams,
      'pourSchedule': pourSchedule,
      'tds': tds,
      'extractionYield': extractionYield,
      'roomTempCelsius': roomTempCelsius,
      'humidity': humidity,
      'altitudeMeters': altitudeMeters,
      'timeOfDay': timeOfDay,
      'cuppingFragrance': cuppingFragrance,
      'cuppingAroma': cuppingAroma,
      'cuppingFlavor': cuppingFlavor,
      'cuppingAftertaste': cuppingAftertaste,
      'cuppingAcidity': cuppingAcidity,
      'cuppingBody': cuppingBody,
      'cuppingBalance': cuppingBalance,
      'cuppingSweetness': cuppingSweetness,
      'cuppingCleanCup': cuppingCleanCup,
      'cuppingUniformity': cuppingUniformity,
      'cuppingOverall': cuppingOverall,
      'cuppingTotal': cuppingTotal,
      'cuppingDefects': cuppingDefects,
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
      preInfusionTimeSeconds: json['preInfusionTimeSeconds'] as int?,
      pressureBars: json['pressureBars']?.toDouble(),
      yieldGrams: json['yieldGrams']?.toDouble(),
      bloomAmountGrams: json['bloomAmountGrams']?.toDouble(),
      pourSchedule: json['pourSchedule'] as String?,
      tds: json['tds']?.toDouble(),
      extractionYield: json['extractionYield']?.toDouble(),
      roomTempCelsius: json['roomTempCelsius']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      altitudeMeters: json['altitudeMeters'] as int?,
      timeOfDay: json['timeOfDay'] as String?,
      cuppingFragrance: json['cuppingFragrance']?.toDouble(),
      cuppingAroma: json['cuppingAroma']?.toDouble(),
      cuppingFlavor: json['cuppingFlavor']?.toDouble(),
      cuppingAftertaste: json['cuppingAftertaste']?.toDouble(),
      cuppingAcidity: json['cuppingAcidity']?.toDouble(),
      cuppingBody: json['cuppingBody']?.toDouble(),
      cuppingBalance: json['cuppingBalance']?.toDouble(),
      cuppingSweetness: json['cuppingSweetness']?.toDouble(),
      cuppingCleanCup: json['cuppingCleanCup']?.toDouble(),
      cuppingUniformity: json['cuppingUniformity']?.toDouble(),
      cuppingOverall: json['cuppingOverall']?.toDouble(),
      cuppingTotal: json['cuppingTotal']?.toDouble(),
      cuppingDefects: json['cuppingDefects'] as String?,
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
    int? preInfusionTimeSeconds,
    double? pressureBars,
    double? yieldGrams,
    double? bloomAmountGrams,
    String? pourSchedule,
    double? tds,
    double? extractionYield,
    double? roomTempCelsius,
    double? humidity,
    int? altitudeMeters,
    String? timeOfDay,
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
      preInfusionTimeSeconds: preInfusionTimeSeconds ?? this.preInfusionTimeSeconds,
      pressureBars: pressureBars ?? this.pressureBars,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      bloomAmountGrams: bloomAmountGrams ?? this.bloomAmountGrams,
      pourSchedule: pourSchedule ?? this.pourSchedule,
      tds: tds ?? this.tds,
      extractionYield: extractionYield ?? this.extractionYield,
      roomTempCelsius: roomTempCelsius ?? this.roomTempCelsius,
      humidity: humidity ?? this.humidity,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      cuppingFragrance: cuppingFragrance,
      cuppingAroma: cuppingAroma,
      cuppingFlavor: cuppingFlavor,
      cuppingAftertaste: cuppingAftertaste,
      cuppingAcidity: cuppingAcidity,
      cuppingBody: cuppingBody,
      cuppingBalance: cuppingBalance,
      cuppingSweetness: cuppingSweetness,
      cuppingCleanCup: cuppingCleanCup,
      cuppingUniformity: cuppingUniformity,
      cuppingOverall: cuppingOverall,
      cuppingTotal: cuppingTotal,
      cuppingDefects: cuppingDefects,
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
      preInfusionTimeSeconds: preInfusionTimeSeconds,
      pressureBars: pressureBars,
      yieldGrams: yieldGrams,
      bloomAmountGrams: bloomAmountGrams,
      pourSchedule: pourSchedule,
      tds: tds,
      extractionYield: extractionYield,
      roomTempCelsius: roomTempCelsius,
      humidity: humidity,
      altitudeMeters: altitudeMeters,
      timeOfDay: timeOfDay,
      cuppingFragrance: cuppingFragrance,
      cuppingAroma: cuppingAroma,
      cuppingFlavor: cuppingFlavor,
      cuppingAftertaste: cuppingAftertaste,
      cuppingAcidity: cuppingAcidity,
      cuppingBody: cuppingBody,
      cuppingBalance: cuppingBalance,
      cuppingSweetness: cuppingSweetness,
      cuppingCleanCup: cuppingCleanCup,
      cuppingUniformity: cuppingUniformity,
      cuppingOverall: cuppingOverall,
      cuppingTotal: cuppingTotal,
      cuppingDefects: cuppingDefects,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
