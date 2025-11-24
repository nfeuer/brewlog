import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';
import '../services/share_service.dart';
import '../providers/user_provider.dart';
import '../providers/bags_provider.dart';
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
  // Field visibility map for QR code sharing
  // Default fields as specified: bag details and essential cup details
  late Map<String, bool> _fieldVisibility;

  @override
  void initState() {
    super.initState();
    // Initialize with default fields checked (as specified by user)
    _fieldVisibility = {
      // Bag Details - default included (name, roaster, roast level, process, aroma)
      'bagName': true,
      'bagRoaster': true,
      'bagRoastLevel': true,
      'bagProcess': true,
      'bagAroma': true,

      // Brew Parameters - default included
      'grindLevel': true,
      'waterTemp': true,
      'gramsUsed': true,
      'finalVolume': true,
      'brewTime': true,

      // Advanced Brewing - default included
      'bloomTime': true,
      'bloomAmount': true,
      'pourSchedule': true,

      // Rating
      'score1to100': true,
      'tastingNotes': true,
      'flavorTags': true,

      // Advanced Brewing - optional
      'preInfusionTime': false,
      'pressureBars': false,
      'yieldGrams': false,
      'tds': false,
      'extractionYield': false,

      // Environmental - optional
      'roomTemp': false,
      'humidity': false,
      'altitude': false,
      'timeOfDay': false,

      // SCA Cupping - optional
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
    };
  }

  Cup get _filteredCup {
    // Create a minimal copy of the cup for QR code sharing
    // Only include fields that are checked in the field visibility map
    return Cup(
      id: widget.cup.id,
      bagId: widget.cup.bagId,
      userId: widget.cup.userId,
      brewType: widget.cup.brewType,
      // Brew Parameters
      grindLevel: _fieldVisibility['grindLevel'] == true ? widget.cup.grindLevel : null,
      waterTempCelsius: _fieldVisibility['waterTemp'] == true ? widget.cup.waterTempCelsius : null,
      gramsUsed: _fieldVisibility['gramsUsed'] == true ? widget.cup.gramsUsed : null,
      finalVolumeMl: _fieldVisibility['finalVolume'] == true ? widget.cup.finalVolumeMl : null,
      ratio: widget.cup.ratio, // Auto-calculated, always include if components present
      brewTimeSeconds: _fieldVisibility['brewTime'] == true ? widget.cup.brewTimeSeconds : null,
      bloomTimeSeconds: _fieldVisibility['bloomTime'] == true ? widget.cup.bloomTimeSeconds : null,
      bloomAmountGrams: _fieldVisibility['bloomAmount'] == true ? widget.cup.bloomAmountGrams : null,
      pourSchedule: _fieldVisibility['pourSchedule'] == true ? widget.cup.pourSchedule : null,
      // Rating - only include score1to100
      score1to5: null,
      score1to10: null,
      score1to100: _fieldVisibility['score1to100'] == true ? widget.cup.score1to100 : null,
      // Tasting notes - limit to 500 characters
      tastingNotes: _fieldVisibility['tastingNotes'] == true
          ? (widget.cup.tastingNotes != null && widget.cup.tastingNotes!.length > 500
              ? widget.cup.tastingNotes!.substring(0, 500)
              : widget.cup.tastingNotes)
          : null,
      // Flavor tags - limit to first 10
      flavorTags: _fieldVisibility['flavorTags'] == true
          ? (widget.cup.flavorTags.length > 10
              ? widget.cup.flavorTags.sublist(0, 10)
              : widget.cup.flavorTags)
          : [],
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
      preInfusionTimeSeconds: _fieldVisibility['preInfusionTime'] == true ? widget.cup.preInfusionTimeSeconds : null,
      pressureBars: _fieldVisibility['pressureBars'] == true ? widget.cup.pressureBars : null,
      yieldGrams: _fieldVisibility['yieldGrams'] == true ? widget.cup.yieldGrams : null,
      tds: _fieldVisibility['tds'] == true ? widget.cup.tds : null,
      extractionYield: _fieldVisibility['extractionYield'] == true ? widget.cup.extractionYield : null,
      // Environmental conditions
      roomTempCelsius: _fieldVisibility['roomTemp'] == true ? widget.cup.roomTempCelsius : null,
      humidity: _fieldVisibility['humidity'] == true ? widget.cup.humidity : null,
      altitudeMeters: _fieldVisibility['altitude'] == true ? widget.cup.altitudeMeters : null,
      timeOfDay: _fieldVisibility['timeOfDay'] == true ? widget.cup.timeOfDay : null,
      // Cupping scores
      cuppingFragrance: _fieldVisibility['cuppingFragrance'] == true ? widget.cup.cuppingFragrance : null,
      cuppingAroma: _fieldVisibility['cuppingAroma'] == true ? widget.cup.cuppingAroma : null,
      cuppingFlavor: _fieldVisibility['cuppingFlavor'] == true ? widget.cup.cuppingFlavor : null,
      cuppingAftertaste: _fieldVisibility['cuppingAftertaste'] == true ? widget.cup.cuppingAftertaste : null,
      cuppingAcidity: _fieldVisibility['cuppingAcidity'] == true ? widget.cup.cuppingAcidity : null,
      cuppingBody: _fieldVisibility['cuppingBody'] == true ? widget.cup.cuppingBody : null,
      cuppingBalance: _fieldVisibility['cuppingBalance'] == true ? widget.cup.cuppingBalance : null,
      cuppingSweetness: _fieldVisibility['cuppingSweetness'] == true ? widget.cup.cuppingSweetness : null,
      cuppingCleanCup: _fieldVisibility['cuppingCleanCup'] == true ? widget.cup.cuppingCleanCup : null,
      cuppingUniformity: _fieldVisibility['cuppingUniformity'] == true ? widget.cup.cuppingUniformity : null,
      cuppingOverall: _fieldVisibility['cuppingOverall'] == true ? widget.cup.cuppingOverall : null,
      cuppingTotal: _fieldVisibility['cuppingTotal'] == true ? widget.cup.cuppingTotal : null,
      cuppingDefects: _fieldVisibility['cuppingDefects'] == true ? widget.cup.cuppingDefects : null,
      fieldVisibility: null, // Not needed for sharing
      drinkRecipeId: null, // Not transferable
      grinderMinSetting: null, // Exclude to reduce size
      grinderMaxSetting: null, // Exclude to reduce size
      grinderStepSize: null, // Exclude to reduce size
    );
  }

  CoffeeBag? _getFilteredBag(CoffeeBag? bag) {
    if (bag == null) return null;
    // Only include bag fields that are selected
    final bool includeName = _fieldVisibility['bagName'] == true;
    final bool includeRoaster = _fieldVisibility['bagRoaster'] == true;
    final bool includeRoastLevel = _fieldVisibility['bagRoastLevel'] == true;
    final bool includeProcess = _fieldVisibility['bagProcess'] == true;
    final bool includeAroma = _fieldVisibility['bagAroma'] == true;

    // If no bag fields are selected, return null
    if (!includeName && !includeRoaster && !includeRoastLevel && !includeProcess && !includeAroma) {
      return null;
    }

    // Create a filtered copy
    return CoffeeBag(
      id: bag.id,
      userId: bag.userId,
      customTitle: bag.customTitle,
      coffeeName: includeName ? bag.coffeeName : '',
      roaster: includeRoaster ? bag.roaster : '',
      roastLevel: includeRoastLevel ? bag.roastLevel : null,
      processingMethods: includeProcess ? bag.processingMethods : null,
      beanAroma: includeAroma ? bag.beanAroma : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final bag = ref.watch(bagProvider(widget.cup.bagId));
    final Cup cupToShare = _filteredCup;
    final CoffeeBag? bagToShare = _getFilteredBag(bag);
    final String qrData = ShareService.encodeCupWithBag(cupToShare, bagToShare, sharerUsername: user?.username);
    final String deepLink = ShareService.createCupWithBagDeepLink(cupToShare, bagToShare, sharerUsername: user?.username);
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
            if (widget.cup.score1to100 != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.cup.score1to100}/100',
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
                            'Use the sliders button (⚙) above to disable more fields, or use "Share via Link" below.',
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
              'Tap the sliders icon above to customize what data to include',
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
                    'Bag details (name, roaster, roast level, process, aroma), brew method, grind size, water temp, coffee/water amounts, timing, rating (1-100), tasting notes, and optional cupping scores',
                  ),
                  const SizedBox(height: 8),
                  _buildHelpItem(
                    'Not Included',
                    'Photos (device-specific). Null/empty fields are automatically excluded to reduce QR code size.',
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
        title: const Text('Select Fields to Share'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select which fields to include in the QR code:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),

                // Bag Details
                _buildSectionHeader('Coffee Bag Info'),
                _buildFieldCheckbox('Coffee Name', 'bagName', setDialogState),
                _buildFieldCheckbox('Roaster', 'bagRoaster', setDialogState),
                _buildFieldCheckbox('Roast Level', 'bagRoastLevel', setDialogState),
                _buildFieldCheckbox('Processing Method', 'bagProcess', setDialogState),
                _buildFieldCheckbox('Bean Aroma', 'bagAroma', setDialogState),
                const SizedBox(height: 12),

                // Brew Parameters
                _buildSectionHeader('Brew Parameters'),
                _buildFieldCheckbox('Grind Level', 'grindLevel', setDialogState),
                _buildFieldCheckbox('Water Temperature', 'waterTemp', setDialogState),
                _buildFieldCheckbox('Coffee Amount (g)', 'gramsUsed', setDialogState),
                _buildFieldCheckbox('Final Volume (ml)', 'finalVolume', setDialogState),
                _buildFieldCheckbox('Brew Time', 'brewTime', setDialogState),
                const SizedBox(height: 12),

                // Advanced Brewing
                _buildSectionHeader('Advanced Brewing'),
                _buildFieldCheckbox('Bloom Time', 'bloomTime', setDialogState),
                _buildFieldCheckbox('Bloom Amount', 'bloomAmount', setDialogState),
                _buildFieldCheckbox('Pour Schedule', 'pourSchedule', setDialogState),
                _buildFieldCheckbox('Pre-Infusion Time', 'preInfusionTime', setDialogState),
                _buildFieldCheckbox('Pressure (bars)', 'pressureBars', setDialogState),
                _buildFieldCheckbox('Yield Weight', 'yieldGrams', setDialogState),
                _buildFieldCheckbox('TDS', 'tds', setDialogState),
                _buildFieldCheckbox('Extraction Yield', 'extractionYield', setDialogState),
                const SizedBox(height: 12),

                // Rating & Tasting
                _buildSectionHeader('Rating & Tasting'),
                _buildFieldCheckbox('Rating (1-100)', 'score1to100', setDialogState),
                _buildFieldCheckbox('Tasting Notes', 'tastingNotes', setDialogState),
                _buildFieldCheckbox('Flavor Tags', 'flavorTags', setDialogState),
                const SizedBox(height: 12),

                // Environmental
                _buildSectionHeader('Environmental'),
                _buildFieldCheckbox('Room Temperature', 'roomTemp', setDialogState),
                _buildFieldCheckbox('Humidity', 'humidity', setDialogState),
                _buildFieldCheckbox('Altitude', 'altitude', setDialogState),
                _buildFieldCheckbox('Time of Day', 'timeOfDay', setDialogState),
                const SizedBox(height: 12),

                // SCA Cupping
                _buildSectionHeader('SCA Cupping Protocol'),
                _buildFieldCheckbox('Fragrance/Aroma', 'cuppingFragrance', setDialogState),
                _buildFieldCheckbox('Aroma (Wet)', 'cuppingAroma', setDialogState),
                _buildFieldCheckbox('Flavor', 'cuppingFlavor', setDialogState),
                _buildFieldCheckbox('Aftertaste', 'cuppingAftertaste', setDialogState),
                _buildFieldCheckbox('Acidity', 'cuppingAcidity', setDialogState),
                _buildFieldCheckbox('Body', 'cuppingBody', setDialogState),
                _buildFieldCheckbox('Balance', 'cuppingBalance', setDialogState),
                _buildFieldCheckbox('Sweetness', 'cuppingSweetness', setDialogState),
                _buildFieldCheckbox('Clean Cup', 'cuppingCleanCup', setDialogState),
                _buildFieldCheckbox('Uniformity', 'cuppingUniformity', setDialogState),
                _buildFieldCheckbox('Overall', 'cuppingOverall', setDialogState),
                _buildFieldCheckbox('Total Score', 'cuppingTotal', setDialogState),
                _buildFieldCheckbox('Defects Notes', 'cuppingDefects', setDialogState),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                // Select all fields
                _fieldVisibility.updateAll((key, value) => true);
              });
              Navigator.pop(context);
            },
            child: const Text('Select All'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Reset to defaults
                _fieldVisibility.updateAll((key, value) => false);
                // Re-enable default fields (bag details + essential cup details)
                _fieldVisibility['bagName'] = true;
                _fieldVisibility['bagRoaster'] = true;
                _fieldVisibility['bagRoastLevel'] = true;
                _fieldVisibility['bagProcess'] = true;
                _fieldVisibility['bagAroma'] = true;
                _fieldVisibility['grindLevel'] = true;
                _fieldVisibility['waterTemp'] = true;
                _fieldVisibility['gramsUsed'] = true;
                _fieldVisibility['finalVolume'] = true;
                _fieldVisibility['brewTime'] = true;
                _fieldVisibility['bloomTime'] = true;
                _fieldVisibility['bloomAmount'] = true;
                _fieldVisibility['pourSchedule'] = true;
                _fieldVisibility['score1to100'] = true;
                _fieldVisibility['tastingNotes'] = true;
                _fieldVisibility['flavorTags'] = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBrown,
        ),
      ),
    );
  }

  Widget _buildFieldCheckbox(String label, String key, StateSetter setDialogState) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: _fieldVisibility[key] ?? false,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onChanged: (value) {
        setDialogState(() {
          _fieldVisibility[key] = value ?? false;
        });
        setState(() {
          _fieldVisibility[key] = value ?? false;
        });
      },
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
