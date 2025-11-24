import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_cups_provider.dart';
import '../providers/user_provider.dart';
import '../providers/bags_provider.dart';
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
}
