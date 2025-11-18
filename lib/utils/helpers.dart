import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper functions and utilities

/// Format date to readable string
String formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

/// Format date with time
String formatDateTime(DateTime date) {
  return DateFormat('MMM d, yyyy • h:mm a').format(date);
}

/// Format time duration in seconds to readable string
String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;

  if (minutes > 0) {
    return '${minutes}m ${remainingSeconds}s';
  }
  return '${seconds}s';
}

/// Format grams to string with 1 decimal
String formatGrams(double grams) {
  return '${grams.toStringAsFixed(1)}g';
}

/// Format ml to string
String formatMl(double ml) {
  return '${ml.toStringAsFixed(0)}ml';
}

/// Format temperature
String formatTemp(double celsius, {bool showFahrenheit = false}) {
  if (showFahrenheit) {
    final fahrenheit = (celsius * 9 / 5) + 32;
    return '${celsius.toStringAsFixed(0)}°C (${fahrenheit.toStringAsFixed(0)}°F)';
  }
  return '${celsius.toStringAsFixed(0)}°C';
}

/// Format rating to string based on max value
String formatRating(double rating, double max) {
  if (max == 5) {
    return rating.toStringAsFixed(1);
  } else if (max == 10) {
    return rating.toStringAsFixed(1);
  } else {
    return rating.toStringAsFixed(0);
  }
}

/// Format price
String formatPrice(double price) {
  return '\$${price.toStringAsFixed(2)}';
}

/// Get color for rating (green for high, yellow for medium, red for low)
Color getRatingColor(double? rating, double max) {
  if (rating == null) return Colors.grey;

  final normalized = rating / max;

  if (normalized >= 0.8) {
    return Colors.green;
  } else if (normalized >= 0.6) {
    return Colors.lightGreen;
  } else if (normalized >= 0.4) {
    return Colors.orange;
  } else {
    return Colors.deepOrange;
  }
}

/// Show success snackbar
void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Show error snackbar
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Show confirmation dialog
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDangerous
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return result ?? false;
}

/// Calculate ratio from grams and ml
double? calculateRatio(double? grams, double? ml) {
  if (grams == null || ml == null || grams == 0) return null;
  return ml / grams;
}

/// Format ratio as string
String formatRatio(double? ratio) {
  if (ratio == null) return '-';
  return '1:${ratio.toStringAsFixed(1)}';
}

/// Debounce function for search
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Extension to add firstWhereOrNull to Iterable (if not available)
extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// Timer class (needed for debouncer)
class Timer {
  final Duration duration;
  final VoidCallback callback;

  Timer(this.duration, this.callback) {
    Future.delayed(duration, callback);
  }

  void cancel() {
    // Implementation would cancel the future if possible
  }
}
