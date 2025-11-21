import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PourEntry {
  final int timeSeconds;
  final double? grams;

  PourEntry({required this.timeSeconds, this.grams});

  String get formattedTime {
    final minutes = timeSeconds ~/ 60;
    final seconds = timeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    if (grams != null) {
      return '$formattedTime - ${grams!.toStringAsFixed(0)}g';
    }
    return formattedTime;
  }
}

class PourScheduleTimer extends StatefulWidget {
  final Function(List<PourEntry> entries, int totalSeconds) onStop;
  final List<PourEntry>? initialEntries;

  const PourScheduleTimer({
    super.key,
    required this.onStop,
    this.initialEntries,
  });

  @override
  State<PourScheduleTimer> createState() => _PourScheduleTimerState();
}

class _PourScheduleTimerState extends State<PourScheduleTimer> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  List<PourEntry> _entries = [];
  final TextEditingController _gramsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialEntries != null) {
      _entries = List.from(widget.initialEntries!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gramsController.dispose();
    super.dispose();
  }

  void _startPauseTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startTimer();
      } else {
        _pauseTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _seconds = 0;
      _entries.clear();
      _gramsController.clear();
    });
  }

  void _addLap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Pour at ${_formatTime(_seconds)}'),
        content: TextField(
          controller: _gramsController,
          decoration: const InputDecoration(
            labelText: 'Grams',
            hintText: 'Enter grams poured',
            suffixText: 'g',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final grams = double.tryParse(_gramsController.text);
              setState(() {
                _entries.add(PourEntry(
                  timeSeconds: _seconds,
                  grams: grams,
                ));
              });
              _gramsController.clear();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    widget.onStop(_entries, _seconds);
    setState(() {
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer display
            Center(
              child: Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reset button
                ElevatedButton.icon(
                  onPressed: _seconds > 0 && !_isRunning ? _resetTimer : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),

                // Start/Pause button
                ElevatedButton.icon(
                  onPressed: _startPauseTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Lap button
                ElevatedButton.icon(
                  onPressed: _isRunning ? _addLap : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Lap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Stop button
                ElevatedButton.icon(
                  onPressed: _seconds > 0 ? _stopTimer : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Pour entries list
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Pour Schedule:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_entries.length, (index) {
                final entry = _entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${index + 1}. ${entry.formattedTime}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (entry.grams != null)
                        Text(
                          '${entry.grams!.toStringAsFixed(0)}g',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const Text(
                          '-',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _entries.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
