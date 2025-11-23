import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TemperatureDial extends StatefulWidget {
  final double? initialValue; // Temperature in Celsius
  final ValueChanged<double?> onChanged; // Returns value in Celsius
  final bool hapticsEnabled;

  const TemperatureDial({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.hapticsEnabled = true,
  });

  @override
  State<TemperatureDial> createState() => _TemperatureDialState();
}

class _TemperatureDialState extends State<TemperatureDial> {
  // Store temperature in Fahrenheit internally
  late double _temperatureFahrenheit;
  late bool _isFahrenheit; // Display unit flag

  // Temperature range in Fahrenheit (60-215°F)
  static const double _minTempF = 60.0;
  static const double _maxTempF = 215.0;

  // Track previous dial angle for delta calculation
  double? _previousDialAngle;

  // Track cumulative rotation for visual display
  double _cumulativeRotation = 0.0;

  // Track last temperature for haptic feedback
  int _lastHapticTemp = 0;

  @override
  void initState() {
    super.initState();
    // Initialize temperature from Celsius value or default to 140°F
    if (widget.initialValue != null) {
      _temperatureFahrenheit = _celsiusToFahrenheit(widget.initialValue!);
    } else {
      _temperatureFahrenheit = 140.0; // Default starting temperature
    }
    _isFahrenheit = true; // Start displaying in Fahrenheit
  }

  @override
  void didUpdateWidget(TemperatureDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != null) {
      _temperatureFahrenheit = _celsiusToFahrenheit(widget.initialValue!);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    // Calculate center of the dial
    final center = Offset(size.width / 2, size.height / 2);

    // Get touch position relative to center
    final touchPos = details.localPosition - center;

    // Calculate angle of touch position (in radians, then convert to degrees)
    double currentAngle = math.atan2(touchPos.dy, touchPos.dx) * 180 / math.pi;

    // Normalize to 0-360 range
    if (currentAngle < 0) {
      currentAngle += 360;
    }

    // Initialize previous angle on first touch
    if (_previousDialAngle == null) {
      _previousDialAngle = currentAngle;
      _lastHapticTemp = _temperatureFahrenheit.round();
      return;
    }

    // Calculate angular change
    double deltaAngle = currentAngle - _previousDialAngle!;

    // Handle wrap-around when crossing 0/360 degree boundary
    if (deltaAngle > 180) {
      deltaAngle -= 360;
    } else if (deltaAngle < -180) {
      deltaAngle += 360;
    }

    _previousDialAngle = currentAngle;

    // Map angle change to temperature change
    // Full rotation (360°) covers the entire temperature range
    double tempChange = (deltaAngle / 360.0) * (_maxTempF - _minTempF);

    setState(() {
      // Update cumulative rotation for visual feedback
      _cumulativeRotation += deltaAngle;

      // Update temperature with clamping to min/max range
      _temperatureFahrenheit =
          (_temperatureFahrenheit + tempChange).clamp(_minTempF, _maxTempF);
    });

    // Provide haptic feedback if enabled and temperature crossed a whole degree
    if (widget.hapticsEnabled) {
      final currentTemp = _temperatureFahrenheit.round();
      if (currentTemp != _lastHapticTemp) {
        HapticFeedback.selectionClick();
        _lastHapticTemp = currentTemp;
      }
    }

    // Notify parent with value in Celsius
    widget.onChanged(_fahrenheitToCelsius(_temperatureFahrenheit));
  }

  void _handlePanEnd(DragEndDetails details) {
    // Reset angle tracking when touch ends
    _previousDialAngle = null;
    _lastHapticTemp = _temperatureFahrenheit.round();
  }

  double _celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  double _fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  double get _temperatureCelsius {
    return _fahrenheitToCelsius(_temperatureFahrenheit);
  }

  double get _displayTemperature {
    return _isFahrenheit ? _temperatureFahrenheit : _temperatureCelsius;
  }

  String get _displayUnit {
    return _isFahrenheit ? 'F' : 'C';
  }

  void _toggleUnit() {
    setState(() {
      _isFahrenheit = !_isFahrenheit;
    });
  }

  double get _progress {
    // Calculate progress as percentage of temperature range
    return ((_temperatureFahrenheit - _minTempF) / (_maxTempF - _minTempF))
        .clamp(0.0, 1.0);
  }

  Color _getTemperatureColor() {
    final normalized = _progress;

    if (normalized < 0.5) {
      // Blue to yellow (cool to warm)
      return Color.lerp(
        Colors.blue.shade400,
        Colors.yellow.shade700,
        normalized * 2,
      )!;
    } else {
      // Yellow to red (warm to hot)
      return Color.lerp(
        Colors.yellow.shade700,
        Colors.red.shade600,
        (normalized - 0.5) * 2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left side: Circular arc progress indicator with temperature display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: CustomPaint(
                  painter: _CircularArcPainter(
                    progress: _progress,
                    color: _getTemperatureColor(),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayTemperature.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _toggleUnit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '°$_displayUnit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Water Temperature',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // Right side: Rotatable dial knob with infinite rotation
          _RotatableDialKnob(
            size: 144,
            rotation: _cumulativeRotation,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
          ),
        ],
      ),
    );
  }
}

class _RotatableDialKnob extends StatelessWidget {
  final double size;
  final double rotation; // Rotation in degrees
  final Function(DragUpdateDetails, Size) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const _RotatableDialKnob({
    required this.size,
    required this.rotation,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onPanUpdate(details, Size(size, size)),
      onPanEnd: onPanEnd,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C2C2C),
        ),
        child: Transform.rotate(
          angle: rotation * math.pi / 180, // Convert degrees to radians
          child: Image.asset(
            'assets/images/dial_knob.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CircularArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _CircularArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc (grey)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw background arc (270 degrees, starting from bottom-left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      135 * math.pi / 180, // Start at bottom-left (135°)
      270 * math.pi / 180, // Sweep 270 degrees clockwise
      false,
      backgroundPaint,
    );

    // Foreground arc (colored, based on progress)
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      135 * math.pi / 180,
      (270 * progress) * math.pi / 180,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
