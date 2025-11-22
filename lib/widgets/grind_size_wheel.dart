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

          // Wheel slider
          SizedBox(
            height: 200,
            child: WheelSlider(
              totalCount: _totalCount,
              initValue: _currentIndex,
              onValueChanged: _onValueChanged,
              hapticFeedbackType: HapticFeedbackType.vibrate,
              enableAnimation: true,
              perspective: 0.01, // Creates the 3D curved effect
              squeeze: 1.1, // Makes the lines curve back
              diameterRatio: 3.0, // Controls the size of the wheel
              lineColor: Colors.brown.shade300,
              selectedLineColor: Colors.brown.shade700,
              showPointer: true,
              pointerColor: Colors.brown.shade900,
              pointerWidth: 3,
              pointerHeight: 40,
              interval: widget.stepSize,
              displayValue: (index) {
                final value = widget.minValue + (index * widget.stepSize);
                return value.toStringAsFixed(
                  widget.stepSize < 1 ? 1 : 0,
                );
              },
              horizontalListWidth: MediaQuery.of(context).size.width * 0.8,
              horizontalListHeight: 200,
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
