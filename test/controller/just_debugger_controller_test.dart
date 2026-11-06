import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

const _tick = Duration(milliseconds: 100);

List<DebuggerLogEntry> _errors(JustDebuggerController controller) => [
  for (final entry in controller.logs)
    if (entry.level == DebuggerLogLevel.error) entry,
];

void main() {
  group('bind', () {
    testWidgets('polls the providers on every tick', (tester) async {
      var tick = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          tick += 1;
          return <String, dynamic>{
            'entityCount': tick * 10,
            'activeEntityCount': tick * 9,
            'systemCount': 4,
            'activeSystemCount': 4,
            'archetypeCount': tick,
          };
        },
        interval: const Duration(milliseconds: 50),
      );

      expect(controller.isBound, isTrue);
      await tester.pump();
      expect(controller.snapshot.entityCount, 10);

      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.snapshot.entityCount, 20);

      controller.stopBinding();
      expect(controller.isBound, isFalse);
    });

    test('reads performance and memory providers too', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => const <String, dynamic>{'entityCount': 12},
        performanceStatsProvider: () => const <String, dynamic>{
          'frame': 120,
          'currentFPS': 58,
          'systemTimesMs': <String, double>{'physics': 2.1},
        },
        memoryStatsProvider: () => const <String, dynamic>{
          'componentCount': 24,
          'cacheFallback': true,
        },
        interval: Duration.zero,
      );

      expect(controller.snapshot.entityCount, 12);
      expect(controller.performance.currentFps, 58);
      expect(controller.memory.componentCount, 24);
      expect(controller.memory.usingCacheFallback, isTrue);
      expect(controller.memory.cleanupAvailable, isFalse);
    });

    test('a cleanup action makes the memory snapshot offer cleanup', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryStatsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () => null,
        interval: Duration.zero,
      );

      expect(controller.memory.cleanupAvailable, isTrue);
      expect(controller.canCleanupMemory, isTrue);
    });

    testWidgets('without fireImmediately it waits for the first tick', (
      tester,
    ) async {
      var calls = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          calls++;
          return const <String, dynamic>{'entityCount': 3};
        },
        interval: _tick,
        fireImmediately: false,
      );

      expect(calls, 0);
      expect(controller.snapshot.entityCount, 0);

      await tester.pump(_tick);
      expect(calls, 1);
      expect(controller.snapshot.entityCount, 3);
      controller.stopBinding();
    });

    testWidgets('an interval of zero refreshes once and never polls', (
      tester,
    ) async {
      var calls = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          calls++;
          return const <String, dynamic>{};
        },
        interval: Duration.zero,
      );

      expect(controller.isBound, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
    });

    testWidgets('binding again replaces the last binding', (tester) async {
      var first = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          first++;
          return const <String, dynamic>{};
        },
        interval: _tick,
      );
      controller.bind(
        statsProvider: () => const <String, dynamic>{'entityCount': 8},
        interval: _tick,
      );

      await tester.pump(_tick * 3);
      expect(first, 1);
      expect(controller.snapshot.entityCount, 8);
      controller.stopBinding();
    });

    testWidgets('a provider that throws keeps the last snapshots and logs '
        'once until a refresh succeeds', (tester) async {
      var calls = 0;
      var failing = false;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          calls++;
          if (failing) {
            throw StateError('the world was disposed');
          }
          return <String, dynamic>{'entityCount': calls};
        },
        interval: _tick,
      );
      expect(controller.snapshot.entityCount, 1);

      failing = true;
      await tester.pump(_tick);
      await tester.pump(_tick);
      await tester.pump(_tick);
      expect(calls, 4);
      expect(controller.snapshot.entityCount, 1);
      expect(_errors(controller), hasLength(1));
      expect(controller.logs.last.category, 'debugger');
      expect(controller.logs.last.message, contains('the world was disposed'));
      expect(controller.isBound, isTrue);

      failing = false;
      await tester.pump(_tick);
      expect(controller.snapshot.entityCount, 5);

      failing = true;
      await tester.pump(_tick);
      expect(_errors(controller), hasLength(2));
      controller.stopBinding();
    });

    test('a throwing provider on the first refresh does not throw out of '
        'bind', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => throw StateError('not ready'),
        interval: Duration.zero,
      );

      expect(_errors(controller), hasLength(1));
      expect(controller.snapshot.entityCount, 0);
    });

    test('a refresh is all or nothing', () {
      var calls = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () {
          calls++;
          return <String, dynamic>{'entityCount': calls};
        },
        performanceStatsProvider: () => <String, dynamic>{'fps': calls * 10},
        memoryStatsProvider: () => const <String, dynamic>{'componentCount': 4},
        interval: Duration.zero,
      );
      expect(controller.snapshot.entityCount, 1);
      expect(controller.performance.currentFps, 10);

      // A second refresh, whose memory read fails after the others ran.
      controller.bind(
        statsProvider: () {
          calls++;
          return <String, dynamic>{'entityCount': calls};
        },
        performanceStatsProvider: () => <String, dynamic>{'fps': calls * 10},
        memoryStatsProvider: () => throw StateError('cache closed'),
        interval: Duration.zero,
      );

      expect(controller.snapshot.entityCount, 1);
      expect(controller.performance.currentFps, 10);
      expect(controller.memory.componentCount, 4);
      expect(_errors(controller), hasLength(1));
    });
  });

  group('log', () {
    test('keeps the last maxLogEntries entries', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);
      final total = JustDebuggerController.maxLogEntries + 5;

      for (var i = 0; i < total; i++) {
        controller.log('entry $i');
      }

      expect(controller.logs, hasLength(JustDebuggerController.maxLogEntries));
      expect(controller.logs.first.message, 'entry 5');
      expect(controller.logs.last.message, 'entry ${total - 1}');
      expect(controller.logs.last.category, 'general');
    });

    test('is unmodifiable from outside', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);
      controller.log('one');

      expect(() => controller.logs.clear(), throwsUnsupportedError);
    });

    test('clearLogs empties it and notifies once', () {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.log('one');
      controller.addListener(() => notified++);

      controller.clearLogs();
      controller.clearLogs();

      expect(controller.logs, isEmpty);
      expect(notified, 1);
    });

    test('does nothing once the controller is disposed', () {
      final controller = JustDebuggerController();
      controller.dispose();

      expect(() => controller.log('late'), returnsNormally);
    });
  });

  group('requestMemoryCleanup', () {
    test('without an action writes a warning', () async {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      await controller.requestMemoryCleanup();

      expect(controller.logs, hasLength(1));
      expect(controller.logs.single.level, DebuggerLogLevel.warning);
      expect(
        controller.logs.single.message,
        contains('No memory cleanup action is attached.'),
      );
    });

    test('shows the memory statistics the action returns', () async {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () async => const <String, dynamic>{
          'componentCount': 9,
          'entityCount': 12,
        },
        interval: Duration.zero,
      );

      await controller.requestMemoryCleanup();

      expect(controller.memory.componentCount, 9);
      expect(controller.memory.cleanupAvailable, isTrue);
      expect(controller.logs.last.message, 'Memory cleanup completed.');
      expect(controller.logs.last.level, DebuggerLogLevel.info);
    });

    test('logs a failing action instead of throwing', () async {
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () async => throw StateError('busy'),
        interval: Duration.zero,
      );

      await controller.requestMemoryCleanup();

      expect(controller.logs.last.level, DebuggerLogLevel.error);
      expect(controller.logs.last.message, contains('busy'));
      expect(controller.isCleaningMemory, isFalse);
    });

    test('a second request while one runs joins it', () async {
      final gate = Completer<Map<String, dynamic>?>();
      var runs = 0;
      final controller = JustDebuggerController();
      addTearDown(controller.dispose);

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () {
          runs++;
          return gate.future;
        },
        interval: Duration.zero,
      );

      final first = controller.requestMemoryCleanup();
      final second = controller.requestMemoryCleanup();
      expect(identical(first, second), isTrue);
      expect(controller.isCleaningMemory, isTrue);

      gate.complete(null);
      await first;

      expect(runs, 1);
      expect(controller.isCleaningMemory, isFalse);
    });

    test('a cleanup that ends after dispose finishes quietly', () async {
      final gate = Completer<Map<String, dynamic>?>();
      final controller = JustDebuggerController();

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () => gate.future,
        interval: Duration.zero,
      );

      final cleanup = controller.requestMemoryCleanup();
      controller.dispose();
      gate.complete(const <String, dynamic>{'componentCount': 3});

      await expectLater(cleanup, completes);
    });

    test('a cleanup that fails after dispose finishes quietly', () async {
      final gate = Completer<Map<String, dynamic>?>();
      final controller = JustDebuggerController();

      controller.bind(
        statsProvider: () => const <String, dynamic>{},
        memoryCleanupAction: () => gate.future,
        interval: Duration.zero,
      );

      final cleanup = controller.requestMemoryCleanup();
      controller.dispose();
      gate.completeError(StateError('cache closed'));

      await expectLater(cleanup, completes);
    });
  });

  test('toggleOverlay flips or sets the overlay', () {
    final controller = JustDebuggerController(overlayVisible: false);
    addTearDown(controller.dispose);

    expect(controller.overlayVisible, isFalse);

    controller.toggleOverlay();
    expect(controller.overlayVisible, isTrue);

    controller.toggleOverlay(false);
    expect(controller.overlayVisible, isFalse);
  });

  test('the update methods replace the snapshots', () {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);

    controller.updateSnapshot(const EcsDebuggerSnapshot(entityCount: 2));
    controller.updatePerformance(
      const PerformanceDebuggerSnapshot(currentFps: 30),
    );
    controller.updateMemory(const MemoryDebuggerSnapshot(rssBytes: 4));

    expect(controller.snapshot.entityCount, 2);
    expect(controller.performance.currentFps, 30);
    expect(controller.memory.rssBytes, 4);

    controller.updateFromStats(
      const {'totalEntities': 7},
      componentUsage: const {'Transform': 7},
    );
    expect(controller.snapshot.entityCount, 7);
    expect(controller.snapshot.componentUsage, {'Transform': 7});
  });

  test('health reads the latest snapshots', () {
    final controller = JustDebuggerController(
      initialSnapshot: const EcsDebuggerSnapshot(
        entityCount: 250,
        systemCount: 8,
        activeSystemCount: 6,
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.health.hasWarnings, isTrue);
    expect(
      controller.health.messages,
      contains('Some ECS systems are currently inactive.'),
    );
  });
}
