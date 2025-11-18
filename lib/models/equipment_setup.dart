import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'equipment_setup.g.dart';

@HiveType(typeId: HiveTypeIds.equipmentSetup)
class EquipmentSetup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name; // e.g., "Home Setup", "Travel Kit"

  // Grinder
  @HiveField(3)
  String? grinderBrand;

  @HiveField(4)
  String? grinderModel;

  @HiveField(5)
  String? grinderType; // Burr, Blade, Hand

  @HiveField(6)
  String? grinderNotes;

  // Brewer details
  @HiveField(7)
  String? brewerBrand;

  @HiveField(8)
  String? brewerModel;

  @HiveField(9)
  String? filterType; // "Bleached paper", "Metal", "Cloth"

  // Water
  @HiveField(10)
  String? waterType; // "Filtered", "Bottled", "Tap", "RO"

  @HiveField(11)
  double? waterTDS; // Total dissolved solids

  @HiveField(12)
  String? waterBrand; // "Third Wave Water", etc.

  // Scale
  @HiveField(13)
  String? scaleBrand;

  @HiveField(14)
  String? scaleModel;

  @HiveField(15)
  double? scaleAccuracy; // 0.1g, 0.01g

  // Kettle
  @HiveField(16)
  String? kettleBrand;

  @HiveField(17)
  String? kettleType; // "Gooseneck", "Electric", "Stovetop"

  @HiveField(18)
  bool? hasTemperatureControl;

  // Espresso-specific
  @HiveField(19)
  String? espressoMachine;

  @HiveField(20)
  double? boilerTemp;

  @HiveField(21)
  double? brewPressure; // in bars

  @HiveField(22)
  bool isDefault;

  @HiveField(23)
  DateTime createdAt;

  @HiveField(24)
  DateTime updatedAt;

  EquipmentSetup({
    required this.id,
    required this.userId,
    required this.name,
    this.grinderBrand,
    this.grinderModel,
    this.grinderType,
    this.grinderNotes,
    this.brewerBrand,
    this.brewerModel,
    this.filterType,
    this.waterType,
    this.waterTDS,
    this.waterBrand,
    this.scaleBrand,
    this.scaleModel,
    this.scaleAccuracy,
    this.kettleBrand,
    this.kettleType,
    this.hasTemperatureControl,
    this.espressoMachine,
    this.boilerTemp,
    this.brewPressure,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Get a summary of the equipment for display
  String get summary {
    final parts = <String>[];
    if (grinderBrand != null || grinderModel != null) {
      parts.add('${grinderBrand ?? ''} ${grinderModel ?? ''}'.trim());
    }
    if (brewerBrand != null || brewerModel != null) {
      parts.add('${brewerBrand ?? ''} ${brewerModel ?? ''}'.trim());
    }
    return parts.isEmpty ? 'No equipment added' : parts.join(' • ');
  }

  /// Get grinder display name
  String get grinderDisplayName {
    if (grinderBrand == null && grinderModel == null) return 'Not specified';
    return '${grinderBrand ?? ''} ${grinderModel ?? ''}'.trim();
  }

  /// Get brewer display name
  String get brewerDisplayName {
    if (brewerBrand == null && brewerModel == null) return 'Not specified';
    return '${brewerBrand ?? ''} ${brewerModel ?? ''}'.trim();
  }

  /// Update timestamp helper
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Convert to/from JSON for Firebase sync
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'grinderBrand': grinderBrand,
      'grinderModel': grinderModel,
      'grinderType': grinderType,
      'grinderNotes': grinderNotes,
      'brewerBrand': brewerBrand,
      'brewerModel': brewerModel,
      'filterType': filterType,
      'waterType': waterType,
      'waterTDS': waterTDS,
      'waterBrand': waterBrand,
      'scaleBrand': scaleBrand,
      'scaleModel': scaleModel,
      'scaleAccuracy': scaleAccuracy,
      'kettleBrand': kettleBrand,
      'kettleType': kettleType,
      'hasTemperatureControl': hasTemperatureControl,
      'espressoMachine': espressoMachine,
      'boilerTemp': boilerTemp,
      'brewPressure': brewPressure,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EquipmentSetup.fromJson(Map<String, dynamic> json) {
    return EquipmentSetup(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      grinderBrand: json['grinderBrand'] as String?,
      grinderModel: json['grinderModel'] as String?,
      grinderType: json['grinderType'] as String?,
      grinderNotes: json['grinderNotes'] as String?,
      brewerBrand: json['brewerBrand'] as String?,
      brewerModel: json['brewerModel'] as String?,
      filterType: json['filterType'] as String?,
      waterType: json['waterType'] as String?,
      waterTDS: json['waterTDS']?.toDouble(),
      waterBrand: json['waterBrand'] as String?,
      scaleBrand: json['scaleBrand'] as String?,
      scaleModel: json['scaleModel'] as String?,
      scaleAccuracy: json['scaleAccuracy']?.toDouble(),
      kettleBrand: json['kettleBrand'] as String?,
      kettleType: json['kettleType'] as String?,
      hasTemperatureControl: json['hasTemperatureControl'] as bool?,
      espressoMachine: json['espressoMachine'] as String?,
      boilerTemp: json['boilerTemp']?.toDouble(),
      brewPressure: json['brewPressure']?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  EquipmentSetup copyWith({
    String? name,
    String? grinderBrand,
    String? grinderModel,
    String? grinderType,
    String? grinderNotes,
    String? brewerBrand,
    String? brewerModel,
    String? filterType,
    String? waterType,
    double? waterTDS,
    String? waterBrand,
    String? scaleBrand,
    String? scaleModel,
    double? scaleAccuracy,
    String? kettleBrand,
    String? kettleType,
    bool? hasTemperatureControl,
    String? espressoMachine,
    double? boilerTemp,
    double? brewPressure,
    bool? isDefault,
  }) {
    return EquipmentSetup(
      id: id,
      userId: userId,
      name: name ?? this.name,
      grinderBrand: grinderBrand ?? this.grinderBrand,
      grinderModel: grinderModel ?? this.grinderModel,
      grinderType: grinderType ?? this.grinderType,
      grinderNotes: grinderNotes ?? this.grinderNotes,
      brewerBrand: brewerBrand ?? this.brewerBrand,
      brewerModel: brewerModel ?? this.brewerModel,
      filterType: filterType ?? this.filterType,
      waterType: waterType ?? this.waterType,
      waterTDS: waterTDS ?? this.waterTDS,
      waterBrand: waterBrand ?? this.waterBrand,
      scaleBrand: scaleBrand ?? this.scaleBrand,
      scaleModel: scaleModel ?? this.scaleModel,
      scaleAccuracy: scaleAccuracy ?? this.scaleAccuracy,
      kettleBrand: kettleBrand ?? this.kettleBrand,
      kettleType: kettleType ?? this.kettleType,
      hasTemperatureControl: hasTemperatureControl ?? this.hasTemperatureControl,
      espressoMachine: espressoMachine ?? this.espressoMachine,
      boilerTemp: boilerTemp ?? this.boilerTemp,
      brewPressure: brewPressure ?? this.brewPressure,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
