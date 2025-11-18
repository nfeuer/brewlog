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

  // Photos
  'photos': true,
};

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
}
