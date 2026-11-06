import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  testWidgets('shows the latest performance snapshot', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);
    controller.updatePerformance(
      const PerformanceDebuggerSnapshot(
        currentFps: 60,
        frameNumber: 99,
        lastUpdateMs: 11.5,
        budgetRemainingMs: 5.1,
        isOverBudget: true,
        systemTimesMs: {'render': 3.0},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PerformanceDebuggerPanel(controller: controller)),
      ),
    );

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
    expect(find.text('11.5 ms'), findsOneWidget);
    expect(find.text('Frame budget exceeded.'), findsOneWidget);
    expect(find.text('render: 3.00 ms'), findsOneWidget);
  });
}
