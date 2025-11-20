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
    this.minTemp = 60.0, // Default range 60-135°C (140-275°F)
    this.maxTemp = 135.0,
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
                width: 144,
                height: 144,
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

          // Right side: Rotatable dial knob
          SizedBox(
            width: 144,
            height: 144,
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);

                // Calculate angle from center of this specific knob widget
                final center = Offset(box.size.width / 2, box.size.height / 2);
                final dx = localPosition.dx - center.dx;
                final dy = localPosition.dy - center.dy;

                // Calculate angle in degrees (atan2 returns radians)
                double angle = math.atan2(dy, dx) * 180 / math.pi;

                // Normalize angle to 0-360
                if (angle < 0) angle += 360;

                // Our dial starts at bottom-left (225°) and goes to bottom-right (495° or -135°)
                // Convert to our 0-270 internal range
                double dialAngle;

                // The dial arc goes from 225° to 495° (or -135°)
                // We want to map this to 0-270 for our internal representation
                if (angle >= 225) {
                  // From 225° to 360°
                  dialAngle = angle - 225;
                } else if (angle <= 135) {
                  // From 0° to 135°
                  dialAngle = angle + 135;
                } else {
                  // In the "dead zone" - snap to nearest end
                  if (angle < 180) {
                    dialAngle = 270;
                  } else {
                    dialAngle = 0;
                  }
                }

                dialAngle = dialAngle.clamp(0.0, 270.0);
                _updateTemperatureFromAngle(dialAngle);
              },
              onPanDown: (details) {
                // Same logic as onPanUpdate for initial touch
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final center = Offset(box.size.width / 2, box.size.height / 2);
                final dx = localPosition.dx - center.dx;
                final dy = localPosition.dy - center.dy;

                double angle = math.atan2(dy, dx) * 180 / math.pi;
                if (angle < 0) angle += 360;

                double dialAngle;
                if (angle >= 225) {
                  dialAngle = angle - 225;
                } else if (angle <= 135) {
                  dialAngle = angle + 135;
                } else {
                  if (angle < 180) {
                    dialAngle = 270;
                  } else {
                    dialAngle = 0;
                  }
                }

                dialAngle = dialAngle.clamp(0.0, 270.0);
                _updateTemperatureFromAngle(dialAngle);
              },
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

    // Draw outer circle (dark knob body)
    final knobPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, knobPaint);

    // Draw inner circle (slightly darker for depth)
    final innerPaint = Paint()
      ..color = const Color(0xFF242424)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.9, innerPaint);

    // Draw indicator notch/line at the edge
    final angleRad = (angle + 135) * math.pi / 180; // Convert to radians, adjust for starting position

    // Draw a white indicator line at the outer edge
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

    // Draw subtle edge highlight for 3D effect
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius - 1, highlightPaint);
  }

  @override
  bool shouldRepaint(_DialKnobPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
