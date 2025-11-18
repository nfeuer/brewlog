import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Rating input widget that adapts to user's preferred rating scale
class RatingInput extends StatelessWidget {
  final RatingScale scale;
  final double? value;
  final ValueChanged<double> onChanged;

  const RatingInput({
    super.key,
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (scale) {
      case RatingScale.oneToFive:
        return _buildStarRating();
      case RatingScale.oneToTen:
        return _buildSlider(10);
      case RatingScale.oneToHundred:
        return _buildSlider(100);
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isFilled = value != null && value! >= starValue;
        final isHalf = value != null &&
                      value! >= starValue - 0.5 &&
                      value! < starValue;

        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Icon(
            isHalf ? Icons.star_half : (isFilled ? Icons.star : Icons.star_border),
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _buildSlider(double max) {
    return Column(
      children: [
        Slider(
          value: value ?? max / 2,
          min: 0,
          max: max,
          divisions: max.toInt(),
          label: value != null ? formatRating(value!, max) : null,
          onChanged: onChanged,
        ),
        Text(
          value != null ? '${formatRating(value!, max)} / ${max.toInt()}' : 'Not rated',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
