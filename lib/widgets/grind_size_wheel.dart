import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wheel_slider/wheel_slider.dart';

class GrindSizeWheel extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double?> onChanged;
  final double minValue;
  final double maxValue;
  final double stepSize;
  final bool showRangeControls;
  final ValueChanged<double>? onMinValueChanged;
  final ValueChanged<double>? onMaxValueChanged;
  final ValueChanged<double>? onStepSizeChanged;
  final bool hapticsEnabled;

  const GrindSizeWheel({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 50,
    this.stepSize = 1.0,
    this.showRangeControls = false,
    this.onMinValueChanged,
    this.onMaxValueChanged,
    this.onStepSizeChanged,
    this.hapticsEnabled = true,
  });

  @override
  State<GrindSizeWheel> createState() => _GrindSizeWheelState();
}

/// Helper to determine tick mark properties based on value
class _TickMarkHelper {
  static double getLineHeight(double value, double stepSize) {
    final remainder = value % 1.0;

    // Whole numbers always get full height
    if (remainder.abs() < 0.01) {
      return 40.0;
    }

    // Half steps (0.5) get medium height
    if ((remainder - 0.5).abs() < 0.01) {
      return 30.0;
    }

    // Quarter steps get short height
    return 20.0;
  }

  static double getLineWidth(double value, double stepSize) {
    final remainder = value % 1.0;

    // Whole numbers - keep full width
    if (remainder.abs() < 0.01) {
      return 3.0;
    }

    // Half steps - reduced by 50%
    if ((remainder - 0.5).abs() < 0.01) {
      return 1.25;
    }

    // Quarter steps - reduced by 75%
    return 0.375;
  }

  static Color getLineColor(double value, double stepSize) {
    final remainder = value % 1.0;

    // Whole numbers
    if (remainder.abs() < 0.01) {
      return Colors.brown.shade600;
    }

    // Half steps
    if ((remainder - 0.5).abs() < 0.01) {
      return Colors.brown.shade400;
    }

    // Quarter steps
    return Colors.brown.shade300;
  }

  /// Check if this tick should be selectable based on stepSize
  static bool isSelectable(double value, double stepSize) {
    final adjustedValue = value % stepSize;
    return adjustedValue.abs() < 0.01 || (stepSize - adjustedValue).abs() < 0.01;
  }
}

class _GrindSizeWheelState extends State<GrindSizeWheel> {
  late double _currentValue;
  late int _totalCount;
  late int _currentIndex;
  bool _showSettings = false;
  int _wheelKey = 0; // Used to force WheelSlider rebuild when snapping to valid position
  Timer? _snapTimer; // Timer to debounce snapping to valid position

  // Always use 0.25 as the base interval for consistent spacing
  static const double _baseInterval = 0.25;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    super.dispose();
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
    // Always generate ticks at 0.25 intervals for consistent spacing
    _totalCount = ((widget.maxValue - widget.minValue) / _baseInterval).round() + 1;

