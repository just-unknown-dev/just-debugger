import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  testWidgets('filters by level and clears the log', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);
    controller.log('Attached.', category: 'runtime');
    controller.log(
      'Slow frame.',
      category: 'performance',
      level: DebuggerLogLevel.warning,
    );
    controller.log(
      'Shader failed.',
      category: 'render',
      level: DebuggerLogLevel.error,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: DebuggerLogConsole(controller: controller),
          ),
        ),
      ),
    );

    expect(find.text('Total: 3'), findsOneWidget);
    expect(find.text('Errors: 1'), findsOneWidget);
    expect(find.text('Attached.'), findsOneWidget);
    expect(find.text('Shader failed.'), findsOneWidget);

    await tester.tap(find.text('Errors'));
    await tester.pump();
    expect(find.text('Shader failed.'), findsOneWidget);
    expect(find.text('Attached.'), findsNothing);
    expect(find.text('Slow frame.'), findsNothing);

    await tester.tap(find.text('Warnings'));
    await tester.pump();
    expect(find.text('Slow frame.'), findsOneWidget);
    expect(find.text('Shader failed.'), findsNothing);

    await tester.tap(find.text('Clear Logs'));
    await tester.pump();
    expect(controller.logs, isEmpty);
    expect(find.text('Total: 0'), findsOneWidget);
    expect(
      find.text('No debugger logs match the current filter.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the newest entry first', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);
    controller.log('first');
    controller.log('second');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: DebuggerLogConsole(controller: controller),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.text('first'));
    final second = tester.getTopLeft(find.text('second'));
    expect(second.dy, lessThan(first.dy));
  });
}
