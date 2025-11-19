/// Application-wide constants and enums

// Rating scales
enum RatingScale {
  oneToFive,
  oneToTen,
  oneToHundred,
}

// View preferences for bag collection
enum ViewPreference {
  grid,
  list,
  rolodex,
}

// Coffee bag status
enum BagStatus {
  active,
  finished,
}

// Common brew types (user can add custom)
const List<String> defaultBrewTypes = [
  'Pour Over',
  'Espresso',
  'French Press',
  'AeroPress',
  'Cold Brew',
  'Moka Pot',
  'Drip Coffee',
  'Chemex',
  'V60',
  'Kalita Wave',
  'Siphon',
  'Turkish',
];

// Common grind levels
const List<String> grindLevels = [
  'Extra Fine',
  'Fine',
  'Medium-Fine',
  'Medium',
  'Medium-Coarse',
  'Coarse',
  'Extra Coarse',
];

// Predefined flavor tags
const List<String> defaultFlavorTags = [
  'fruity',
  'nutty',
  'chocolatey',
  'floral',
  'citrus',
  'berry',
  'caramel',
  'vanilla',
  'spicy',
  'earthy',
  'wine-like',
  'tea-like',
  'herbal',
  'sweet',
  'bitter',
  'acidic',
  'bright',
  'smooth',
  'creamy',
  'clean',
];

// Default visible fields for cup cards
const Map<String, bool> defaultFieldVisibility = {
  // Coffee Bag Info
  'coffeeName': true,
  'roaster': true,
  'farmer': false,
  'variety': true,
  'elevation': false,
  'beanAroma': true,

  // Brew Parameters
  'brewType': true,
  'equipment': true,
  'grindLevel': true,
  'waterTemp': true,
  'gramsUsed': true,
  'finalVolume': true,
  'ratio': true,
  'brewTime': false,
  'bloomTime': false,

  // Rating & Tasting
  'rating': true,
  'tastingNotes': true,
  'flavorTags': true,

  // Photos & Extras
  'photos': true,
  'bestRecipe': false,
};

// Cup field definitions for visibility settings dialog
class CupFieldDefinition {
  final String key;
  final String displayName;
  final String section;

  const CupFieldDefinition({
    required this.key,
    required this.displayName,
    required this.section,
  });
}

const List<CupFieldDefinition> cupFields = [
  // Coffee Bag Info section
  CupFieldDefinition(key: 'farmer', displayName: 'Farmer', section: 'Coffee Info'),
  CupFieldDefinition(key: 'variety', displayName: 'Variety', section: 'Coffee Info'),
  CupFieldDefinition(key: 'elevation', displayName: 'Elevation', section: 'Coffee Info'),
  CupFieldDefinition(key: 'beanAroma', displayName: 'Bean Aroma', section: 'Coffee Info'),

  // Brew Parameters section
  CupFieldDefinition(key: 'equipment', displayName: 'Equipment Setup', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'grindLevel', displayName: 'Grind Level', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'waterTemp', displayName: 'Water Temperature', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'gramsUsed', displayName: 'Grams Used', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'finalVolume', displayName: 'Final Volume', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'brewTime', displayName: 'Brew Time', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'bloomTime', displayName: 'Bloom Time', section: 'Brew Parameters'),

  // Rating & Tasting section
  CupFieldDefinition(key: 'rating', displayName: 'Rating', section: 'Rating & Tasting'),
  CupFieldDefinition(key: 'tastingNotes', displayName: 'Tasting Notes', section: 'Rating & Tasting'),
  CupFieldDefinition(key: 'flavorTags', displayName: 'Flavor Tags', section: 'Rating & Tasting'),

  // Photos & Extras section
  CupFieldDefinition(key: 'photos', displayName: 'Photos', section: 'Photos & Extras'),
  CupFieldDefinition(key: 'bestRecipe', displayName: 'Mark as Best Recipe', section: 'Photos & Extras'),
];

// App theme colors
class AppColors {
  static const primary = 0xFF6F4E37; // Coffee brown
  static const secondary = 0xFFA0826D; // Light brown
  static const accent = 0xFFD4A574; // Cream
  static const background = 0xFFFFF8F0; // Off-white
  static const cardBackground = 0xFFFFFFFF; // White
  static const textPrimary = 0xFF2C2C2C; // Dark gray
  static const textSecondary = 0xFF757575; // Medium gray
}

// Hive type IDs for adapters
class HiveTypeIds {
  static const userProfile = 0;
  static const userStats = 1;
  static const coffeeBag = 2;
  static const cup = 3;
  static const sharedCup = 4;
  static const ratingScale = 5;
  static const viewPreference = 6;
  static const bagStatus = 7;
  static const equipmentSetup = 8;
}

// Common equipment types
const List<String> grinderTypes = [
  'Burr (Conical)',
  'Burr (Flat)',
  'Hand Grinder',
  'Blade',
];

const List<String> waterTypes = [
  'Filtered Tap',
  'Bottled',
  'Reverse Osmosis',
  'Third Wave Water',
  'Tap Water',
  'Spring Water',
];

const List<String> filterTypes = [
  'Paper (Bleached)',
  'Paper (Unbleached)',
  'Metal',
  'Cloth',
];

const List<String> kettleTypes = [
  'Gooseneck Electric',
  'Gooseneck Stovetop',
  'Standard Electric',
  'Standard Stovetop',
];
