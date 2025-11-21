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
  bool _isStopped = false;
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
      _isStopped = false;
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
            labelText: 'Current Volume',
            hintText: 'Total volume so far',
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
      _isStopped = true;
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
            // Timer display and controls (hide when stopped)
            if (!_isStopped) ...[
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

              // Control buttons row (circular icon buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset button
                  IconButton(
                    onPressed: _seconds > 0 && !_isRunning ? _resetTimer : null,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: _seconds > 0 && !_isRunning
                          ? Colors.grey[300]
                          : Colors.grey[200],
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 24,
                    tooltip: 'Reset',
                  ),
                  const SizedBox(width: 12),

                  // Start/Pause button
                  IconButton(
                    onPressed: _startPauseTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 24,
                    tooltip: _isRunning ? 'Pause' : 'Start',
                  ),
                  const SizedBox(width: 12),

                  // Stop button
                  IconButton(
                    onPressed: _seconds > 0 ? _stopTimer : null,
                    icon: const Icon(Icons.stop),
                    style: IconButton.styleFrom(
                      backgroundColor: _seconds > 0 ? Colors.red : Colors.grey[200],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 24,
                    tooltip: 'Stop',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lap button (below, with text)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? _addLap : null,
                  icon: const Icon(Icons.add),
                  label: const Text('+ Pour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ],

            // Pour entries list
            if (_entries.isNotEmpty) ...[
              if (!_isStopped) const SizedBox(height: 16),
              if (!_isStopped) const Divider(),
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
                      if (!_isStopped)
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
