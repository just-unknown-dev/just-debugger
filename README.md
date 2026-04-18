# Just Debugger

Visual ECS and runtime debugging tools for projects built with the Just Game Engine.

This package provides a lightweight development UI for inspecting a live world, tracking runtime health, reviewing logs, and surfacing performance and memory information without building a custom debug screen from scratch.

## Features

- Live ECS summaries for entities, systems, component usage, and system timings
- Compact overlay for quick in-game visibility
- Optional inspector panel for deeper debugging sessions
- Performance panel for frame-budget and runtime stats
- Memory panel with optional cleanup action support
- Built-in log console with levels and categories
- Flexible controller API that can be driven by your own stats providers

## Getting started

`just_debugger` is intended for development builds and internal tooling. In this workspace it is used alongside the Just Game Engine packages, but the UI can also be fed by any runtime that exposes simple map-based stats.

Typical setup:

1. Create a `JustDebuggerController`.
2. Bind it to your runtime statistics.
3. Wrap your game or preview widget with `JustDebuggerView`.
4. Enable the overlay and optional inspector panel while developing.

## Usage

### Basic integration

```dart
import 'package:flutter/material.dart';
import 'package:just_debugger/just_debugger.dart';

class DebugPreview extends StatefulWidget {
  const DebugPreview({super.key});

  @override
  State<DebugPreview> createState() => _DebugPreviewState();
}

class _DebugPreviewState extends State<DebugPreview> {
  late final JustDebuggerController controller;

  @override
  void initState() {
    super.initState();
    controller = JustDebuggerController();

    controller.bindToSources(
      statsProvider: () => {
        'entityCount': 18,
        'systemCount': 4,
        'activeSystemCount': 4,
      },
      componentUsageProvider: () => {
        'Transform': 18,
        'Velocity': 12,
      },
      systemTimesProvider: () => {
        'MovementSystem': 0.4,
        'RenderPrepSystem': 0.8,
      },
      performanceStatsProvider: () => {
        'fps': 60.0,
        'frameTimeMs': 16.6,
        'budgetMs': 16.6,
      },
      memoryStatsProvider: () => {
        'usedMb': 42.0,
        'peakMb': 58.0,
      },
      interval: const Duration(milliseconds: 250),
    );

    controller.log('Debugger attached.', category: 'runtime');
  }

  @override
  Widget build(BuildContext context) {
    return JustDebuggerView(
      controller: controller,
      showOverlay: true,
      showInspectorPanel: true,
      child: const Placeholder(),
    );
  }
}
```

### Main building blocks

- `JustDebuggerController` manages snapshots, logs, health state, and overlay visibility.
- `JustDebuggerView` wraps your app or game surface and renders the overlay UI.
- `EcsDebuggerPanel`, `PerformanceDebuggerPanel`, and `MemoryDebuggerPanel` can be embedded separately in custom layouts.
- `DebuggerLogConsole` shows runtime messages emitted through the controller.

## Recommended use cases

Use this package when you want to:

- inspect a live ECS world during gameplay
- visualize entity and system counts while tuning features
- watch frame timing during performance passes
- track memory behavior while loading assets or scenes
- expose a lightweight debug HUD for internal QA or development builds

## Additional information

This package is part of the Just Game Engine workspace and is currently geared toward internal development workflows. It is best enabled behind debug flags or included only in non-production builds.
