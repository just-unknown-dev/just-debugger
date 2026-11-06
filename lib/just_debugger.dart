/// Visual ECS and runtime debugging tools for the Just Game Engine — or any
/// runtime that reports its statistics as plain maps.
///
/// - `JustDebuggerController` holds the latest snapshots, the log and the
///   overlay's visibility, and polls stats providers with `bind`.
/// - `JustDebuggerView` wraps a game with a `DebuggerOverlay` and an
///   optional inspector panel.
/// - `EcsDebuggerPanel`, `PerformanceDebuggerPanel`, `MemoryDebuggerPanel`
///   and `DebuggerLogConsole` can be placed on their own.
library;

export 'src/controller/controller.dart';
export 'src/snapshots/snapshots.dart';
export 'src/widgets/widgets.dart';
