import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dial_knob/flutter_dial_knob.dart';

enum TemperatureUnit { celsius, fahrenheit }

class TemperatureDial extends StatefulWidget {
  final double? initialValue; // Temperature in Celsius
  final TemperatureUnit initialUnit;
  final ValueChanged<double?> onChanged; // Returns value in Celsius
  final double minTemp; // Min in Celsius
  final double maxTemp; // Max in Celsius

  const TemperatureDial({
    super.key,
    this.initialValue,
    this.initialUnit = TemperatureUnit.celsius,
    required this.onChanged,
    this.minTemp = 60.0, // Default range 60-135°C (140-275°F)
    this.maxTemp = 135.0,
  });

  @override
  State<TemperatureDial> createState() => _TemperatureDialState();
}

class _TemperatureDialState extends State<TemperatureDial> {
  late double? _temperatureCelsius;
  late TemperatureUnit _currentUnit;
  late double _knobValue; // 0.0 to 1.0 for the dial knob

  @override
  void initState() {
    super.initState();
    _temperatureCelsius = widget.initialValue;
    _currentUnit = widget.initialUnit;
    _updateKnobValue();
  }

  @override
  void didUpdateWidget(TemperatureDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _temperatureCelsius = widget.initialValue;
      _updateKnobValue();
    }
  }

  void _updateKnobValue() {
    if (_temperatureCelsius == null) {
      _knobValue = 0.0;
      return;
    }
    // Map temperature to 0-1 range
    final normalized = (_temperatureCelsius! - widget.minTemp) /
        (widget.maxTemp - widget.minTemp);
    _knobValue = normalized.clamp(0.0, 1.0);
  }

  void _updateTemperatureFromKnob(double value) {
    // Map 0-1 range back to temperature
    final newTemp = widget.minTemp + (value * (widget.maxTemp - widget.minTemp));

    setState(() {
      _temperatureCelsius = double.parse(newTemp.toStringAsFixed(1));
      _knobValue = value;
    });

    widget.onChanged(_temperatureCelsius);
  }

  double _celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  double _fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  double? _getDisplayTemperature() {
    if (_temperatureCelsius == null) return null;
    return _currentUnit == TemperatureUnit.celsius
        ? _temperatureCelsius
        : _celsiusToFahrenheit(_temperatureCelsius!);
  }

  void _toggleUnit() {
    setState(() {
      _currentUnit = _currentUnit == TemperatureUnit.celsius
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTemp = _getDisplayTemperature();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left side: Circular arc with temperature display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: CustomPaint(
                  painter: _CircularArcPainter(
                    progress: _knobValue,
                    color: _getTemperatureColor(_temperatureCelsius ?? widget.minTemp),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayTemp != null
                              ? displayTemp.toStringAsFixed(0)
                              : '--',
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
                              '°${_currentUnit == TemperatureUnit.celsius ? 'C' : 'F'}',
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

          // Right side: Rotatable dial knob using flutter_dial_knob
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2C2C2C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DialKnob(
              value: _knobValue,
              onChanged: _updateTemperatureFromKnob,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF242424),
                ),
                child: CustomPaint(
                  painter: _KnobIndicatorPainter(
                    progress: _knobValue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double tempCelsius) {
    // Gradient from cool blue to hot red
    final normalized = ((tempCelsius - widget.minTemp) /
        (widget.maxTemp - widget.minTemp)).clamp(0.0, 1.0);

    if (normalized < 0.5) {
      // Blue to yellow
      return Color.lerp(
        Colors.blue.shade400,
        Colors.yellow.shade700,
        normalized * 2,
      )!;
    } else {
      // Yellow to red
      return Color.lerp(
        Colors.yellow.shade700,
        Colors.red.shade600,
        (normalized - 0.5) * 2,
      )!;
    }
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
      135 * math.pi / 180, // Start at bottom-left
      270 * math.pi / 180, // Sweep 270 degrees
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

class _KnobIndicatorPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _KnobIndicatorPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate angle from progress (0-1 maps to 270 degrees starting at bottom-left)
    final angle = (progress * 270) + 135; // Start at 135° (bottom-left)
    final angleRad = angle * math.pi / 180;

    // Draw white indicator line at the edge
    final indicatorStart = Offset(
      center.dx + (radius * 0.75) * math.cos(angleRad),
      center.dy + (radius * 0.75) * math.sin(angleRad),
    );
    final indicatorEnd = Offset(
      center.dx + (radius * 0.95) * math.cos(angleRad),
      center.dy + (radius * 0.95) * math.sin(angleRad),
    );

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);

    // Draw center dot for depth
    final centerDotPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.2, centerDotPaint);
  }

  @override
  bool shouldRepaint(_KnobIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
