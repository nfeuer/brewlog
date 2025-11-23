import 'dart:io';
import 'package:flutter/material.dart';
import '../models/coffee_bag.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

/// Reusable coffee bag card widget that adapts to different view modes.
///
/// This widget displays a [CoffeeBag] in either grid or list format,
/// showing key information like:
/// - Bag image/label photo (or placeholder)
/// - Bag title and roaster name
/// - Average rating (if available)
/// - Total cups brewed
///
/// **View Modes:**
/// - **Grid Mode** ([isGridView] = true): Vertical card with image on top
/// - **List Mode** ([isGridView] = false): Horizontal row with image on left
///
/// **Features:**
/// - Tap handling via [onTap] callback
/// - Displays local images or placeholder
/// - Responsive layout that adapts to view mode
/// - Shows rating badge with star icon
/// - Shows cup count badge
///
/// **Usage:**
/// ```dart
/// BagCard(
///   bag: coffeeBag,
///   onTap: () => Navigator.push(...),
///   isGridView: true,  // or false for list view
/// )
/// ```
///
/// **See Also:**
/// - [CoffeeBag] model
/// - [HomeScreen] where this widget is primarily used
class BagCard extends StatelessWidget {
  final CoffeeBag bag;
  final VoidCallback onTap;
  final bool isGridView;

  const BagCard({
    super.key,
    required this.bag,
    required this.onTap,
    this.isGridView = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image - flexible to take available space
        Expanded(
          child: Container(
            width: double.infinity,
            child: _buildImage(),
          ),
        ),
        // Info - fixed height section
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bag.displayTitle,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                bag.roaster,
                style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (bag.avgScore != null) _buildRatingBadge(),
                  _buildCupCount(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: _buildImage(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bag.displayTitle,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  bag.roaster,
                  style: AppTextStyles.cardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bag.variety != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    bag.variety!,
                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (bag.avgScore != null) ...[
                      _buildRatingBadge(),
                      const SizedBox(width: 8),
                    ],
                    _buildCupCount(),
                    const Spacer(),
                    if (bag.status == BagStatus.finished)
                      const Chip(
                        label: Text('Finished', style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (bag.labelPhotoPath != null && bag.labelPhotoPath!.isNotEmpty) {
      final file = File(bag.labelPhotoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    }

    // Placeholder
    return Container(
      color: AppTheme.accentCream,
      child: const Icon(
        Icons.coffee,
        size: 48,
        color: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildRatingBadge() {
    final score = bag.avgScore!;
    final color = getRatingColor(score, 5.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            formatRating(score, 5),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupCount() {
    return Text(
      '${bag.totalCups} cup${bag.totalCups != 1 ? 's' : ''}',
      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
    );
  }
}
