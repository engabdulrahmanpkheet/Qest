import 'package:flutter_test/flutter_test.dart';
import 'package:qest/core/utils/quiet_hours.dart';

void main() {
  group('clampToActiveHours', () {
    test('passes through times in active window', () {
      final t = DateTime(2026, 5, 13, 14);
      expect(clampToActiveHours(t), t);
    });

    test('shifts late-night times to next morning at 10:00', () {
      final t = DateTime(2026, 5, 13, 23, 30);
      final out = clampToActiveHours(t);
      expect(out.hour, 10);
      expect(out.day, 14);
    });

    test('shifts early-morning times to same day 10:00', () {
      final t = DateTime(2026, 5, 13, 7);
      final out = clampToActiveHours(t);
      expect(out.hour, 10);
      expect(out.day, 13);
    });
  });

  group('spreadReminderSlots', () {
    test('spreads N slots across the active window', () {
      final day = DateTime(2026, 5, 13);
      final slots = spreadReminderSlots(day, 3);
      expect(slots.length, 3);
      for (final s in slots) {
        expect(s.hour, greaterThanOrEqualTo(10));
        expect(s.hour, lessThan(22));
      }
      // Slots are increasing.
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].isAfter(slots[i - 1]), true);
      }
    });
  });
}
