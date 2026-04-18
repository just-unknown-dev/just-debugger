import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:just_debugger/just_debugger.dart';

void main() {
  group('ECS debugger controller', () {
    test('flags high entity counts and inactive systems', () {
      final snapshot = EcsDebuggerSnapshot(
        entityCount: 250,
        activeEntityCount: 220,
        systemCount: 8,
        activeSystemCount: 6,
        archetypeCount: 12,
        componentUsage: const {'Transform': 220, 'Velocity': 180},
        systemTimesMs: const {'movement': 1.2, 'physics': 3.4},
      );

      final controller = JustDebuggerController(initialSnapshot: snapshot);

      expect(controller.snapshot.entityCount, 250);
      expect(controller.health.hasWarnings, isTrue);
      expect(
        controller.health.messages,
        contains('Some ECS systems are currently inactive.'),
      );
    });

    testWidgets('overlay shows ECS summary values', (tester) async {
      final controller = JustDebuggerController(
        initialSnapshot: const EcsDebuggerSnapshot(
          entityCount: 42,
          activeEntityCount: 40,
          systemCount: 5,
          activeSystemCount: 5,
          archetypeCount: 4,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EcsDebuggerOverlay(controller: controller)),
        ),
      );

      expect(find.text('ECS'), findsWidgets);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('overlay exposes debugger tabs and summaries', (tester) async {
      final controller = JustDebuggerController(
        initialSnapshot: const EcsDebuggerSnapshot(
          entityCount: 42,
          activeEntityCount: 40,
          systemCount: 5,
          activeSystemCount: 5,
          archetypeCount: 4,
        ),
      );

      controller.updatePerformance(
        const PerformanceDebuggerSnapshot(
          currentFps: 60,
          frameNumber: 12,
          lastUpdateMs: 11.5,
          budgetRemainingMs: 5.2,
          systemTimesMs: {'render': 2.3},
        ),
      );
      controller.updateMemory(
        const MemoryDebuggerSnapshot(
          componentCount: 24,
          entityCount: 42,
          counters: {'systems': 5},
          totalPhysicalMemoryBytes: 8 * 1024 * 1024 * 1024,
          freePhysicalMemoryBytes: 3 * 1024 * 1024 * 1024,
          rssBytes: 512 * 1024 * 1024,
          cleanupAvailable: true,
        ),
      );
      controller.log('Overlay ready.', category: 'runtime');
      controller.log(
        'Physics spike detected.',
        category: 'physics',
        level: DebuggerLogLevel.warning,
      );
      controller.log(
        'Renderer crashed once.',
        category: 'render',
        level: DebuggerLogLevel.error,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EcsDebuggerOverlay(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);

      await tester.tap(find.text('Performance'));
      await tester.pumpAndSettle();
      expect(find.text('FPS'), findsOneWidget);

      await tester.ensureVisible(find.text('Memory'));
      await tester.tap(find.text('Memory'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Components'), findsOneWidget);
      expect(find.text('RAM Availability'), findsOneWidget);
      expect(find.text('Engine + Game Footprint'), findsOneWidget);
      expect(find.textContaining('Optimization headroom'), findsOneWidget);
      expect(find.textContaining('just_memory'), findsOneWidget);

      await tester.ensureVisible(find.text('Logs'));
      await tester.tap(find.text('Logs'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Clear Logs'), findsOneWidget);
      expect(find.text('Warnings'), findsWidgets);
      expect(find.textContaining('Overlay ready.'), findsOneWidget);
    });

    testWidgets('controller binds to live ECS stats', (tester) async {
      var tick = 0;
      final controller = JustDebuggerController();

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

      await tester.pump();
      expect(controller.snapshot.entityCount, 10);

      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.snapshot.entityCount, 20);

      controller.stopBinding();
    });

    test('controller stores performance, memory, and log data', () {
      final controller = JustDebuggerController();

      controller.bind(
        statsProvider: () => const <String, dynamic>{
          'entityCount': 12,
          'activeEntityCount': 10,
          'systemCount': 3,
          'activeSystemCount': 3,
          'archetypeCount': 2,
        },
        performanceStatsProvider: () => const <String, dynamic>{
          'frame': 120,
          'currentFPS': 58,
          'lastUpdateMs': 12.4,
          'budgetRemainingMs': 4.2,
          'isOverBudget': false,
          'systemTimesMs': <String, double>{'physics': 2.1},
        },
        memoryStatsProvider: () => const <String, dynamic>{
          'componentCount': 24,
          'cacheFallback': true,
        },
        interval: Duration.zero,
      );

      controller.log('Debugger attached.', category: 'runtime');

      expect(controller.performance.currentFps, 58);
      expect(controller.memory.componentCount, 24);
      expect(controller.memory.usingCacheFallback, isTrue);
      expect(controller.logs.last.message, 'Debugger attached.');
    });

    testWidgets('performance, memory, and log panels render', (tester) async {
      final controller = JustDebuggerController(
        initialSnapshot: const EcsDebuggerSnapshot(
          entityCount: 12,
          activeEntityCount: 11,
          systemCount: 3,
          activeSystemCount: 3,
          archetypeCount: 2,
        ),
      );

      controller.updatePerformance(
        const PerformanceDebuggerSnapshot(
          currentFps: 60,
          frameNumber: 99,
          lastUpdateMs: 11.5,
          budgetRemainingMs: 5.1,
          systemTimesMs: {'render': 3.0},
        ),
      );
      controller.updateMemory(
        const MemoryDebuggerSnapshot(
          componentCount: 24,
          usingCacheFallback: true,
          totalPhysicalMemoryBytes: 8 * 1024 * 1024 * 1024,
          freePhysicalMemoryBytes: 3 * 1024 * 1024 * 1024,
          rssBytes: 512 * 1024 * 1024,
          cleanupAvailable: true,
        ),
      );
      controller.log('Frame budget stable.', category: 'performance');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: PerformanceDebuggerPanel(controller: controller),
                ),
                Expanded(child: MemoryDebuggerPanel(controller: controller)),
                Expanded(child: DebuggerLogConsole(controller: controller)),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('RAM Availability'), findsOneWidget);
      expect(find.text('Free Up RAM'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Frame budget stable.'), findsOneWidget);
    });

    test('controller toggles overlay visibility', () {
      final controller = JustDebuggerController(overlayVisible: false);

      expect(controller.overlayVisible, isFalse);

      controller.toggleOverlay();
      expect(controller.overlayVisible, isTrue);

      controller.toggleOverlay(false);
      expect(controller.overlayVisible, isFalse);
    });

    test('memory cleanup without action writes a warning log', () async {
      final controller = JustDebuggerController();

      await controller.requestMemoryCleanup();

      expect(controller.logs, hasLength(1));
      expect(controller.logs.single.level, DebuggerLogLevel.warning);
      expect(
        controller.logs.single.message,
        contains('No memory cleanup action is attached.'),
      );
    });

    test('memory cleanup action refreshes the memory snapshot', () async {
      final controller = JustDebuggerController();

      controller.bind(
        statsProvider: () => const <String, dynamic>{
          'entityCount': 12,
          'activeEntityCount': 12,
          'systemCount': 3,
          'activeSystemCount': 3,
          'archetypeCount': 1,
        },
        memoryCleanupAction: () async => const <String, dynamic>{
          'componentCount': 9,
          'entityCount': 12,
          'cleanupAvailable': true,
        },
        interval: Duration.zero,
      );

      await controller.requestMemoryCleanup();

      expect(controller.memory.componentCount, 9);
      expect(controller.logs.last.message, 'Memory cleanup completed.');
      expect(controller.logs.last.level, DebuggerLogLevel.info);
    });

    testWidgets('debugger view overlays the wrapped child', (tester) async {
      final controller = JustDebuggerController(
        initialSnapshot: const EcsDebuggerSnapshot(
          entityCount: 7,
          activeEntityCount: 7,
          systemCount: 1,
          activeSystemCount: 1,
          archetypeCount: 2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JustDebuggerView(
            controller: controller,
            child: const Placeholder(),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.text('ECS Debugger'), findsOneWidget);
    });
  });
}
