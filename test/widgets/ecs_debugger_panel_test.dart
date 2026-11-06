import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  testWidgets('shows counts, usage, timings and warnings', (tester) async {
    final controller = JustDebuggerController(
      initialSnapshot: const EcsDebuggerSnapshot(
        entityCount: 12,
        activeEntityCount: 11,
        systemCount: 3,
        activeSystemCount: 2,
        archetypeCount: 2,
        componentUsage: {'Transform': 12},
        systemTimesMs: {'physics': 1.25},
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EcsDebuggerPanel(controller: controller)),
      ),
    );

    expect(find.text('ECS Inspector'), findsOneWidget);
    expect(find.text('Transform: 12'), findsOneWidget);
    expect(find.text('physics: 1.25 ms'), findsOneWidget);
    expect(find.text('• Some ECS systems are currently inactive.'), findsOne);
  });

  testWidgets('says when nothing has been published', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EcsDebuggerPanel(controller: controller)),
      ),
    );

    expect(
      find.text('No component usage has been published yet.'),
      findsOneWidget,
    );
    expect(find.text('No system timing data available yet.'), findsOneWidget);
    expect(find.text('Warnings'), findsNothing);
  });
}
