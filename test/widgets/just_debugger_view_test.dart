import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/just_debugger.dart';

void main() {
  testWidgets('overlays the wrapped child', (tester) async {
    final controller = JustDebuggerController(
      initialSnapshot: const EcsDebuggerSnapshot(entityCount: 7),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: JustDebuggerView(
          controller: controller,
          child: const Placeholder(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(DebuggerOverlay), findsOneWidget);
    expect(find.text('ECS Debugger'), findsOneWidget);
    expect(find.byType(EcsDebuggerPanel), findsNothing);
  });

  testWidgets('shows the inspector panel when asked', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: JustDebuggerView(
          controller: controller,
          showOverlay: false,
          showInspectorPanel: true,
          child: const Placeholder(),
        ),
      ),
    );

    expect(find.byType(DebuggerOverlay), findsNothing);
    expect(find.text('ECS Inspector'), findsOneWidget);
  });

  testWidgets('takes another inspector child', (tester) async {
    final controller = JustDebuggerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: JustDebuggerView(
          controller: controller,
          showInspectorPanel: true,
          inspectorChild: const Text('custom'),
          child: const Placeholder(),
        ),
      ),
    );

    expect(find.text('custom'), findsOneWidget);
    expect(find.byType(EcsDebuggerPanel), findsNothing);
  });
}
