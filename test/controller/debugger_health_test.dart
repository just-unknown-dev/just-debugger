import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  test('a quiet world is healthy', () {
    final health = DebuggerHealth.fromSnapshot(
      const EcsDebuggerSnapshot(
        entityCount: 10,
        systemCount: 2,
        activeSystemCount: 2,
        systemTimesMs: {'render': 1.0},
      ),
      performance: const PerformanceDebuggerSnapshot(),
      memory: const MemoryDebuggerSnapshot(),
    );

    expect(health.isHealthy, isTrue);
    expect(health.hasWarnings, isFalse);
    expect(health.messages, isEmpty);
  });

  test('warns at each threshold', () {
    final health = DebuggerHealth.fromSnapshot(
      const EcsDebuggerSnapshot(
        entityCount: 200,
        systemCount: 3,
        activeSystemCount: 2,
        systemTimesMs: {'render': 1.0, 'physics': 4.0},
      ),
      performance: const PerformanceDebuggerSnapshot(isOverBudget: true),
      memory: const MemoryDebuggerSnapshot(usingCacheFallback: true),
    );

    expect(health.isHealthy, isFalse);
    expect(health.messages, [
      'High entity count detected. Consider reviewing ECS load.',
      'Some ECS systems are currently inactive.',
      'physics is taking 4.0 ms.',
      'Frame budget is currently being exceeded.',
      'Memory cache fallback is active.',
    ]);
  });

  test('stays quiet just below the thresholds', () {
    final health = DebuggerHealth.fromSnapshot(
      const EcsDebuggerSnapshot(
        entityCount: 199,
        systemTimesMs: {'physics': 3.9},
      ),
    );

    expect(health.isHealthy, isTrue);
  });
}
