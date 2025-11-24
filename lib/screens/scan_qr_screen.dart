import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../models/drink_recipe.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';
import '../models/shared_cup.dart';
import '../services/share_service.dart';
import '../providers/drink_recipes_provider.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../providers/shared_cups_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';

/// Screen for scanning QR codes to import shared data
class ScanQRScreen extends ConsumerStatefulWidget {
  const ScanQRScreen({super.key});

  @override
  ConsumerState<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends ConsumerState<ScanQRScreen> {
  bool _isProcessing = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller?.switchCamera(),
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The code will be scanned automatically',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _processScannedData(rawValue);
    } catch (e) {
      if (mounted) {
        _showError('Failed to process QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processScannedData(String data) async {
    // Try to decode as DrinkRecipe
    final DrinkRecipe? recipe = ShareService.decodeDrinkRecipe(data);
    if (recipe != null) {
      await _importDrinkRecipe(recipe);
      return;
    }

    // Try to decode as Cup with bag data (new format)
    final cupWithBagData = ShareService.decodeCupWithBag(data);
    if (cupWithBagData != null) {
      final Cup cup = cupWithBagData['cup'] as Cup;
      final Map<String, dynamic>? bagData = cupWithBagData['bagData'] as Map<String, dynamic>?;
      await _importCup(cup, bagData: bagData);
      return;
    }

    // Try to parse as deep link
    final deepLinkData = ShareService.parseDeepLink(data);
    if (deepLinkData != null) {
      final String type = deepLinkData['type'];
      final String jsonData = deepLinkData['data'];

      if (type == 'drink_recipe') {
        final DrinkRecipe? recipe = ShareService.decodeDrinkRecipe(jsonData);
        if (recipe != null) {
          await _importDrinkRecipe(recipe);
          return;
        }
      } else if (type == 'cup') {
        final cupWithBagData = ShareService.decodeCupWithBag(jsonData);
        if (cupWithBagData != null) {
          final Cup cup = cupWithBagData['cup'] as Cup;
          final Map<String, dynamic>? bagData = cupWithBagData['bagData'] as Map<String, dynamic>?;
          await _importCup(cup, bagData: bagData);
          return;
        }
      }
    }

    // If we get here, the QR code wasn't recognized
    if (mounted) {
      _showError('This QR code is not a valid BrewLog share code');
    }
  }

  Future<void> _importDrinkRecipe(DrinkRecipe recipe) async {
    // Show confirmation dialog
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Import this drink recipe?'),
            const SizedBox(height: 16),
            Text(
              recipe.name,
              style: AppTextStyles.cardTitle,
            ),
            if (recipe.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.summary,
                style: AppTextStyles.cardSubtitle,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Add the recipe
      await ref.read(drinkRecipesProvider.notifier).createRecipe(recipe);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${recipe.name}" imported successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to import recipe: $e');
      }
    }
  }

  Future<void> _importCup(Cup cup, {Map<String, dynamic>? bagData}) async {
    if (!mounted) return;

    // Get current user
    final currentUser = ref.read(userProfileProvider);
    if (currentUser == null) {
      _showError('User not found');
      return;
    }

    // Show confirmation dialog with cup preview
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Shared Cup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Import this cup to your Shared tab?'),
              const SizedBox(height: 16),
              // Cup preview with bag data if available
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show bag info if available
                    if (bagData != null) ...[
                      Text(
                        'Coffee',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      if (bagData['coffeeName'] != null)
                        Text(
                          bagData['coffeeName'] as String,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      if (bagData['roaster'] != null)
                        Text(
                          'by ${bagData['roaster']}',
                          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        ),
                      if (bagData['roastLevel'] != null)
                        Text(
                          'Roast: ${bagData['roastLevel']}',
                          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Brew Method',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cup.brewType,
                      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                    ),
                    if (cup.score1to100 != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${cup.score1to100}/100',
                            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (cup.tastingNotes != null && cup.tastingNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        cup.tastingNotes!,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (cup.sharedByUsername != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Shared by @${cup.sharedByUsername}',
                        style: AppTextStyles.cardSubtitle.copyWith(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Create a SharedCup
      const uuid = Uuid();
      final sharedCup = SharedCup(
        id: uuid.v4(),
        originalCupId: cup.id,
        originalUserId: cup.userId,
        originalUsername: cup.sharedByUsername ?? 'Unknown',
        receivedByUserId: currentUser.id,
        cupData: cup,
        sharedAt: DateTime.now(),
      );

      // Save to shared cups
      await ref.read(sharedCupsProvider.notifier).addSharedCup(sharedCup);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cup imported to Shared tab${cup.sharedByUsername != null ? ' from @${cup.sharedByUsername}' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to import cup: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
