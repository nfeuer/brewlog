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
class ShareCupScreen extends ConsumerStatefulWidget {
  final Cup cup;

  const ShareCupScreen({
    super.key,
    required this.cup,
  });

  @override
  ConsumerState<ShareCupScreen> createState() => _ShareCupScreenState();
}

class _ShareCupScreenState extends ConsumerState<ShareCupScreen> {
  // Field visibility toggles for reducing QR code size
  // Default to false to keep QR codes scannable - most users don't need all fields
  bool _includeEnvironmental = false;
  bool _includeCuppingScores = false;
  bool _includeAdvancedBrewing = false;
  bool _includeTimingDetails = true; // Keep timing as it's commonly used

  Cup get _filteredCup {
    // Create a minimal copy of the cup for QR code sharing
    // Only include essential brewing data to keep QR code scannable
    return Cup(
      id: widget.cup.id,
      bagId: widget.cup.bagId,
      userId: widget.cup.userId,
      brewType: widget.cup.brewType,
      grindLevel: widget.cup.grindLevel,
      waterTempCelsius: widget.cup.waterTempCelsius,
      gramsUsed: widget.cup.gramsUsed,
      finalVolumeMl: widget.cup.finalVolumeMl,
      ratio: widget.cup.ratio,
      brewTimeSeconds: _includeTimingDetails ? widget.cup.brewTimeSeconds : null,
      bloomTimeSeconds: _includeTimingDetails ? widget.cup.bloomTimeSeconds : null,
      // Only include the 1-5 score format to reduce size
      score1to5: widget.cup.score1to5,
      score1to10: null,
      score1to100: null,
      // Limit tasting notes to 500 characters
      tastingNotes: widget.cup.tastingNotes != null && widget.cup.tastingNotes!.length > 500
          ? widget.cup.tastingNotes!.substring(0, 500)
          : widget.cup.tastingNotes,
      // Limit flavor tags to first 10
      flavorTags: widget.cup.flavorTags.length > 10
          ? widget.cup.flavorTags.sublist(0, 10)
          : widget.cup.flavorTags,
      photoPaths: [], // Never include photos in QR
      isBest: widget.cup.isBest,
      shareCount: widget.cup.shareCount,
      sharedByUserId: widget.cup.sharedByUserId,
      sharedByUsername: widget.cup.sharedByUsername,
      createdAt: widget.cup.createdAt,
      customTitle: null, // Exclude to reduce size
      equipmentSetupId: null, // Not useful for sharing
      adaptationNotes: null, // Exclude to reduce size
      // Advanced brewing parameters
      preInfusionTimeSeconds: _includeAdvancedBrewing ? widget.cup.preInfusionTimeSeconds : null,
      pressureBars: _includeAdvancedBrewing ? widget.cup.pressureBars : null,
      yieldGrams: _includeAdvancedBrewing ? widget.cup.yieldGrams : null,
      bloomAmountGrams: _includeAdvancedBrewing ? widget.cup.bloomAmountGrams : null,
      pourSchedule: _includeAdvancedBrewing ? widget.cup.pourSchedule : null,
      tds: _includeAdvancedBrewing ? widget.cup.tds : null,
      extractionYield: _includeAdvancedBrewing ? widget.cup.extractionYield : null,
      // Environmental conditions
      roomTempCelsius: _includeEnvironmental ? widget.cup.roomTempCelsius : null,
      humidity: _includeEnvironmental ? widget.cup.humidity : null,
      altitudeMeters: _includeEnvironmental ? widget.cup.altitudeMeters : null,
      timeOfDay: _includeEnvironmental ? widget.cup.timeOfDay : null,
      // Cupping scores
      cuppingFragrance: _includeCuppingScores ? widget.cup.cuppingFragrance : null,
      cuppingAroma: _includeCuppingScores ? widget.cup.cuppingAroma : null,
      cuppingFlavor: _includeCuppingScores ? widget.cup.cuppingFlavor : null,
      cuppingAftertaste: _includeCuppingScores ? widget.cup.cuppingAftertaste : null,
      cuppingAcidity: _includeCuppingScores ? widget.cup.cuppingAcidity : null,
      cuppingBody: _includeCuppingScores ? widget.cup.cuppingBody : null,
      cuppingBalance: _includeCuppingScores ? widget.cup.cuppingBalance : null,
      cuppingSweetness: _includeCuppingScores ? widget.cup.cuppingSweetness : null,
      cuppingCleanCup: _includeCuppingScores ? widget.cup.cuppingCleanCup : null,
      cuppingUniformity: _includeCuppingScores ? widget.cup.cuppingUniformity : null,
      cuppingOverall: _includeCuppingScores ? widget.cup.cuppingOverall : null,
      cuppingTotal: _includeCuppingScores ? widget.cup.cuppingTotal : null,
      cuppingDefects: _includeCuppingScores ? widget.cup.cuppingDefects : null,
      fieldVisibility: null, // Not needed for sharing
      drinkRecipeId: null, // Not transferable
      grinderMinSetting: null, // Exclude to reduce size
      grinderMaxSetting: null, // Exclude to reduce size
      grinderStepSize: null, // Exclude to reduce size
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final Cup cupToShare = _filteredCup;
    final String qrData = ShareService.encodeCup(cupToShare, sharerUsername: user?.username);
    final String deepLink = ShareService.createCupDeepLink(cupToShare, sharerUsername: user?.username);
    final int dataSize = ShareService.estimateDataSize(qrData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Cup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFieldSettings,
            tooltip: 'Customize QR Code',
          ),
        ],
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
              widget.cup.brewType,
              style: AppTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Rating if available
            if (widget.cup.score1to5 != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.cup.score1to5}/5',
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
              child: dataSize > 10208
                  ? Container(
                      width: 300,
                      height: 300,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber, size: 48, color: Colors.red.shade700),
                          const SizedBox(height: 16),
                          Text(
                            'QR Code Too Large',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the ⚙️ button to disable more fields, or use "Share via Link" below.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 300,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
            ),
            const SizedBox(height: 16),

            // Data size info with color coding
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dataSize > 10000
                    ? Colors.red.shade50
                    : dataSize > 7000
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dataSize > 10000
                      ? Colors.red
                      : dataSize > 7000
                          ? Colors.orange
                          : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dataSize > 10000
                        ? Icons.error_outline
                        : dataSize > 7000
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                    size: 16,
                    color: dataSize > 10000
                        ? Colors.red
                        : dataSize > 7000
                            ? Colors.orange
                            : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dataSize > 10000
                        ? 'Too large ($dataSize bytes) - disable more fields'
                        : dataSize > 7000
                            ? 'Large ($dataSize bytes) - may be hard to scan'
                            : 'Optimal size ($dataSize bytes)',
                    style: AppTextStyles.cardSubtitle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dataSize > 10000
                          ? Colors.red.shade900
                          : dataSize > 7000
                              ? Colors.orange.shade900
                              : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
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
            const SizedBox(height: 4),
            Text(
              'Tap the ⚙️ icon above to customize what data to include',
              style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Share via link button (fallback option)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaLink(context, deepLink, cupToShare),
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
                    'Coffee details, brew method, grind size settings, tasting notes, rating, and all cupping scores',
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

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize QR Code'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Toggle fields to reduce QR code size for easier scanning:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Timing Details'),
                subtitle: const Text('Brew time, bloom time'),
                value: _includeTimingDetails,
                onChanged: (value) {
                  setDialogState(() => _includeTimingDetails = value);
                  setState(() => _includeTimingDetails = value);
                },
              ),
              SwitchListTile(
                title: const Text('Advanced Brewing'),
                subtitle: const Text('Pre-infusion, pressure, TDS, extraction'),
                value: _includeAdvancedBrewing,
                onChanged: (value) {
                  setDialogState(() => _includeAdvancedBrewing = value);
                  setState(() => _includeAdvancedBrewing = value);
                },
              ),
              SwitchListTile(
                title: const Text('Environmental Data'),
                subtitle: const Text('Room temp, humidity, altitude'),
                value: _includeEnvironmental,
                onChanged: (value) {
                  setDialogState(() => _includeEnvironmental = value);
                  setState(() => _includeEnvironmental = value);
                },
              ),
              SwitchListTile(
                title: const Text('Cupping Scores'),
                subtitle: const Text('SCA cupping protocol scores'),
                value: _includeCuppingScores,
                onChanged: (value) {
                  setDialogState(() => _includeCuppingScores = value);
                  setState(() => _includeCuppingScores = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _includeTimingDetails = true;
                _includeAdvancedBrewing = true;
                _includeEnvironmental = true;
                _includeCuppingScores = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Include All'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
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
