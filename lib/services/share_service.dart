import 'dart:convert';
import '../models/drink_recipe.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';

/// Service for sharing cups and recipes via QR codes and deep links.
///
/// **Premium Feature:** QR code sharing is only available to paid users.
///
/// This service provides encoding/decoding functionality for sharing:
/// - Drink recipes
/// - Brew cups (without photos for QR size constraints)
///
/// **Sharing Methods:**
///
/// 1. **QR Codes:**
///    - Encode object to JSON string
///    - Generate QR code with qr_flutter package
///    - Scan QR with mobile_scanner package
///    - Decode JSON string back to object
///
/// 2. **Deep Links:**
///    - Create brewlog:// URLs with encoded data
///    - Handle incoming links via app_links package
///    - Parse and import data
///
/// **Data Format:**
/// ```json
/// {
///   "type": "drink_recipe" | "cup",
///   "version": 1,
///   "data": { ... object JSON ... }
/// }
/// ```
///
/// **Version Management:**
/// - Current version: 1
/// - Future versions can have different data structures
/// - Decoder validates version compatibility
///
/// **Usage Examples:**
///
/// **Encoding a recipe:**
/// ```dart
/// final qrData = ShareService.encodeDrinkRecipe(recipe, sharerUsername: user.username);
/// // Display in QrImageView widget
/// ```
///
/// **Decoding from QR:**
/// ```dart
/// final recipe = ShareService.decodeDrinkRecipe(scannedData);
/// if (recipe != null) {
///   await db.createDrinkRecipe(recipe);
/// }
/// ```
///
/// **Creating deep link:**
/// ```dart
/// final url = ShareService.encodeShareUrl('cup', cupJson);
/// // Returns: brewlog://cup?data=<base64>
/// await Share.share(url);
/// ```
///
/// **Security Notes:**
/// - Photos are excluded from cup shares (device-specific paths)
/// - IDs and userIds are stripped on import (new IDs generated)
/// - Sharer username is preserved for attribution
/// - No sensitive user data is shared
///
/// **See Also:**
/// - [SharedCup] for storing imported cups
/// - [ScanQrScreen] for QR code scanning
/// - [main.dart] deep link handling in _handleDeepLink()
class ShareService {
  /// Encode a DrinkRecipe to JSON string for sharing
  static String encodeDrinkRecipe(DrinkRecipe recipe, {String? sharerUsername}) {
    final recipeJson = recipe.toJson();

    // Add the sharer's username if provided
    if (sharerUsername != null) {
      recipeJson['sharedByUsername'] = sharerUsername;
    }

    final Map<String, dynamic> shareData = {
      'type': 'drink_recipe',
      'version': 1,
      'data': recipeJson,
    };
    return jsonEncode(shareData);
  }

  /// Decode a DrinkRecipe from JSON string
  static DrinkRecipe? decodeDrinkRecipe(String jsonString) {
    try {
      final Map<String, dynamic> shareData = jsonDecode(jsonString);

      // Validate the data type
      if (shareData['type'] != 'drink_recipe') {
        throw Exception('Invalid share data type: ${shareData['type']}');
      }

      // Check version compatibility (for future updates)
      final int version = shareData['version'] ?? 1;
      if (version > 1) {
        throw Exception('Unsupported share data version: $version');
      }

      // Decode the recipe data
      final Map<String, dynamic> recipeData = shareData['data'];

      // Remove the ID and userId so the imported recipe gets new ones
      recipeData.remove('id');
      recipeData.remove('userId');

      return DrinkRecipe.fromJson(recipeData);
    } catch (e) {
      print('Error decoding drink recipe: $e');
      return null;
    }
  }

  /// Encode a Cup to JSON string for sharing (without photos)
  static String encodeCup(Cup cup, {String? sharerUsername}) {
    final cupJson = cup.toJson();

    // Add the sharer's username if provided
    if (sharerUsername != null) {
      cupJson['sharedByUsername'] = sharerUsername;
    }

    final Map<String, dynamic> shareData = {
      'type': 'cup',
      'version': 1,
      'data': cupJson,
    };
    return jsonEncode(shareData);
  }

  /// Decode a Cup from JSON string
  static Cup? decodeCup(String jsonString) {
    try {
      final Map<String, dynamic> shareData = jsonDecode(jsonString);

      // Validate the data type
      if (shareData['type'] != 'cup') {
        throw Exception('Invalid share data type: ${shareData['type']}');
      }

      // Check version compatibility (for future updates)
      final int version = shareData['version'] ?? 1;
      if (version > 1) {
        throw Exception('Unsupported share data version: $version');
      }

      // Decode the cup data
      final Map<String, dynamic> cupData = shareData['data'];

      // Preserve original IDs for SharedCup reference, but mark that they're from sharing
      // The SharedCup model will store these separately as originalCupId/originalUserId
      // If missing, use placeholder values (shouldn't happen with properly encoded data)
      if (!cupData.containsKey('id')) {
        cupData['id'] = 'shared-cup';
      }
      if (!cupData.containsKey('userId')) {
        cupData['userId'] = 'shared-user';
      }
      if (!cupData.containsKey('bagId')) {
        cupData['bagId'] = 'shared-bag';
      }

      // Photos won't transfer via QR code (device-specific paths)
      cupData['photoPaths'] = [];

      return Cup.fromJson(cupData);
    } catch (e) {
      print('Error decoding cup: $e');
      return null;
    }
  }

