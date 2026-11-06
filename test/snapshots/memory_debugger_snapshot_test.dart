import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  group('MemoryDebuggerSnapshot.fromStats', () {
    test('reads the top-level keys', () {
      final snapshot = MemoryDebuggerSnapshot.fromStats(const {
        'componentCount': 24,
        'entityCount': 12,
        'usingCacheFallback': true,
        'counters': {'pools': 2, 'arenas': 1},
        'totalPhysicalMemoryBytes': 8000,
        'freePhysicalMemoryBytes': 3000,
        'rssBytes': 500,
        'cleanupAvailable': true,
      });

      expect(snapshot.componentCount, 24);
      expect(snapshot.entityCount, 12);
      expect(snapshot.usingCacheFallback, isTrue);
      expect(snapshot.counters, {'pools': 2, 'arenas': 1});
      expect(snapshot.totalPhysicalMemoryBytes, 8000);
      expect(snapshot.freePhysicalMemoryBytes, 3000);
      expect(snapshot.rssBytes, 500);
      expect(snapshot.cleanupAvailable, isTrue);
    });

    test('reads the alias keys', () {
      final snapshot = MemoryDebuggerSnapshot.fromStats(const {
        'activeEntities': 9,
        'cacheFallback': true,
        'currentRssBytes': 700,
      });

      expect(snapshot.entityCount, 9);
      expect(snapshot.usingCacheFallback, isTrue);
      expect(snapshot.rssBytes, 700);
    });

    test('falls back to the systemMemory map', () {
      final snapshot = MemoryDebuggerSnapshot.fromStats(const {
        'rssBytes': 0,
        'systemMemory': {
          'totalPhysicalMemoryBytes': 8000,
          'freePhysicalMemoryBytes': 2000,
          'rssBytes': 600,
          'componentCount': 5,
        },
      });

      expect(snapshot.totalPhysicalMemoryBytes, 8000);
      expect(snapshot.freePhysicalMemoryBytes, 2000);
      expect(snapshot.rssBytes, 600);
      expect(snapshot.componentCount, 5);
    });

    test('reads a systemMemory map with other keys than strings', () {
      final snapshot = MemoryDebuggerSnapshot.fromStats({
        'systemMemory': <Object?, Object?>{
          'rssBytes': 600,
          1: 'ignored',
          null: 2,
        },
      });

      expect(snapshot.rssBytes, 600);
    });
  });

  group('derived values', () {
    test('without system memory', () {
      const snapshot = MemoryDebuggerSnapshot(rssBytes: 100);

      expect(snapshot.hasSystemMemoryStats, isFalse);
      expect(snapshot.availabilityRatio, 0.0);
      expect(snapshot.usedPhysicalMemoryBytes, 0);
    });

    test('with system memory', () {
      const snapshot = MemoryDebuggerSnapshot(
        totalPhysicalMemoryBytes: 8000,
        freePhysicalMemoryBytes: 2000,
      );

      expect(snapshot.hasSystemMemoryStats, isTrue);
      expect(snapshot.availabilityRatio, 0.25);
      expect(snapshot.usedPhysicalMemoryBytes, 6000);
    });

    test('used memory is never negative', () {
      const snapshot = MemoryDebuggerSnapshot(
        totalPhysicalMemoryBytes: 1000,
        freePhysicalMemoryBytes: 2000,
      );

      expect(snapshot.usedPhysicalMemoryBytes, 0);
    });
  });
}
