import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/format.dart';

void main() {
  group('Core Format & Utilities Unit Tests', () {
    test('formatRelativeTime returns "Baru saja" for recent timestamps', () {
      final now = DateTime(2026, 10, 11, 14, 0, 30);
      final recent = DateTime(2026, 10, 11, 14, 0, 10);
      expect(formatRelativeTime(recent, now: now), 'Baru saja');
    });

    test('formatRelativeTime returns minutes ago correctly', () {
      final now = DateTime(2026, 10, 11, 14, 30);
      final earlier = DateTime(2026, 10, 11, 14, 15);
      expect(formatRelativeTime(earlier, now: now), '15 menit lalu');
    });

    test('formatRelativeTime returns "Hari ini, HH:mm" on same day', () {
      final now = DateTime(2026, 10, 11, 18, 0);
      final earlier = DateTime(2026, 10, 11, 10, 15);
      expect(formatRelativeTime(earlier, now: now), 'Hari ini, 10:15');
    });

    test('formatRelativeTime returns "Kemarin, HH:mm" for yesterday', () {
      final now = DateTime(2026, 10, 11, 10, 0);
      final yesterday = DateTime(2026, 10, 10, 15, 45);
      expect(formatRelativeTime(yesterday, now: now), 'Kemarin, 15:45');
    });

    test('parseRouteId parses valid numeric string and handles edge cases', () {
      expect(parseRouteId('123'), 123);
      expect(parseRouteId('  42  '), 42);
      expect(parseRouteId(null), isNull);
      expect(parseRouteId(''), isNull);
      expect(parseRouteId('abc'), isNull);
    });

    test('sanitizeText trims and collapses excessive newlines', () {
      expect(sanitizeText('  Halo Dunia  '), 'Halo Dunia');
      expect(sanitizeText('A\n\n\n\nB'), 'A\n\nB');
    });
  });
}
