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
  'processingMethod': false,
  'region': false,
  'harvestDate': false,
  'roastLevel': false,
  'roastProfile': false,
  'beanSize': false,
  'certifications': false,

  // Brew Parameters
  'brewType': true,
  'equipment': true,
  'grindLevel': true,
  'waterTemp': true,
  'gramsUsed': true,
  'finalVolume': true,
  'ratio': true,
  'brewTime': false,

  // Advanced Brewing Parameters (brew-type specific, hidden by default)
  'bloomTime': false,
  'preInfusionTime': false,
  'pressureBars': false,
  'yieldGrams': false,
  'bloomAmount': false,
  'pourSchedule': false,
  'tds': false,
  'extractionYield': false,

  // Environmental Conditions (hidden by default)
  'roomTemp': false,
  'humidity': false,
  'altitude': false,
  'timeOfDay': false,

  // SCA Cupping Scores (hidden by default)
  'cuppingFragrance': false,
  'cuppingAroma': false,
  'cuppingFlavor': false,
  'cuppingAftertaste': false,
  'cuppingAcidity': false,
  'cuppingBody': false,
  'cuppingBalance': false,
  'cuppingSweetness': false,
  'cuppingCleanCup': false,
  'cuppingUniformity': false,
  'cuppingOverall': false,
  'cuppingTotal': false,
  'cuppingDefects': false,

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
  CupFieldDefinition(key: 'processingMethod', displayName: 'Processing Method', section: 'Coffee Info'),
  CupFieldDefinition(key: 'region', displayName: 'Region', section: 'Coffee Info'),
  CupFieldDefinition(key: 'harvestDate', displayName: 'Harvest Date', section: 'Coffee Info'),
  CupFieldDefinition(key: 'roastLevel', displayName: 'Roast Level', section: 'Coffee Info'),
  CupFieldDefinition(key: 'roastProfile', displayName: 'Roast Profile', section: 'Coffee Info'),
  CupFieldDefinition(key: 'beanSize', displayName: 'Bean Size', section: 'Coffee Info'),
  CupFieldDefinition(key: 'certifications', displayName: 'Certifications', section: 'Coffee Info'),

  // Brew Parameters section
  CupFieldDefinition(key: 'equipment', displayName: 'Equipment Setup', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'grindLevel', displayName: 'Grind Level', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'waterTemp', displayName: 'Water Temperature', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'gramsUsed', displayName: 'Grams Used', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'finalVolume', displayName: 'Final Volume', section: 'Brew Parameters'),
  CupFieldDefinition(key: 'brewTime', displayName: 'Brew Time', section: 'Brew Parameters'),

  // Advanced Brewing Parameters section (brew-type specific)
  CupFieldDefinition(key: 'bloomTime', displayName: 'Bloom Time', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'preInfusionTime', displayName: 'Pre-Infusion Time', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'pressureBars', displayName: 'Pressure (bars)', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'yieldGrams', displayName: 'Yield (grams)', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'bloomAmount', displayName: 'Bloom Amount (grams)', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'pourSchedule', displayName: 'Pour Schedule', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'tds', displayName: 'TDS', section: 'Advanced Brewing'),
  CupFieldDefinition(key: 'extractionYield', displayName: 'Extraction Yield (%)', section: 'Advanced Brewing'),

  // Environmental Conditions section
  CupFieldDefinition(key: 'roomTemp', displayName: 'Room Temperature', section: 'Environmental'),
  CupFieldDefinition(key: 'humidity', displayName: 'Humidity', section: 'Environmental'),
  CupFieldDefinition(key: 'altitude', displayName: 'Altitude', section: 'Environmental'),
  CupFieldDefinition(key: 'timeOfDay', displayName: 'Time of Day', section: 'Environmental'),

  // SCA Cupping Scores section
  CupFieldDefinition(key: 'cuppingFragrance', displayName: 'Fragrance/Aroma (Dry)', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingAroma', displayName: 'Aroma (Wet)', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingFlavor', displayName: 'Flavor', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingAftertaste', displayName: 'Aftertaste', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingAcidity', displayName: 'Acidity', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingBody', displayName: 'Body', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingBalance', displayName: 'Balance', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingSweetness', displayName: 'Sweetness', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingCleanCup', displayName: 'Clean Cup', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingUniformity', displayName: 'Uniformity', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingOverall', displayName: 'Overall', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingTotal', displayName: 'Total Score', section: 'SCA Cupping'),
  CupFieldDefinition(key: 'cuppingDefects', displayName: 'Defects Notes', section: 'SCA Cupping'),

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

// Processing methods for coffee beans
const List<String> processingMethods = [
  'Washed',
  'Natural',
  'Honey',
  'Semi-Washed',
  'Wet Hulled',
  'Anaerobic',
  'Carbonic Maceration',
  'Double Fermentation',
];

// Roast levels
const List<String> roastLevels = [
  'Light',
  'Light-Medium',
  'Medium',
  'Medium-Dark',
  'Dark',
  'French',
  'Italian',
];

// Time of day options
const List<String> timesOfDay = [
  'Morning',
  'Afternoon',
  'Evening',
  'Night',
];

// Common bean screen sizes
const List<String> beanSizes = [
  '10',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18',
  '19',
  '20',
  '14/16',
  '15/16',
  '16/17',
  '17/18',
  '18/19',
];

// Coffee certifications
const List<String> coffeeCertifications = [
  'Organic',
  'Fair Trade',
  'Rainforest Alliance',
  'Bird Friendly',
  'Direct Trade',
  'UTZ Certified',
  'Cup of Excellence',
];
