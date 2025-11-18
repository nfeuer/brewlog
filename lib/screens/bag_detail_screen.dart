import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../widgets/cup_summary_card.dart';
import 'cup_card_screen.dart';

class BagDetailScreen extends ConsumerWidget {
  final String bagId;

  const BagDetailScreen({super.key, required this.bagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bag = ref.watch(bagProvider(bagId));
    final cups = ref.watch(cupsForBagProvider(bagId));
    final ratingScale = ref.watch(ratingScaleProvider);

    if (bag == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bag Not Found')),
        body: const Center(child: Text('Coffee bag not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(bag.displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit bag info
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with photo
            if (bag.labelPhotoPath != null) ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(bag.labelPhotoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                ),
              ),
            ] else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlaceholderImage(),
              ),

            Padding(
              padding: AppStyles.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bag.customTitle,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      Chip(
                        label: Text(
                          bag.status.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${bag.coffeeName} • ${bag.roaster}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Stats card
                  Card(
                    child: Padding(
                      padding: AppStyles.cardPadding,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                context,
                                'Total Cups',
                                bag.totalCups.toString(),
                              ),
                              _buildStat(
                                context,
                                'Avg Score',
                                bag.avgScore != null
                                    ? formatRating(bag.avgScore!, 5)
                                    : '-',
                              ),
                              _buildStat(
                                context,
                                'Days Open',
                                bag.openDate != null
                                    ? DateTime.now()
                                        .difference(bag.openDate!)
                                        .inDays
                                        .toString()
                                    : '-',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action bar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _createNewCup(context, bag.id),
                          icon: const Icon(Icons.add),
                          label: const Text('New Cup'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (bag.bestCupId != null)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _openCup(context, bag.bestCupId!),
                          icon: const Icon(Icons.star),
                          label: const Text('Best Cup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cups section
                  Text(
                    'Cups',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Swipeable cups
            if (cups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_cafe_outlined,
                        size: 48,
                        color: AppTheme.textGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cups yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textGray,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first cup to start tracking!',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: cups.length,
                  itemBuilder: (context, index) {
                    final cup = cups[index];
                    return SizedBox(
                      width: 300,
                      child: CupSummaryCard(
                        cup: cup,
                        onTap: () => _openCup(context, cup.id),
                        onCopy: () => _copyCup(context, ref, cup.id),
                        ratingMax: ratingScale.index == 0
                            ? 5
                            : ratingScale.index == 1
                                ? 10
                                : 100,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.accentCream,
      child: const Icon(
        Icons.coffee,
        size: 64,
        color: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.statValue,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.statLabel,
        ),
      ],
    );
  }

  void _createNewCup(BuildContext context, String bagId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CupCardScreen(bagId: bagId),
      ),
    );
  }

  void _openCup(BuildContext context, String cupId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CupCardScreen(cupId: cupId),
      ),
    );
  }

  void _copyCup(BuildContext context, WidgetRef ref, String cupId) async {
    final cupsNotifier = ref.read(cupsNotifierProvider);
    await cupsNotifier.copyCup(cupId);
    if (context.mounted) {
      showSuccess(context, 'Cup copied!');
    }
  }
}
