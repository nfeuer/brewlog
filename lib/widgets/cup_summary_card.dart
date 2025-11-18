import 'dart:io';
import 'package:flutter/material.dart';
import '../models/cup.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

/// Summary card for a cup (used in swipeable list on bag detail screen)
class CupSummaryCard extends StatelessWidget {
  final Cup cup;
  final VoidCallback onTap;
  final VoidCallback? onCopy;
  final double ratingMax;

  const CupSummaryCard({
    super.key,
    required this.cup,
    required this.onTap,
    this.onCopy,
    this.ratingMax = 5.0,
  });

  @override
  Widget build(BuildContext context) {
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
                  // Rating
                  if (cup.score1to5 != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getRatingColor(cup.score1to5, ratingMax),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            formatRating(cup.score1to5!, ratingMax),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
