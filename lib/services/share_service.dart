import 'dart:convert';
import '../models/drink_recipe.dart';
import '../models/cup.dart';

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

      // Remove the ID, userId, and bagId so the imported cup gets new ones
      cupData.remove('id');
      cupData.remove('userId');
      cupData.remove('bagId');

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
}
