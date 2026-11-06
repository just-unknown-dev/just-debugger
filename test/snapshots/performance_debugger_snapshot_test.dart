import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  group('PerformanceDebuggerSnapshot.fromStats', () {
    test('reads the primary keys', () {
      final snapshot = PerformanceDebuggerSnapshot.fromStats(const {
        'currentFPS': 58,
        'frame': 120,
        'lastUpdateMs': 12.4,
        'budgetRemainingMs': 4.2,
        'isOverBudget': true,
        'systemTimesMs': {'physics': 2.1},
      });

      expect(snapshot.currentFps, 58);
      expect(snapshot.frameNumber, 120);
      expect(snapshot.lastUpdateMs, 12.4);
      expect(snapshot.budgetRemainingMs, 4.2);
      expect(snapshot.isOverBudget, isTrue);
      expect(snapshot.systemTimesMs, {'physics': 2.1});
    });

    test('reads the alias keys', () {
      final snapshot = PerformanceDebuggerSnapshot.fromStats(const {
        'fps': 60.0,
        'frameNumber': 7,
        'updateMs': 3,
      });

      expect(snapshot.currentFps, 60);
      expect(snapshot.frameNumber, 7);
      expect(snapshot.lastUpdateMs, 3.0);
      expect(snapshot.isOverBudget, isFalse);
    });

    test('an infinite frame rate reads as missing, not as a crash', () {
      final snapshot = PerformanceDebuggerSnapshot.fromStats(const {
        'currentFPS': double.infinity,
        'fps': 30,
      });

      expect(snapshot.currentFps, 30);
    });
  });
}
