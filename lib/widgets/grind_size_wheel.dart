import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wheel_slider/wheel_slider.dart';

class GrindSizeWheel extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double?> onChanged;
  final double minValue;
  final double maxValue;
  final double stepSize;

  const GrindSizeWheel({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 50,
    this.stepSize = 1.0,
  });

  @override
  State<GrindSizeWheel> createState() => _GrindSizeWheelState();
}

/// Helper to determine tick mark height based on value and step size
class _TickMarkHelper {
  static double getLineHeight(double value, double stepSize) {
    if (stepSize >= 1.0) {
      // All full steps - uniform height
      return 40.0;
    } else if (stepSize == 0.5) {
      // Whole numbers get full height, half steps get medium height
      final isWholeNumber = (value % 1.0).abs() < 0.01;
      return isWholeNumber ? 40.0 : 25.0;
    } else if (stepSize == 0.25) {
      // Whole numbers: full, halves: medium, quarters: short
      final remainder = value % 1.0;
      if (remainder.abs() < 0.01) {
        return 40.0; // Whole number
      } else if ((remainder - 0.5).abs() < 0.01) {
        return 30.0; // Half step
      } else {
        return 20.0; // Quarter step
      }
    }
    return 40.0; // Default
  }

  static double getLineWidth(double value, double stepSize) {
    if (stepSize >= 1.0) {
      return 2.5;
    } else if (stepSize == 0.5) {
      final isWholeNumber = (value % 1.0).abs() < 0.01;
      return isWholeNumber ? 3.0 : 2.0;
    } else if (stepSize == 0.25) {
      final remainder = value % 1.0;
      if (remainder.abs() < 0.01) {
        return 3.0; // Whole number
      } else if ((remainder - 0.5).abs() < 0.01) {
        return 2.5; // Half step
      } else {
        return 1.5; // Quarter step
      }
    }
    return 2.5;
  }

  static Color getLineColor(double value, double stepSize) {
    if (stepSize >= 1.0) {
      return Colors.brown.shade400;
    } else if (stepSize == 0.5) {
      final isWholeNumber = (value % 1.0).abs() < 0.01;
      return isWholeNumber ? Colors.brown.shade500 : Colors.brown.shade300;
    } else if (stepSize == 0.25) {
      final remainder = value % 1.0;
      if (remainder.abs() < 0.01) {
        return Colors.brown.shade600; // Whole number
      } else if ((remainder - 0.5).abs() < 0.01) {
        return Colors.brown.shade400; // Half step
      } else {
        return Colors.brown.shade300; // Quarter step
      }
    }
    return Colors.brown.shade400;
  }
}

class _GrindSizeWheelState extends State<GrindSizeWheel> {
  late double _currentValue;
  late int _totalCount;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  @override
  void didUpdateWidget(GrindSizeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue ||
        oldWidget.minValue != widget.minValue ||
        oldWidget.maxValue != widget.maxValue ||
        oldWidget.stepSize != widget.stepSize) {
      _initializeValues();
    }
  }

  void _initializeValues() {
    // Calculate total number of steps
    _totalCount = ((widget.maxValue - widget.minValue) / widget.stepSize).round() + 1;

    // Set initial value
    if (widget.initialValue != null) {
      _currentValue = widget.initialValue!;
      _currentIndex = ((widget.initialValue! - widget.minValue) / widget.stepSize).round();
    } else {
      // Default to middle value
      _currentIndex = _totalCount ~/ 2;
      _currentValue = widget.minValue + (_currentIndex * widget.stepSize);
    }
  }

  void _onValueChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentValue = widget.minValue + (index * widget.stepSize);
    });

    // Provide haptic feedback
    HapticFeedback.selectionClick();

    // Notify parent
    widget.onChanged(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display current value
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.blender,
                  size: 24,
                  color: Colors.brown,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentValue.toStringAsFixed(
                        widget.stepSize < 1 ? 2 : (widget.stepSize == 1 ? 0 : 1),
                      ),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Grind Size',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Wheel slider with custom line rendering
          SizedBox(
            height: 200,
            child: WheelSlider.customWidget(
              totalCount: _totalCount,
              initValue: _currentIndex,
              onValueChanged: (value) => _onValueChanged(value as int),
              hapticFeedbackType: HapticFeedbackType.vibrate,
              enableAnimation: true,
              perspective: 0.01, // Creates the 3D curved effect
              squeeze: 1.1, // Makes the lines curve back
              showPointer: true,
              pointerColor: Colors.brown.shade900,
              pointerWidth: 3,
              pointerHeight: 40,
              horizontalListWidth: MediaQuery.of(context).size.width * 0.8,
              horizontalListHeight: 200,
              children: List.generate(_totalCount, (index) {
                final value = widget.minValue + (index * widget.stepSize);
                final lineHeight = _TickMarkHelper.getLineHeight(value, widget.stepSize);
                final lineWidth = _TickMarkHelper.getLineWidth(value, widget.stepSize);
                final lineColor = _TickMarkHelper.getLineColor(value, widget.stepSize);
                final isWholeNumber = widget.stepSize < 1.0 && (value % 1.0).abs() < 0.01;

                return Container(
                  height: lineHeight,
                  width: lineWidth,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(lineWidth / 2),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: isWholeNumber
                      ? Padding(
                          padding: const EdgeInsets.only(top: 45),
                          child: Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Show range information
          Text(
            'Range: ${widget.minValue.toStringAsFixed(0)} - ${widget.maxValue.toStringAsFixed(0)} (step: ${widget.stepSize})',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
