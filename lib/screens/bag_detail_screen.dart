import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bag.dart';
import '../providers/bags_provider.dart';
import '../providers/cups_provider.dart';
import '../providers/user_provider.dart';
import '../services/photo_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../widgets/cup_summary_card.dart';
import '../widgets/photo_viewer.dart';
import 'bag_form_screen.dart';
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BagFormScreen(bag: bag),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'finish') {
                await _markAsFinished(context, ref, bag);
              } else if (value == 'reopen') {
                await _markAsActive(context, ref, bag);
              } else if (value == 'delete') {
                await _deleteBag(context, ref, bag);
              }
            },
            itemBuilder: (context) => [
              if (bag.status == BagStatus.active)
                const PopupMenuItem(
                  value: 'finish',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text('Mark as Finished'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'reopen',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Reopen Bag'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Bag', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with photo (tap to zoom, long press to edit)
            GestureDetector(
              onTap: () {
                // Tap to zoom if photo exists
                if (bag.labelPhotoPath != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SinglePhotoViewer(
                        photoPath: bag.labelPhotoPath!,
                      ),
                    ),
                  );
                }
              },
              onLongPress: () => _changeBagPhoto(context, ref, bag),
              child: Stack(
                children: [
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
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
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
    final newCupId = await cupsNotifier.copyCup(cupId);
    if (context.mounted) {
      showSuccess(context, 'Cup copied!');
      // Navigate to the new cup for editing
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CupCardScreen(cupId: newCupId),
        ),
      );
    }
  }
}

Future<void> _markAsFinished(BuildContext context, WidgetRef ref, CoffeeBag bag) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Mark as Finished',
    message: 'Mark "${bag.displayTitle}" as finished? You can reopen it later if needed.',
    confirmText: 'Mark Finished',
  );

  if (confirmed) {
    await ref.read(bagsProvider.notifier).markAsFinished(bag.id);
    if (context.mounted) {
      showSuccess(context, 'Bag marked as finished');
    }
  }
}

Future<void> _markAsActive(BuildContext context, WidgetRef ref, CoffeeBag bag) async {
  await ref.read(bagsProvider.notifier).markAsActive(bag.id);
  if (context.mounted) {
    showSuccess(context, 'Bag reopened');
  }
}

Future<void> _deleteBag(BuildContext context, WidgetRef ref, CoffeeBag bag) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete Bag',
    message: 'Are you sure you want to delete "${bag.displayTitle}"?\n\nThis will permanently delete the bag and all ${bag.totalCups} cup(s) associated with it. This action cannot be undone.',
    confirmText: 'Delete',
    isDangerous: true,
  );

  if (confirmed) {
    await ref.read(bagsProvider.notifier).deleteBag(bag.id);
    if (context.mounted) {
      Navigator.pop(context); // Go back to previous screen
      showSuccess(context, 'Bag deleted');
    }
  }
}

Future<void> _changeBagPhoto(BuildContext context, WidgetRef ref, CoffeeBag bag) async {
  final photoService = PhotoService();

  final source = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Change Photo'),
      content: const Text('Choose photo source'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'camera'),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Camera'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'gallery'),
          icon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
        ),
        if (bag.labelPhotoPath != null)
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'remove'),
            icon: const Icon(Icons.delete),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  if (source == null) return;

  String? newPhotoPath;

  if (source == 'remove') {
    newPhotoPath = null;
  } else if (source == 'camera') {
    newPhotoPath = await photoService.takePhoto();
    if (newPhotoPath == null) return; // User cancelled
  } else {
    newPhotoPath = await photoService.pickPhoto();
    if (newPhotoPath == null) return; // User cancelled
  }

  // Update bag with new photo
  final updatedBag = bag.copyWith(labelPhotoPath: newPhotoPath);
  await ref.read(bagsProvider.notifier).updateBag(updatedBag);

  if (context.mounted) {
    if (source == 'remove') {
      showSuccess(context, 'Photo removed');
    } else {
      showSuccess(context, 'Photo updated');
    }
  }
}
