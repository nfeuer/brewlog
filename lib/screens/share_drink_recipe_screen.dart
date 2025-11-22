import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/drink_recipe.dart';
import '../services/share_service.dart';
import '../utils/theme.dart';

/// Screen for sharing a DrinkRecipe via QR code or deep link
class ShareDrinkRecipeScreen extends StatelessWidget {
  final DrinkRecipe recipe;

  const ShareDrinkRecipeScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final String qrData = ShareService.encodeDrinkRecipe(recipe);
    final String deepLink = ShareService.createDrinkRecipeDeepLink(recipe);
    final int dataSize = ShareService.estimateDataSize(qrData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Recipe name
            Text(
              recipe.name ?? 'Unnamed Recipe',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Recipe summary
            if (recipe.summary.isNotEmpty)
              Text(
                recipe.summary,
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 16),

            // Data size info
            Text(
              'Data size: ${dataSize} bytes',
              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Instructions
            const Text(
              'Scan this QR code with another device to import this recipe',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Share via link button (fallback option)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaLink(context, deepLink, recipe),
                icon: const Icon(Icons.share),
                label: const Text('Share via Link'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Copy link button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyLink(context, deepLink),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Link'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppTheme.primaryBrown),
                      const SizedBox(width: 8),
                      Text(
                        'Sharing Options',
                        style: AppTextStyles.sectionHeader,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    'QR Code',
                    'Best for sharing in person. Have the other person scan this code with the BrewLog app.',
                  ),
                  const SizedBox(height: 8),
                  _buildHelpItem(
                    'Share Link',
                    'Send the recipe via text, email, or social media. The recipient needs BrewLog installed.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _shareViaLink(BuildContext context, String deepLink, DrinkRecipe recipe) async {
    try {
      await Share.share(
        deepLink,
        subject: 'Check out this coffee recipe: ${recipe.name ?? "Unnamed Recipe"}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context, String deepLink) async {
    await Clipboard.setData(ClipboardData(text: deepLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
