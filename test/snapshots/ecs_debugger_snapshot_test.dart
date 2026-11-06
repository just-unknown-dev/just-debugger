import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  group('EcsDebuggerSnapshot.fromStats', () {
    test('reads the primary keys', () {
      final snapshot = EcsDebuggerSnapshot.fromStats(const {
        'entityCount': 12,
        'activeEntityCount': 10,
        'systemCount': 4,
        'activeSystemCount': 3,
        'archetypeCount': 2,
        'systemTimesMs': {'physics': 1.5},
      });

      expect(snapshot.entityCount, 12);
      expect(snapshot.activeEntityCount, 10);
      expect(snapshot.systemCount, 4);
      expect(snapshot.activeSystemCount, 3);
      expect(snapshot.archetypeCount, 2);
      expect(snapshot.systemTimesMs, {'physics': 1.5});
      expect(snapshot.capturedAt, isNotNull);
    });

    test('reads the alias keys', () {
      final snapshot = EcsDebuggerSnapshot.fromStats(const {
        'totalEntities': 12,
        'activeEntities': 10,
        'systems': 4,
        'activeSystems': 3,
        'archetypes': 2,
      });

      expect(snapshot.entityCount, 12);
      expect(snapshot.activeEntityCount, 10);
      expect(snapshot.systemCount, 4);
      expect(snapshot.activeSystemCount, 3);
      expect(snapshot.archetypeCount, 2);
    });

    test('prefers the given maps over the stats', () {
      final snapshot = EcsDebuggerSnapshot.fromStats(
        const {
          'systemTimesMs': {'physics': 1.5},
        },
        componentUsage: const {'Transform': 3},
        systemTimesMs: const {'render': 2.0},
      );

      expect(snapshot.componentUsage, {'Transform': 3});
      expect(snapshot.systemTimesMs, {'render': 2.0});
    });

    test('reads a systemTimesMs that is not a map as empty', () {
      final snapshot = EcsDebuggerSnapshot.fromStats(const {
        'systemTimesMs': [1, 2],
      });

      expect(snapshot.systemTimesMs, isEmpty);
    });
  });

  test('copyWith replaces only what it is given', () {
    const snapshot = EcsDebuggerSnapshot(entityCount: 3, systemCount: 2);
    final copy = snapshot.copyWith(entityCount: 5);

    expect(copy.entityCount, 5);
    expect(copy.systemCount, 2);
  });
}
