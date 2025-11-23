import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'drink_recipe.g.dart';

/// Represents a saved coffee drink recipe (e.g., latte, cappuccino, iced coffee).
///
/// Drink recipes allow users to save their favorite coffee beverage combinations
/// and associate them with brew cups. Unlike [Cup] which tracks the brewing
/// process, DrinkRecipe focuses on the final drink composition (milk, syrups, etc.).
///
/// **Key Features:**
/// - Save drink recipes with custom names
/// - Track ingredients: milk, syrups, sweeteners, additions
/// - Usage counter for popular recipes
/// - QR code sharing with other users (premium)
/// - Link to cups via [Cup.drinkRecipeId]
///
/// **Example Recipes:**
/// - Vanilla Latte: Espresso + whole milk + vanilla syrup
/// - Iced Americano: Espresso + ice + water
/// - Spanish Latte: Espresso + condensed milk + whole milk
///
/// **Usage:**
/// ```dart
/// final recipe = DrinkRecipe(
///   id: uuid.v4(),
///   userId: user.id,
///   name: 'Vanilla Latte',
///   baseType: 'Espresso',
///   espressoShot: 'Double',
///   milkType: 'Whole Milk',
///   milkAmountMl: 200,
///   syrups: ['Vanilla'],
/// );
/// await db.createDrinkRecipe(recipe);
/// ```
///
/// **Sharing:**
/// Premium users can share recipes via:
/// - QR codes (encodes recipe JSON)
/// - Deep links (brewlog://drink_recipe?data=...)
///
/// **See Also:**
/// - [Cup] for brew tracking
/// - [ShareService] for QR code generation
@HiveType(typeId: HiveTypeIds.drinkRecipe)
class DrinkRecipe extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name; // e.g., "Vanilla Latte", "Iced Coffee"

  @HiveField(3)
  String? baseType; // e.g., "Espresso", "Drip", "Pour Over"

  @HiveField(4)
  String? milkType; // e.g., "Whole Milk", "Almond Milk", "Oat Milk"

  @HiveField(5)
  double? milkAmountMl; // Amount of milk in ml

  @HiveField(6)
  bool ice; // Whether the drink includes ice

  @HiveField(7)
  List<String> syrups; // Flavor syrups (e.g., "Vanilla", "Caramel")

  @HiveField(8)
  List<String> sweeteners; // Sweeteners (e.g., "Sugar", "Honey", "Stevia")

  @HiveField(9)
  List<String> otherAdditions; // Other additions (e.g., "Whiskey", "Tonic Water")

  @HiveField(10)
  String? instructions; // Optional preparation notes

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  int usageCount; // Number of times this recipe has been used

  @HiveField(14)
  String? espressoShot; // "Single" or "Double" for espresso-based drinks

  @HiveField(15)
  String? sharedByUsername; // Username of user who shared this recipe

  DrinkRecipe({
    required this.id,
    required this.userId,
    required this.name,
    this.baseType,
    this.milkType,
    this.milkAmountMl,
    this.ice = false,
    List<String>? syrups,
    List<String>? sweeteners,
    List<String>? otherAdditions,
    this.instructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.usageCount = 0,
    this.espressoShot,
    this.sharedByUsername,
  })  : syrups = syrups ?? [],
        sweeteners = sweeteners ?? [],
        otherAdditions = otherAdditions ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Update timestamp helper
  void touch() {
    updatedAt = DateTime.now();
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'baseType': baseType,
      'milkType': milkType,
      'milkAmountMl': milkAmountMl,
      'ice': ice,
      'syrups': syrups,
      'sweeteners': sweeteners,
      'otherAdditions': otherAdditions,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'usageCount': usageCount,
      'espressoShot': espressoShot,
      'sharedByUsername': sharedByUsername,
    };
  }

  factory DrinkRecipe.fromJson(Map<String, dynamic> json) {
    return DrinkRecipe(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      baseType: json['baseType'] as String?,
      milkType: json['milkType'] as String?,
      milkAmountMl: json['milkAmountMl']?.toDouble(),
      ice: json['ice'] as bool? ?? false,
      syrups: List<String>.from(json['syrups'] ?? []),
      sweeteners: List<String>.from(json['sweeteners'] ?? []),
      otherAdditions: List<String>.from(json['otherAdditions'] ?? []),
      instructions: json['instructions'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      usageCount: json['usageCount'] as int? ?? 0,
      espressoShot: json['espressoShot'] as String?,
      sharedByUsername: json['sharedByUsername'] as String?,
    );
  }

  // Get a summary of the recipe for display
  String get summary {
    final parts = <String>[];

    if (baseType != null) {
      if (espressoShot != null && baseType!.toLowerCase().contains('espresso')) {
        parts.add('$espressoShot $baseType');
      } else {
        parts.add(baseType!);
      }
    }
    if (milkType != null) {
      if (milkAmountMl != null) {
        parts.add('$milkType (${milkAmountMl!.toInt()}ml)');
      } else {
        parts.add(milkType!);
      }
    }
    if (ice) parts.add('Iced');
    if (syrups.isNotEmpty) parts.add(syrups.join(', '));
    if (sweeteners.isNotEmpty) parts.add(sweeteners.join(', '));
    if (otherAdditions.isNotEmpty) parts.add(otherAdditions.join(', '));

    return parts.isEmpty ? 'No details' : parts.join(' • ');
  }
}
