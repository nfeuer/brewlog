import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/drink_recipe.dart';
import '../models/cup.dart';
import '../services/share_service.dart';
import '../providers/drink_recipes_provider.dart';
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
      await ref.read(drinkRecipesProvider.notifier).addRecipe(recipe);

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
    // For now, just show a message that Cup import is not yet implemented
    // In the future, this could navigate to a screen where the user selects which bag to add it to
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cup Sharing'),
          content: const Text(
            'Cup sharing is not yet implemented. Currently, only drink recipes can be imported.',
          ),
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
