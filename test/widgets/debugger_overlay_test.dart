import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

Widget _host(JustDebuggerController controller) => MaterialApp(
  home: Scaffold(body: DebuggerOverlay(controller: controller)),
);

JustDebuggerController _controller() => JustDebuggerController(
  initialSnapshot: const EcsDebuggerSnapshot(
    entityCount: 42,
    activeEntityCount: 40,
    systemCount: 5,
    activeSystemCount: 5,
    archetypeCount: 4,
  ),
);

void main() {
  testWidgets('shows the ECS summary first', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));

    expect(find.text('ECS Debugger'), findsOneWidget);
    expect(find.text('ECS'), findsWidgets);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('switches between its tabs', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);

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
        counters: {'pools': 3, 'arenas': 2},
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

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();

    expect(find.text('60 fps'), findsOneWidget);
    expect(find.text('24 cmp'), findsOneWidget);
    expect(find.text('3 events'), findsOneWidget);

    await tester.tap(find.text('Performance'));
    await tester.pumpAndSettle();
    expect(find.text('FPS'), findsOneWidget);
    expect(find.text('11.5ms'), findsOneWidget);

    await tester.ensureVisible(find.text('Memory'));
    await tester.tap(find.text('Memory'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('RAM Availability'), findsOneWidget);
    expect(find.text('App Footprint'), findsOneWidget);
    expect(find.text('63% system RAM used • 5.0 GB / 8.0 GB'), findsOneWidget);
    expect(find.text('Pooled memory: 3 pools • 2 arenas'), findsOneWidget);
    expect(find.textContaining('A cleanup action is attached'), findsOneWidget);

    await tester.ensureVisible(find.text('Logs'));
    await tester.tap(find.text('Logs'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Clear Logs'), findsOneWidget);
    expect(find.textContaining('Overlay ready.'), findsOneWidget);

    await tester.tap(find.text('Errors').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Renderer crashed once.'), findsOneWidget);
    expect(find.textContaining('Overlay ready.'), findsNothing);
  });

  testWidgets('names no engine package in its memory text', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    controller.updateMemory(
      const MemoryDebuggerSnapshot(
        counters: {'pools': 1},
        rssBytes: 256 * 1024 * 1024,
        cleanupAvailable: true,
      ),
    );

    await tester.pumpWidget(_host(controller));
    await tester.ensureVisible(find.text('Memory'));
    await tester.tap(find.text('Memory'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('App Footprint'), findsOneWidget);
    expect(
      find.text(
        'App: 256.0 MB live RSS against a 512.0 MB soft budget',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('just_', skipOffstage: false), findsNothing);
  });

  testWidgets('is empty while the overlay is hidden', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));
    controller.toggleOverlay(false);
    await tester.pump();

    expect(find.text('ECS Debugger'), findsNothing);
  });
}