    // Set initial value
    if (widget.initialValue != null) {
      _currentValue = widget.initialValue!;
      _currentIndex = ((widget.initialValue! - widget.minValue) / _baseInterval).round();
    } else {
      // Default to middle value, snapped to stepSize
      final middleValue = (widget.minValue + widget.maxValue) / 2;
      _currentValue = _snapToStepSize(middleValue);
      _currentIndex = ((_currentValue - widget.minValue) / _baseInterval).round();
    }
  }

  /// Snap a value to the nearest valid stepSize
  double _snapToStepSize(double value) {
    final steps = ((value - widget.minValue) / widget.stepSize).round();
    return widget.minValue + (steps * widget.stepSize);
  }

  void _onValueChanged(int index) {
    final newValue = widget.minValue + (index * _baseInterval);
    final isValid = _TickMarkHelper.isSelectable(newValue, widget.stepSize);

    // Always update the index for smooth scrolling
    setState(() {
      _currentIndex = index;
    });

    if (isValid) {
      // Valid position - update immediately
      setState(() {
        _currentValue = _snapToStepSize(newValue);
      });

      // Provide haptic feedback if enabled
      if (widget.hapticsEnabled) {
        HapticFeedback.selectionClick();
      }

      // Notify parent
      widget.onChanged(_currentValue);

      // Cancel any pending snap timer since we're on a valid position
      _snapTimer?.cancel();
    } else {
      // Invalid position - debounce the snap to avoid interrupting scrolling
      _snapTimer?.cancel();
      _snapTimer = Timer(const Duration(milliseconds: 150), () {
        // After scrolling has stopped, snap to nearest valid position
        final snappedValue = _snapToStepSize(newValue);
        final snappedIndex = ((snappedValue - widget.minValue) / _baseInterval).round();

        setState(() {
          _currentIndex = snappedIndex;
          _currentValue = snappedValue;
          _wheelKey++; // Force WheelSlider to rebuild at the snapped position
        });

        // Notify parent
        widget.onChanged(_currentValue);
      });
    }
  }

  /// Calculate the visual width for a tick to maintain consistent spacing
  /// regardless of step size
  double _getTickSpacing(double stepSize) {
    // Reduce spacing to make ticks more visible
    // Base spacing for 1.0 step size
    const baseSpacing = 8.0;
    // Scale spacing inversely with step size (smaller steps = tighter spacing)
    return baseSpacing * stepSize;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display current value (removed icon, reduced spacing)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentValue.toStringAsFixed(
                  widget.stepSize < 1 ? 2 : (widget.stepSize == 1 ? 0 : 1),
                ),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                  color: Colors.brown,
                ),
              ),
              const Text(
                'Grind Size',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Wheel slider with custom line rendering (oval/3D effect)
          SizedBox(
            height: 200,
            child: WheelSlider.customWidget(
              key: ValueKey(_wheelKey), // Force rebuild when snapping to valid position
              totalCount: _totalCount,
              initValue: _currentIndex,
              onValueChanged: (value) => _onValueChanged(value as int),
              isVibrate: false, // Disable WheelSlider's built-in haptics - we handle them manually
              enableAnimation: false, // Disable animation to prevent initial scroll
              perspective: 0.005, // Reduced for more oval effect
              squeeze: 1.5, // Increased for more pronounced 3D curve
              showPointer: true,
              pointerColor: Colors.brown.shade900,
              pointerWidth: 3,
              pointerHeight: 40,
              horizontalListWidth: MediaQuery.of(context).size.width * 0.8,
              horizontalListHeight: 200,
              children: List.generate(_totalCount, (index) {
                final value = widget.minValue + (index * _baseInterval);
                final isWholeNumber = (value % 1.0).abs() < 0.01;
                final isHalfStep = ((value % 1.0) - 0.5).abs() < 0.01;
                final isQuarterStep = !isWholeNumber && !isHalfStep;

                // Hide finer ticks based on stepSize to maintain spacing
                bool shouldHide = false;
                if (widget.stepSize >= 1.0 && !isWholeNumber) {
                  shouldHide = true; // Hide half and quarter steps at 1.0 stepSize
                } else if (widget.stepSize == 0.5 && isQuarterStep) {
                  shouldHide = true; // Hide quarter steps at 0.5 stepSize
                }

                if (shouldHide) {
                  return const SizedBox(width: 0, height: 0);
                }

                final lineHeight = _TickMarkHelper.getLineHeight(value, widget.stepSize);
                final lineWidth = _TickMarkHelper.getLineWidth(value, widget.stepSize);
                final lineColor = _TickMarkHelper.getLineColor(value, widget.stepSize);
                final showHalfLabel = widget.stepSize <= 0.5 && isHalfStep;

                return Container(
                  height: lineHeight,
                  width: lineWidth,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(lineWidth / 2),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: (isWholeNumber || showHalfLabel)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 45),
                          child: Text(
                            value.toStringAsFixed(showHalfLabel ? 1 : 0),
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

          const SizedBox(height: 4),

          // Range controls (optional)
          if (widget.showRangeControls) ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              icon: Icon(_showSettings ? Icons.expand_less : Icons.settings),
              label: Text(_showSettings ? 'Hide Settings' : 'Adjust Range & Step'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown.shade700,
              ),
            ),
            if (_showSettings) ...[
              const SizedBox(height: 4),
              _buildRangeControls(),
            ],
          ],

          // Show range information
          if (!widget.showRangeControls || !_showSettings)
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

  Widget _buildRangeControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Min', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: TextEditingController(text: widget.minValue.toString()),
                      onSubmitted: (value) {
                        final newMin = double.tryParse(value);
                        if (newMin != null && widget.onMinValueChanged != null) {
                          widget.onMinValueChanged!(newMin);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: TextEditingController(text: widget.maxValue.toString()),
                      onSubmitted: (value) {
                        final newMax = double.tryParse(value);
                        if (newMax != null && widget.onMaxValueChanged != null) {
                          widget.onMaxValueChanged!(newMax);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Step Size', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          DropdownButtonFormField<double>(
            value: widget.stepSize,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('1.0 (Full steps)')),
              DropdownMenuItem(value: 0.5, child: Text('0.5 (Half steps)')),
              DropdownMenuItem(value: 0.25, child: Text('0.25 (Quarter steps)')),
            ],
            onChanged: (value) {
              if (value != null && widget.onStepSizeChanged != null) {
                widget.onStepSizeChanged!(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
