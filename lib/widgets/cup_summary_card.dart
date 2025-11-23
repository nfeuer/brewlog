import 'package:flutter/material.dart';
import '../models/cup.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

/// Summary card for a cup (used in swipeable list on bag detail screen)
class CupSummaryCard extends StatelessWidget {
  final Cup cup;
  final VoidCallback onTap;
  final VoidCallback? onCopy;
  final RatingScale ratingScale;

  const CupSummaryCard({
    super.key,
    required this.cup,
    required this.onTap,
    this.onCopy,
    required this.ratingScale,
  });

  @override
  Widget build(BuildContext context) {
    // Get rating in user's preferred scale
    final rating = cup.getRating(ratingScale);
    final ratingMax = ratingScale == RatingScale.oneToFive
        ? 5.0
        : ratingScale == RatingScale.oneToTen
            ? 10.0
            : 100.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and Best badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(cup.createdAt),
                    style: AppTextStyles.cardSubtitle,
                  ),
                  if (cup.isBest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Best',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Brew type
              Text(
                cup.brewType,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Parameters row
              Row(
                children: [
                  if (cup.gramsUsed != null) ...[
                    _buildParam(Icons.scale, formatGrams(cup.gramsUsed!)),
                    const SizedBox(width: 12),
                  ],
                  if (cup.finalVolumeMl != null) ...[
                    _buildParam(Icons.local_drink, formatMl(cup.finalVolumeMl!)),
                    const SizedBox(width: 12),
                  ],
                  if (cup.ratio != null)
                    _buildParam(Icons.compare_arrows, cup.ratioString),
                ],
              ),
              const SizedBox(height: 8),

              // Rating and actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rating and SCA score
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Regular rating
                        if (rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getRatingColor(rating, ratingMax),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  formatRating(rating, ratingMax),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // SCA Cupping Total Score
                        if (cup.cuppingTotal != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBrown.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assessment, size: 14, color: AppTheme.primaryBrown),
                                const SizedBox(width: 4),
                                Text(
                                  'SCA: ${cup.cuppingTotal!.toInt()}/110',
                                  style: TextStyle(
                                    color: AppTheme.primaryBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Drink Recipe indicator
                        if (cup.drinkRecipeId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.menu_book, size: 14, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(
                                  'Recipe',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Copy button
                  if (onCopy != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: onCopy,
                      tooltip: 'Copy recipe',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),

              // Photos indicator
              if (cup.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.photo_camera, size: 14, color: AppTheme.textGray),
                    const SizedBox(width: 4),
                    Text(
                      '${cup.photoPaths.length} photo${cup.photoPaths.length != 1 ? 's' : ''}',
                      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParam(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
