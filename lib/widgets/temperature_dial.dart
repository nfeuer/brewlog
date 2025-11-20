import 'dart:math' as math;
import 'package:flutter/material.dart';

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
    this.minTemp = 60.0, // Default range 60-100°C
    this.maxTemp = 100.0,
  });

  @override
  State<TemperatureDial> createState() => _TemperatureDialState();
}

class _TemperatureDialState extends State<TemperatureDial> {
  late double? _temperatureCelsius;
  late TemperatureUnit _currentUnit;
  double _knobAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _temperatureCelsius = widget.initialValue;
    _currentUnit = widget.initialUnit;
    _updateKnobAngle();
  }

  @override
  void didUpdateWidget(TemperatureDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _temperatureCelsius = widget.initialValue;
      _updateKnobAngle();
    }
  }

  void _updateKnobAngle() {
    if (_temperatureCelsius == null) {
      _knobAngle = 0.0;
      return;
    }
    // Map temperature to angle (0 to 270 degrees)
    final normalized = (_temperatureCelsius! - widget.minTemp) /
                      (widget.maxTemp - widget.minTemp);
    _knobAngle = normalized.clamp(0.0, 1.0) * 270.0;
  }

  void _updateTemperatureFromAngle(double angle) {
    // Map angle (0 to 270 degrees) back to temperature
    final normalized = (angle / 270.0).clamp(0.0, 1.0);
    final newTemp = widget.minTemp + (normalized * (widget.maxTemp - widget.minTemp));

    setState(() {
      _temperatureCelsius = double.parse(newTemp.toStringAsFixed(1));
      _knobAngle = angle;
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
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _CircularArcPainter(
                    progress: _knobAngle / 270.0,
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
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _toggleUnit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '°${_currentUnit == TemperatureUnit.celsius ? 'C' : 'F'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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

          // Right side: Rotatable dial knob
          GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);

              // Calculate angle from center of the knob
              // The knob is on the right side, so we need to adjust for its position
              final knobCenterX = box.size.width * 0.75; // Approximate knob center
              final knobCenterY = box.size.height * 0.4;

              final dx = localPosition.dx - knobCenterX;
              final dy = localPosition.dy - knobCenterY;

              // Calculate angle in degrees
              double angle = math.atan2(dy, dx) * 180 / math.pi;

              // Adjust angle to start from top (270 degrees in standard coordinates)
              angle = (angle + 90) % 360;

              // Map to 0-270 range, starting from bottom-left going clockwise
              if (angle < 0) angle += 360;

              // Convert to our 0-270 range (bottom-left to bottom-right)
              double dialAngle;
              if (angle >= 135 && angle <= 405) {
                dialAngle = angle - 135;
                if (dialAngle > 270) dialAngle = 270;
                if (dialAngle < 0) dialAngle = 0;
                _updateTemperatureFromAngle(dialAngle);
              }
            },
            child: SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _DialKnobPainter(
                  angle: _knobAngle,
                  color: _getTemperatureColor(_temperatureCelsius ?? widget.minTemp),
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

class _DialKnobPainter extends CustomPainter {
  final double angle; // 0 to 270 degrees
  final Color color;

  _DialKnobPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle (knob body)
    final knobPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, knobPaint);

    // Draw inner circle (slightly lighter)
    final innerPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.85, innerPaint);

    // Draw indicator line
    final angleRad = (angle + 135) * math.pi / 180; // Convert to radians, adjust for starting position
    final indicatorStart = Offset(
      center.dx + (radius * 0.3) * math.cos(angleRad),
      center.dy + (radius * 0.3) * math.sin(angleRad),
    );
    final indicatorEnd = Offset(
      center.dx + (radius * 0.7) * math.cos(angleRad),
      center.dy + (radius * 0.7) * math.sin(angleRad),
    );

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.15, centerDotPaint);

    // Draw subtle edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 1, highlightPaint);
  }

  @override
  bool shouldRepaint(_DialKnobPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
