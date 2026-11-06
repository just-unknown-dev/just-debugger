import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  test('timeLabel pads hours, minutes and seconds', () {
    final entry = DebuggerLogEntry(
      message: 'm',
      category: 'c',
      timestamp: DateTime(2026, 1, 2, 3, 4, 5),
    );

    expect(entry.timeLabel, '03:04:05');
  });

  test('timeLabel without a timestamp', () {
    const entry = DebuggerLogEntry(message: 'm', category: 'c');

    expect(entry.timeLabel, '--:--:--');
    expect(entry.level, DebuggerLogLevel.info);
  });
}
