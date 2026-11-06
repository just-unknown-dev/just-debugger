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

`just_debugger` is intended for development builds and internal tooling. In this workspace it is used alongside the Just Game Engine packages, but the UI can be fed by any runtime that reports its statistics as plain maps: the widgets name no engine.

Typical setup:

1. Create a `JustDebuggerController`.
2. Bind it to your runtime statistics with `bind`.
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
  final controller = JustDebuggerController();

  @override
  void initState() {
    super.initState();
    controller.bind(
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
        'currentFPS': 60,
        'lastUpdateMs': 11.2,
        'budgetRemainingMs': 5.4,
      },
      memoryStatsProvider: () => {
        'componentCount': 30,
        'rssBytes': 42 * 1024 * 1024,
      },
      interval: const Duration(milliseconds: 250),
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
    return JustDebuggerView(
      controller: controller,
      showOverlay: true,
      showInspectorPanel: true,
      child: const Placeholder(),
    );
  }
}
```

`example/main.dart` is a runnable version.

### What the providers report

Each snapshot reads a few keys from its map; the first key that holds a finite number wins, and anything missing reads as zero. The dartdoc of each `fromStats` lists them:

| Snapshot | Keys |
|---|---|
| `EcsDebuggerSnapshot` | `entityCount`/`totalEntities`, `activeEntityCount`/`activeEntities`, `systemCount`/`systems`, `activeSystemCount`/`activeSystems`, `archetypeCount`/`archetypes`, `systemTimesMs` |
| `PerformanceDebuggerSnapshot` | `currentFPS`/`fps`, `frame`/`frameNumber`, `lastUpdateMs`/`updateMs`, `budgetRemainingMs`, `isOverBudget`, `systemTimesMs` |
| `MemoryDebuggerSnapshot` | `componentCount`, `entityCount`/`activeEntities`, `totalPhysicalMemoryBytes`, `freePhysicalMemoryBytes`, `rssBytes`/`currentRssBytes` (also read from a nested `systemMemory` map), `cacheFallback`/`usingCacheFallback`, `counters`, `cleanupAvailable` |

### Polling and errors

`bind` refreshes every `interval` (250 ms by default); `Duration.zero` refreshes once and never polls, and `fireImmediately: false` waits for the first tick. A refresh is all or nothing: when a provider throws — say, it reads a world that was just torn down — every snapshot keeps its last value, the error is logged once at `DebuggerLogLevel.error` under the `debugger` category, and polling goes on quietly until a refresh succeeds again. `stopBinding` or `dispose` ends polling.

`requestMemoryCleanup` runs the `memoryCleanupAction` given to `bind`. A second request while one runs joins it, a failure is logged rather than thrown, and a cleanup that finishes after the controller is disposed is dropped quietly.

### Main building blocks

- `JustDebuggerController` manages snapshots, logs (the last 200), health state, and overlay visibility.
- `JustDebuggerView` wraps your app or game surface and renders the `DebuggerOverlay` and an optional inspector panel.
- `EcsDebuggerPanel`, `PerformanceDebuggerPanel`, and `MemoryDebuggerPanel` can be embedded separately in custom layouts.
- `DebuggerLogConsole` shows runtime messages emitted through the controller.
- `DebuggerHealth` turns the latest snapshots into warnings (200+ entities, inactive systems, a system at 4 ms or more, an exceeded frame budget, a cache fallback).

## Recommended use cases

Use this package when you want to:

- inspect a live ECS world during gameplay
- visualize entity and system counts while tuning features
- watch frame timing during performance passes
- track memory behavior while loading assets or scenes
- expose a lightweight debug HUD for internal QA or development builds

## Additional information

This package is part of the Just Game Engine workspace and is currently geared toward internal development workflows. It is best enabled behind debug flags or included only in non-production builds.
