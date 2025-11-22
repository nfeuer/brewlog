import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cup.dart';
import '../services/share_service.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';

/// Screen for sharing a Cup via QR code or deep link
class ShareCupScreen extends ConsumerWidget {
  final Cup cup;

  const ShareCupScreen({
    super.key,
    required this.cup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final String qrData = ShareService.encodeCup(cup, sharerUsername: user?.username);
    final String deepLink = ShareService.createCupDeepLink(cup, sharerUsername: user?.username);
    final int dataSize = ShareService.estimateDataSize(qrData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Cup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cup info
            Text(
              'Share Tasting Notes',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Brew type
            Text(
              cup.brewType,
              style: AppTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Rating if available
            if (cup.score1to5 != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${cup.score1to5}/5',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 16),

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
              'Scan this QR code with another device to import these tasting notes',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Photos will not be transferred',
              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Share via link button (fallback option)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaLink(context, deepLink, cup),
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
                        'What gets shared?',
                        style: AppTextStyles.sectionHeader,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    'Included',
                    'Coffee details, brew method, tasting notes, rating, and all cupping scores',
                  ),
                  const SizedBox(height: 8),
                  _buildHelpItem(
                    'Not Included',
                    'Photos (device-specific) and bag association (recipient chooses their own bag)',
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

  Future<void> _shareViaLink(BuildContext context, String deepLink, Cup cup) async {
    try {
      final String shareText = 'Check out my ${cup.brewType} tasting notes!\n\n$deepLink';

      await Share.share(
        shareText,
        subject: 'Coffee Tasting Notes from BrewLog',
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
