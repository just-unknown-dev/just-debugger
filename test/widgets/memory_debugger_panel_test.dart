import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

Widget _host(JustDebuggerController controller) => MaterialApp(
  home: Scaffold(body: MemoryDebuggerPanel(controller: controller)),
);

ElevatedButton _button(WidgetTester tester) => tester.widget<ElevatedButton>(
  find.byWidgetPredicate((widget) => widget is ElevatedButton),
);

void main() {
  testWidgets('shows the machine RAM when it is known', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);
    controller.updateMemory(
      const MemoryDebuggerSnapshot(
        componentCount: 24,
        usingCacheFallback: true,
        counters: {'pools': 2},
        totalPhysicalMemoryBytes: 8 * 1024 * 1024 * 1024,
        freePhysicalMemoryBytes: 2 * 1024 * 1024 * 1024,
        rssBytes: 512 * 1024 * 1024,
      ),
    );

    await tester.pumpWidget(_host(controller));

    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('RAM Availability'), findsOneWidget);
    expect(find.text('512.0 MB'), findsOneWidget);
    expect(find.text('25% free • 2.0 GB available of 8.0 GB'), findsOneWidget);
    expect(
      find.text('The cache is running in memory fallback mode.'),
      findsOneWidget,
    );
    expect(find.text('pools: 2'), findsOneWidget);
    expect(find.text('Free Up RAM'), findsNothing);
  });

  testWidgets('falls back to the app footprint', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);
    controller.updateMemory(
      const MemoryDebuggerSnapshot(rssBytes: 128 * 1024 * 1024),
    );

    await tester.pumpWidget(_host(controller));

    expect(find.textContaining('512.0 MB soft budget'), findsOneWidget);
  });

  testWidgets('Free Up RAM is off while a cleanup runs', (tester) async {
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

    await tester.pumpWidget(_host(controller));
    expect(find.text('Free Up RAM'), findsOneWidget);
    expect(find.textContaining('just_'), findsNothing);
    expect(_button(tester).onPressed, isNotNull);

    await tester.tap(find.text('Free Up RAM'));
    await tester.pump();
    expect(_button(tester).onPressed, isNull);

    await tester.tap(find.text('Free Up RAM'), warnIfMissed: false);
    await tester.pump();
    expect(runs, 1);

    gate.complete(null);
    await tester.pumpAndSettle();
    expect(_button(tester).onPressed, isNotNull);
    expect(controller.logs.last.message, 'Memory cleanup completed.');
  });
}