  /// Create a deep link URL for sharing a DrinkRecipe
  static String createDrinkRecipeDeepLink(DrinkRecipe recipe, {String? sharerUsername}) {
    final encodedData = Uri.encodeComponent(encodeDrinkRecipe(recipe, sharerUsername: sharerUsername));
    return 'brewlog://share/drink_recipe?data=$encodedData';
  }

  /// Create a deep link URL for sharing a Cup
  static String createCupDeepLink(Cup cup, {String? sharerUsername}) {
    final encodedData = Uri.encodeComponent(encodeCup(cup, sharerUsername: sharerUsername));
    return 'brewlog://share/cup?data=$encodedData';
  }

  /// Parse a deep link URL and extract the shared data
  static Map<String, dynamic>? parseDeepLink(String url) {
    try {
      final uri = Uri.parse(url);

      // Validate scheme
      if (uri.scheme != 'brewlog') {
        return null;
      }

      // Validate host
      if (uri.host != 'share') {
        return null;
      }

      // Get the type from the path
      final type = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      if (type == null) {
        return null;
      }

      // Get the encoded data from query parameter
      final encodedData = uri.queryParameters['data'];
      if (encodedData == null) {
        return null;
      }

      // Decode the data
      final jsonString = Uri.decodeComponent(encodedData);

      return {
        'type': type,
        'data': jsonString,
      };
    } catch (e) {
      print('Error parsing deep link: $e');
      return null;
    }
  }

  /// Estimate the size of encoded data in bytes
  static int estimateDataSize(String jsonString) {
    return utf8.encode(jsonString).length;
  }

  /// Remove null values from a JSON map recursively
  static Map<String, dynamic> _removeNullValues(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    json.forEach((key, value) {
      if (value != null) {
        if (value is Map<String, dynamic>) {
          final nested = _removeNullValues(value);
          if (nested.isNotEmpty) {
            result[key] = nested;
          }
        } else if (value is List) {
          // Keep non-empty lists
          if (value.isNotEmpty) {
            result[key] = value;
          }
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  /// Encode a Cup with its CoffeeBag data for sharing
  /// This is the preferred method for sharing cups as it includes bag context
  static String encodeCupWithBag(Cup cup, CoffeeBag? bag, {String? sharerUsername}) {
    final cupJson = cup.toJson();

    // Remove null values to reduce data size
    final cleanedCupJson = _removeNullValues(cupJson);

    // Add the sharer's username if provided
    if (sharerUsername != null) {
      cleanedCupJson['sharedByUsername'] = sharerUsername;
    }

    // Include selected bag fields if bag is provided
    Map<String, dynamic>? bagData;
    if (bag != null) {
      bagData = _removeNullValues({
        'coffeeName': bag.coffeeName,
        'roaster': bag.roaster,
        'roastLevel': bag.roastLevel,
        'processingMethods': bag.processingMethods,
        'beanAroma': bag.beanAroma,
      });
    }

    final Map<String, dynamic> shareData = {
      'type': 'cup_with_bag',
      'version': 1,
      'data': {
        'cup': cleanedCupJson,
        if (bagData != null && bagData.isNotEmpty) 'bag': bagData,
      },
    };
    return jsonEncode(shareData);
  }

  /// Decode a Cup with bag data from JSON string
  static Map<String, dynamic>? decodeCupWithBag(String jsonString) {
    try {
      final Map<String, dynamic> shareData = jsonDecode(jsonString);

      // Support both new 'cup_with_bag' and legacy 'cup' formats
      if (shareData['type'] != 'cup_with_bag' && shareData['type'] != 'cup') {
        throw Exception('Invalid share data type: ${shareData['type']}');
      }

      // Check version compatibility
      final int version = shareData['version'] ?? 1;
      if (version > 1) {
        throw Exception('Unsupported share data version: $version');
      }

      final Map<String, dynamic> data = shareData['data'];

      // Handle both formats
      Map<String, dynamic> cupData;
      Map<String, dynamic>? bagData;

      if (shareData['type'] == 'cup_with_bag') {
        cupData = data['cup'];
        bagData = data['bag'];
      } else {
        // Legacy format - just cup data
        cupData = data;
      }

      // Preserve original IDs for SharedCup reference
      if (!cupData.containsKey('id')) {
        cupData['id'] = 'shared-cup';
      }
      if (!cupData.containsKey('userId')) {
        cupData['userId'] = 'shared-user';
      }
      if (!cupData.containsKey('bagId')) {
        cupData['bagId'] = 'shared-bag';
      }

      // Photos won't transfer via QR code
      cupData['photoPaths'] = [];

      final cup = Cup.fromJson(cupData);

      return {
        'cup': cup,
        'bagData': bagData,
      };
    } catch (e) {
      print('Error decoding cup with bag: $e');
      return null;
    }
  }

  /// Create a deep link URL for sharing a Cup with bag data
  static String createCupWithBagDeepLink(Cup cup, CoffeeBag? bag, {String? sharerUsername}) {
    final encodedData = Uri.encodeComponent(encodeCupWithBag(cup, bag, sharerUsername: sharerUsername));
    return 'brewlog://share/cup?data=$encodedData';
  }
}
