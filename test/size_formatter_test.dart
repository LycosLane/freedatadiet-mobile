import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/core/utils/size_formatter.dart';

void main() {
  group('SizeFormatter Tests', () {
    test('formats bytes properly across units', () {
      expect(SizeFormatter.formatBytes(0), '0 B');
      expect(SizeFormatter.formatBytes(512), '512.00 B');
      expect(SizeFormatter.formatBytes(1024), '1.00 KB');
      expect(SizeFormatter.formatBytes(1024 * 1024), '1.00 MB');
      expect(SizeFormatter.formatBytes(1536 * 1024), '1.50 MB');
      expect(SizeFormatter.formatBytes(1024 * 1024 * 1024), '1.00 GB');
      expect(SizeFormatter.formatBytes(5 * 1024 * 1024 * 1024), '5.00 GB');
    });

    test('calculates safe ratios', () {
      expect(SizeFormatter.calculateRatio(0, 100), 0.0);
      expect(SizeFormatter.calculateRatio(50, 100), 0.5);
      expect(SizeFormatter.calculateRatio(100, 100), 1.0);
      expect(SizeFormatter.calculateRatio(150, 100), 1.0); // clamped
      expect(SizeFormatter.calculateRatio(50, 0), 0.0); // safe division by zero
    });

    test('formats percentages', () {
      expect(SizeFormatter.formatPercentage(0.0), '0.0%');
      expect(SizeFormatter.formatPercentage(0.452), '45.2%');
      expect(SizeFormatter.formatPercentage(1.0), '100.0%');
    });
  });
}
