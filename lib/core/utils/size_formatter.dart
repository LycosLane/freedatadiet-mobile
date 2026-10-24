import 'dart:math';

/// Utility methods for formatting file sizes and computing percentages.
class SizeFormatter {
  SizeFormatter._();

  static const List<String> _units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  /// Formats byte count to human-readable string (e.g. "4.12 GB", "350 KB").
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    final int i = (log(bytes) / log(1024)).floor().clamp(0, _units.length - 1);
    final double size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${_units[i]}';
  }

  /// Calculates ratio between 0.0 and 1.0 safely.
  static double calculateRatio(int currentBytes, int maxBytes) {
    if (maxBytes <= 0 || currentBytes <= 0) return 0.0;
    final ratio = currentBytes / maxBytes;
    return ratio.clamp(0.0, 1.0);
  }

  /// Formats percentage string (e.g. "45.2%").
  static String formatPercentage(double ratio, {int decimals = 1}) {
    final pct = (ratio * 100).clamp(0.0, 100.0);
    return '${pct.toStringAsFixed(decimals)}%';
  }
}
