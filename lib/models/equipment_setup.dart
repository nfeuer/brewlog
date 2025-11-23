import 'package:hive/hive.dart';
import '../utils/constants.dart';

// Part directive commented out until build_runner is executed
// part 'equipment_setup.g.dart';

/// Represents a saved equipment configuration for brewing coffee.
///
/// Equipment setups allow users to save their brewing equipment configurations
/// (grinder, brewer, scale, kettle, water) and quickly populate brew parameters.
/// Users can have multiple setups (e.g., "Home Setup", "Travel Kit", "Office").
///
/// **Tracked Equipment:**
/// - **Grinder**: Brand, model, type (burr/blade/hand), notes
/// - **Brewer**: Brand, model, filter type
/// - **Water**: Type, TDS, brand (e.g., Third Wave Water)
/// - **Scale**: Brand, model, accuracy
/// - **Kettle**: Brand, type, temperature control
/// - **Espresso**: Machine model, boiler temp, brew pressure
///
/// **Key Features:**
/// - Save multiple equipment configurations
/// - Mark one setup as default
/// - Auto-populate brew parameters from default setup
/// - Track equipment notes and specifications
/// - 25 tracked fields for comprehensive equipment tracking
///
/// **Usage:**
/// ```dart
/// final setup = EquipmentSetup(
///   id: uuid.v4(),
///   userId: user.id,
///   name: 'Home Setup',
///   grinderBrand: 'Baratza',
///   grinderModel: 'Virtuoso+',
///   grinderType: 'Burr (Conical)',
///   brewerBrand: 'Hario',
///   brewerModel: 'V60',
///   filterType: 'Paper (Unbleached)',
///   scaleBrand: 'Acaia',
///   scaleModel: 'Lunar',
///   isDefault: true,
/// );
/// await db.createEquipment(setup);
/// ```
///
/// **Default Setup:**
/// When creating a new cup, the default equipment setup automatically
/// populates the equipment field. Only one setup can be default at a time.
///
/// **See Also:**
/// - [Cup.equipmentSetupId] for linking cups to equipment
/// - [DatabaseService.getDefaultEquipment] to get default setup
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

  @HiveField(25)
  double? grinderMinSetting; // Minimum grind size setting (e.g., 0)

  @HiveField(26)
  double? grinderMaxSetting; // Maximum grind size setting (e.g., 50)

  @HiveField(27)
  double? grinderStepSize; // Step size: 1.0, 0.5, or 0.25

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
    this.grinderMinSetting,
    this.grinderMaxSetting,
    this.grinderStepSize,
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
      'grinderMinSetting': grinderMinSetting,
      'grinderMaxSetting': grinderMaxSetting,
      'grinderStepSize': grinderStepSize,
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
      grinderMinSetting: json['grinderMinSetting']?.toDouble(),
      grinderMaxSetting: json['grinderMaxSetting']?.toDouble(),
      grinderStepSize: json['grinderStepSize']?.toDouble(),
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
    double? grinderMinSetting,
    double? grinderMaxSetting,
    double? grinderStepSize,
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
      grinderMinSetting: grinderMinSetting ?? this.grinderMinSetting,
      grinderMaxSetting: grinderMaxSetting ?? this.grinderMaxSetting,
      grinderStepSize: grinderStepSize ?? this.grinderStepSize,
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
