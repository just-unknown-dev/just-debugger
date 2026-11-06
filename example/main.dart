import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_debugger/just_debugger.dart';

/// A stand-in for a game: the debugger reads it through plain maps.
class FakeWorld {
  final _random = Random();
  int frame = 0;

  Map<String, dynamic> stats() => {
    'entityCount': 180 + _random.nextInt(40),
    'activeEntityCount': 170,
    'systemCount': 4,
    'activeSystemCount': 4,
    'archetypeCount': 6,
  };

  Map<String, dynamic> performance() => {
    'currentFPS': 58 + _random.nextInt(3),
    'frame': frame += 15,
    'lastUpdateMs': 10 + _random.nextDouble() * 4,
    'budgetRemainingMs': 3.0,
    'isOverBudget': false,
  };

  Map<String, dynamic> memory() => {
    'componentCount': 540,
    'entityCount': 180,
    'rssBytes': 210 * 1024 * 1024,
    'counters': {'pools': 3, 'arenas': 1},
  };
}

void main() => runApp(const MaterialApp(home: DebugPreview()));

class DebugPreview extends StatefulWidget {
  const DebugPreview({super.key});

  @override
  State<DebugPreview> createState() => _DebugPreviewState();
}

class _DebugPreviewState extends State<DebugPreview> {
  final world = FakeWorld();
  final controller = JustDebuggerController();

  @override
  void initState() {
    super.initState();
    controller.bind(
      statsProvider: world.stats,
      componentUsageProvider: () => {'Transform': 180, 'Velocity': 120},
      systemTimesProvider: () => {'MovementSystem': 0.4, 'RenderSystem': 1.8},
      performanceStatsProvider: world.performance,
      memoryStatsProvider: world.memory,
      memoryCleanupAction: () async => world.memory(),
    );
    controller.log('Debugger attached.', category: 'runtime');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: JustDebuggerView(
        controller: controller,
        showInspectorPanel: true,
        child: const ColoredBox(color: Color(0xFF1B2838)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.toggleOverlay,
        child: const Icon(Icons.bug_report_outlined),
      ),
    );
  }
}
