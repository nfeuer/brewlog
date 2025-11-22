import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/drink_recipe.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';
import '../services/share_service.dart';
import '../providers/drink_recipes_provider.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
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

    // Try to decode as Cup
    final Cup? cup = ShareService.decodeCup(data);
    if (cup != null) {
      await _importCup(cup);
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
        final Cup? cup = ShareService.decodeCup(jsonData);
        if (cup != null) {
          await _importCup(cup);
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
              recipe.name ?? 'Unnamed Recipe',
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
            content: Text('Recipe "${recipe.name ?? "Unnamed"}" imported successfully'),
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

  Future<void> _importCup(Cup cup) async {
    if (!mounted) return;

    // Get user's bags
    final bags = ref.read(bagsProvider);

    if (bags.isEmpty) {
      // No bags available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Bags Available'),
          content: const Text(
            'You need to have at least one coffee bag to import tasting notes. '
            'Please add a bag first, then try importing again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show bag selection dialog
    final CoffeeBag? selectedBag = await showDialog<CoffeeBag>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tasting Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select which bag to add these tasting notes to:'),
            const SizedBox(height: 16),
            // Cup preview
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
                  Text(
                    'Tasting Notes',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brew Type: ${cup.brewType}',
                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                  ),
                  if (cup.score1to5 != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${cup.score1to5}/5',
                          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (cup.tastingNotes != null && cup.tastingNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      cup.tastingNotes!,
                      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add to bag:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Bag selection
            SizedBox(
              width: double.maxFinite,
              child: DropdownButtonFormField<CoffeeBag>(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a bag'),
                items: bags.map((bag) {
                  return DropdownMenuItem<CoffeeBag>(
                    value: bag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bag.coffeeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          bag.roaster,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (CoffeeBag? bag) {
                  if (bag != null) {
                    Navigator.pop(context, bag);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBag == null || !mounted) return;

    try {
      // Create a new cup with the selected bagId
      final importedCup = Cup(
        id: cup.id, // Will get a new ID when added
        userId: cup.userId, // Will be set to current user
        bagId: selectedBag.id, // Use the selected bag
        brewType: cup.brewType,
        grindLevel: cup.grindLevel,
        waterTempCelsius: cup.waterTempCelsius,
        gramsUsed: cup.gramsUsed,
        finalVolumeMl: cup.finalVolumeMl,
        brewTimeSeconds: cup.brewTimeSeconds,
        bloomTimeSeconds: cup.bloomTimeSeconds,
        score1to5: cup.score1to5,
        score1to10: cup.score1to10,
        score1to100: cup.score1to100,
        tastingNotes: cup.tastingNotes,
        flavorTags: cup.flavorTags,
        photoPaths: [], // Photos don't transfer
        isBest: cup.isBest,
        createdAt: cup.createdAt,
        updatedAt: DateTime.now(),
        customTitle: cup.customTitle,
        equipmentSetupId: cup.equipmentSetupId,
        adaptationNotes: cup.adaptationNotes,
        preInfusionTimeSeconds: cup.preInfusionTimeSeconds,
        pressureBars: cup.pressureBars,
        yieldGrams: cup.yieldGrams,
        bloomAmountGrams: cup.bloomAmountGrams,
        pourSchedule: cup.pourSchedule,
        tds: cup.tds,
        extractionYield: cup.extractionYield,
        roomTempCelsius: cup.roomTempCelsius,
        humidity: cup.humidity,
        altitudeMeters: cup.altitudeMeters,
        timeOfDay: cup.timeOfDay,
        // Cupping scores
        cuppingFragrance: cup.cuppingFragrance,
        cuppingAroma: cup.cuppingAroma,
        cuppingFlavor: cup.cuppingFlavor,
        cuppingAftertaste: cup.cuppingAftertaste,
        cuppingAcidity: cup.cuppingAcidity,
        cuppingBody: cup.cuppingBody,
        cuppingBalance: cup.cuppingBalance,
        cuppingSweetness: cup.cuppingSweetness,
        cuppingCleanCup: cup.cuppingCleanCup,
        cuppingUniformity: cup.cuppingUniformity,
        cuppingOverall: cup.cuppingOverall,
        cuppingDefects: cup.cuppingDefects,
        // Drink recipe
        drinkRecipeId: cup.drinkRecipeId,
      );

      // Add the cup
      await ref.read(cupsNotifierProvider).createCup(importedCup);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tasting notes imported to ${selectedBag.coffeeName}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to import tasting notes: $e');
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
