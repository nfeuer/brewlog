import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/shared_cups_provider.dart';
import '../providers/user_provider.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../models/cup.dart';
import '../models/coffee_bag.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class SharedTab extends ConsumerWidget {
  const SharedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedCups = ref.watch(sharedCupsProvider);

    if (sharedCups.isEmpty) {
      return Center(
        child: Padding(
          padding: AppStyles.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 120,
                color: AppTheme.primaryBrown.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Shared Items Yet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan QR codes or use links\nto see shared recipes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textGray,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: AppStyles.screenPadding,
      itemCount: sharedCups.length,
      itemBuilder: (context, index) {
        final sharedCup = sharedCups[index];
        final cup = sharedCup.cupData;
        final bag = ref.watch(bagProvider(cup.bagId));

        // Fallback to brew type if bag is not found
        final bagName = bag?.displayTitle ?? cup.brewType;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryBrown,
                child: Icon(Icons.coffee, color: Colors.white),
              ),
              title: Text(
                bagName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cup.brewType,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${sharedCup.originalUsername} • ${formatDate(sharedCup.sharedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Copy Recipe',
                    onPressed: () => _showCopyDialog(context, ref, sharedCup, bag),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _viewSharedCup(context, sharedCup.id);
                      } else if (value == 'delete') {
                        _deleteSharedCup(context, ref, sharedCup.id);
                      }
                    },
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bag != null) ...[
                        _buildDetailRow('Coffee', bag.coffeeName),
                        _buildDetailRow('Roaster', bag.roaster),
                        if (bag.variety != null)
                          _buildDetailRow('Variety', bag.variety!),
                        const Divider(height: 24),
                      ],
                      _buildDetailRow('Brew Type', cup.brewType),
                      if (cup.gramsUsed != null)
                        _buildDetailRow('Coffee', formatGrams(cup.gramsUsed!)),
                      if (cup.finalVolumeMl != null)
                        _buildDetailRow('Water', formatMl(cup.finalVolumeMl!)),
                      if (cup.waterTempCelsius != null)
                        _buildDetailRow('Temperature', formatTemp(cup.waterTempCelsius!)),
                      if (cup.grindLevel != null)
                        _buildDetailRow('Grind', cup.grindLevel!),
                      if (cup.score1to100 != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Rating',
                          '${cup.score1to100}/100',
                          valueColor: getRatingColor(cup.score1to100!, 100),
                        ),
                      ],
                      if (cup.tastingNotes != null && cup.tastingNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Tasting Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cup.tastingNotes!,
                          style: TextStyle(color: AppTheme.textGray),
                        ),
                      ],
                      if (cup.flavorTags != null && cup.flavorTags!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cup.flavorTags!
                              .map((tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppTheme.primaryBrown.withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scanQRCode(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: const Text(
          'QR code scanning requires camera permissions and Firebase setup. '
          'This feature will be available after Firebase configuration.',
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

  void _viewSharedCup(BuildContext context, String sharedCupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shared Recipe'),
        content: const Text('Recipe details coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteSharedCup(BuildContext context, WidgetRef ref, String sharedCupId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Shared Recipe',
      message: 'Are you sure you want to delete this shared recipe?',
      confirmText: 'Delete',
      isDangerous: true,
    );

    if (confirmed) {
      await ref.read(sharedCupsProvider.notifier).deleteSharedCup(sharedCupId);
      if (context.mounted) {
        showSuccess(context, 'Shared recipe deleted');
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCopyDialog(BuildContext context, WidgetRef ref, dynamic sharedCup, dynamic bag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy Recipe'),
        content: const Text('Would you like to create a new bag or add to an existing bag?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showExistingBagsDialog(context, ref, sharedCup);
            },
            child: const Text('Existing Bag'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyToNewBag(context, ref, sharedCup, bag);
            },
            child: const Text('New Bag'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showExistingBagsDialog(BuildContext context, WidgetRef ref, dynamic sharedCup) {
    final bags = ref.read(activeBagsProvider);

    if (bags.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Bags Available'),
          content: const Text('You don\'t have any active bags. Create a new bag to copy this recipe.'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Bag'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bags.length,
            itemBuilder: (context, index) {
              final bag = bags[index];
              return ListTile(
                leading: const Icon(Icons.coffee),
                title: Text(bag.displayTitle),
                subtitle: Text(bag.roaster),
                onTap: () {
                  Navigator.pop(context);
                  _copyToExistingBag(context, ref, sharedCup, bag);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToNewBag(BuildContext context, WidgetRef ref, dynamic sharedCup, dynamic sourceBag) async {
    try {
      final user = ref.read(userProfileProvider);
      if (user == null) {
        if (context.mounted) {
          showError(context, 'User not found');
        }
        return;
      }

      final uuid = const Uuid();
      final cup = sharedCup.cupData;

      // Create new bag based on shared bag data, or create a default bag
      final newBag = CoffeeBag(
        id: uuid.v4(),
        userId: user.id,
        customTitle: sourceBag?.customTitle ?? 'Shared: ${cup.brewType}',
        coffeeName: sourceBag?.coffeeName ?? cup.brewType,
        roaster: sourceBag?.roaster ?? 'Unknown Roaster',
        farmer: sourceBag?.farmer,
        variety: sourceBag?.variety,
        elevation: sourceBag?.elevation,
        beanAroma: sourceBag?.beanAroma,
        datePurchased: DateTime.now(),
        processingMethods: sourceBag?.processingMethods,
        region: sourceBag?.region,
        roastLevel: sourceBag?.roastLevel,
      );

      // Create the bag first
      final bagId = await ref.read(bagsProvider.notifier).createBag(newBag);

      // Create new cup linked to the new bag
      final newCup = Cup(
        id: uuid.v4(),
        bagId: bagId,
        userId: user.id,
        brewType: cup.brewType,
        grindLevel: cup.grindLevel,
        waterTempCelsius: cup.waterTempCelsius,
        gramsUsed: cup.gramsUsed,
        finalVolumeMl: cup.finalVolumeMl,
        ratio: cup.ratio,
        brewTimeSeconds: cup.brewTimeSeconds,
        bloomTimeSeconds: cup.bloomTimeSeconds,
        score1to5: cup.score1to5,
        score1to10: cup.score1to10,
        score1to100: cup.score1to100,
        tastingNotes: cup.tastingNotes,
        flavorTags: cup.flavorTags != null ? List<String>.from(cup.flavorTags!) : null,
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
        sharedByUserId: sharedCup.originalUserId,
        sharedByUsername: sharedCup.originalUsername,
      );

      await ref.read(cupsNotifierProvider).createCup(newCup);

      if (context.mounted) {
        showSuccess(context, 'Recipe copied to new bag: ${newBag.displayTitle}');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Failed to copy recipe: $e');
      }
    }
  }

  Future<void> _copyToExistingBag(BuildContext context, WidgetRef ref, dynamic sharedCup, CoffeeBag targetBag) async {
    try {
      final user = ref.read(userProfileProvider);
      if (user == null) {
        if (context.mounted) {
          showError(context, 'User not found');
        }
        return;
      }

      final uuid = const Uuid();
      final cup = sharedCup.cupData;

      // Create new cup linked to the existing bag
      // The cup will inherit bag details through the bagId relationship
      final newCup = Cup(
        id: uuid.v4(),
        bagId: targetBag.id,
        userId: user.id,
        brewType: cup.brewType,
        grindLevel: cup.grindLevel,
        waterTempCelsius: cup.waterTempCelsius,
        gramsUsed: cup.gramsUsed,
        finalVolumeMl: cup.finalVolumeMl,
        ratio: cup.ratio,
        brewTimeSeconds: cup.brewTimeSeconds,
        bloomTimeSeconds: cup.bloomTimeSeconds,
        score1to5: cup.score1to5,
        score1to10: cup.score1to10,
        score1to100: cup.score1to100,
        tastingNotes: cup.tastingNotes,
        flavorTags: cup.flavorTags != null ? List<String>.from(cup.flavorTags!) : null,
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
        sharedByUserId: sharedCup.originalUserId,
        sharedByUsername: sharedCup.originalUsername,
      );

      await ref.read(cupsNotifierProvider).createCup(newCup);

      if (context.mounted) {
        showSuccess(context, 'Recipe copied to ${targetBag.displayTitle}');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Failed to copy recipe: $e');
      }
    }
  }
}
