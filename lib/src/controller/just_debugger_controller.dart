import 'dart:async';

import 'package:flutter/foundation.dart';

import '../snapshots/snapshots.dart';
import 'debugger_health.dart';

/// Reads a world's statistics for [EcsDebuggerSnapshot.fromStats].
typedef EcsStatsProvider = Map<String, dynamic> Function();

/// Counts each kind of component, by name.
typedef EcsComponentUsageProvider = Map<String, int> Function();

/// Reads what each system took on its last update, in milliseconds.
typedef EcsSystemTimesProvider = Map<String, double> Function();

/// Reads the game loop's statistics for
/// [PerformanceDebuggerSnapshot.fromStats].
typedef PerformanceStatsProvider = Map<String, dynamic> Function();

/// Reads memory statistics for [MemoryDebuggerSnapshot.fromStats].
typedef MemoryStatsProvider = Map<String, dynamic> Function();

/// Frees memory, and returns memory statistics read afterwards (for
/// [MemoryDebuggerSnapshot.fromStats]), or null to keep the last ones.
typedef MemoryCleanupAction = FutureOr<Map<String, dynamic>?> Function();

/// What the debugger shows: the latest snapshots, the log, and whether the
/// overlay is visible.
///
/// Feed it by hand ([updateSnapshot], [updatePerformance], [updateMemory],
/// [updateFromStats]) or have it poll providers with [bind]. Widgets listen
/// to it and rebuild when it changes.
class JustDebuggerController extends ChangeNotifier {
  /// A controller starting from [initialSnapshot] (an empty one by
  /// default), with the overlay shown when [overlayVisible].
  JustDebuggerController({
    EcsDebuggerSnapshot? initialSnapshot,
    bool overlayVisible = true,
  }) : _snapshot = initialSnapshot ?? const EcsDebuggerSnapshot(),
       _overlayVisible = overlayVisible;

  /// How many entries [logs] keeps; older ones are dropped first.
  static const int maxLogEntries = 200;

  EcsDebuggerSnapshot _snapshot;
  PerformanceDebuggerSnapshot _performance =
      const PerformanceDebuggerSnapshot();
  MemoryDebuggerSnapshot _memory = const MemoryDebuggerSnapshot();
  final List<DebuggerLogEntry> _logs = <DebuggerLogEntry>[];
  bool _overlayVisible;
  Timer? _bindingTimer;
  MemoryCleanupAction? _memoryCleanupAction;
  Future<void>? _cleanup;
  bool _refreshFailing = false;
  bool _disposed = false;

  /// The latest ECS snapshot.
  EcsDebuggerSnapshot get snapshot => _snapshot;

  /// The latest performance snapshot.
  PerformanceDebuggerSnapshot get performance => _performance;

  /// The latest memory snapshot.
  MemoryDebuggerSnapshot get memory => _memory;

  /// The log, oldest first, at most [maxLogEntries] long.
  List<DebuggerLogEntry> get logs => List.unmodifiable(_logs);

  /// Whether the overlay is shown.
  bool get overlayVisible => _overlayVisible;

  /// Whether [bind] is polling its providers.
  bool get isBound => _bindingTimer?.isActive ?? false;

  /// Whether a memory cleanup can be asked for: the memory snapshot says so,
  /// or [bind] was given a cleanup action.
  bool get canCleanupMemory =>
      _memory.cleanupAvailable || _memoryCleanupAction != null;

  /// Whether a [requestMemoryCleanup] is running.
  bool get isCleaningMemory => _cleanup != null;

  /// The warnings for the latest snapshots.
  DebuggerHealth get health => DebuggerHealth.fromSnapshot(
    _snapshot,
    performance: _performance,
    memory: _memory,
  );

  /// Shows [snapshot] as the latest ECS snapshot.
  void updateSnapshot(EcsDebuggerSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  /// Shows [snapshot] as the latest performance snapshot.
  void updatePerformance(PerformanceDebuggerSnapshot snapshot) {
    _performance = snapshot;
    notifyListeners();
  }

  /// Shows [snapshot] as the latest memory snapshot.
  void updateMemory(MemoryDebuggerSnapshot snapshot) {
    _memory = snapshot;
    notifyListeners();
  }

  /// Adds [message] to the log, stamped now.
  ///
  /// The log keeps the last [maxLogEntries] entries. Once the controller is
  /// disposed this does nothing, so work that finishes late may still log.
  void log(
    String message, {
    String category = 'general',
    DebuggerLogLevel level = DebuggerLogLevel.info,
  }) {
    if (_disposed) {
      return;
    }
    _logs.add(
      DebuggerLogEntry(
        message: message,
        category: category,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > maxLogEntries) {
      _logs.removeRange(0, _logs.length - maxLogEntries);
    }
    notifyListeners();
  }

  /// Empties the log.
  void clearLogs() {
    if (_logs.isEmpty) {
      return;
    }
    _logs.clear();
    notifyListeners();
  }

  /// Shows a snapshot read from [stats] (see [EcsDebuggerSnapshot.fromStats])
  /// as the latest ECS snapshot.
  void updateFromStats(
    Map<String, dynamic> stats, {
    Map<String, int>? componentUsage,
    Map<String, double>? systemTimesMs,
  }) {
    _snapshot = EcsDebuggerSnapshot.fromStats(
      stats,
      componentUsage: componentUsage,
      systemTimesMs: systemTimesMs,
    );
    notifyListeners();
  }

  /// Polls the providers every [interval] and shows what they read.
  ///
  /// One refresh asks [statsProvider], then [componentUsageProvider] and
  /// [systemTimesProvider] for the ECS snapshot, then
  /// [performanceStatsProvider] and [memoryStatsProvider] when given; a
  /// snapshot whose provider is not given keeps its last value.
  ///
  /// - [fireImmediately] refreshes once now, before the first tick.
  /// - An [interval] of [Duration.zero] (or less) never polls: with
  ///   [fireImmediately] it refreshes once.
  /// - [memoryCleanupAction] is what [requestMemoryCleanup] runs.
  ///
  /// A refresh is all or nothing: when a provider throws, every snapshot
  /// keeps its last value, the error is logged once (level
  /// [DebuggerLogLevel.error], category `debugger`), and polling goes on
  /// quietly until a refresh succeeds again.
  ///
  /// Binding again replaces the last binding; [stopBinding] ends it, and so
  /// does [dispose].
  void bind({
    required EcsStatsProvider statsProvider,
    EcsComponentUsageProvider? componentUsageProvider,
    EcsSystemTimesProvider? systemTimesProvider,
    PerformanceStatsProvider? performanceStatsProvider,
    MemoryStatsProvider? memoryStatsProvider,
    MemoryCleanupAction? memoryCleanupAction,
    Duration interval = const Duration(milliseconds: 250),
    bool fireImmediately = true,
  }) {
    _memoryCleanupAction = memoryCleanupAction;
    stopBinding();
    _refreshFailing = false;

    final providers = _Providers(
      stats: statsProvider,
      componentUsage: componentUsageProvider,
      systemTimes: systemTimesProvider,
      performance: performanceStatsProvider,
      memory: memoryStatsProvider,
    );

    if (fireImmediately) {
      _refresh(providers);
    }

    if (interval > Duration.zero) {
      _bindingTimer = Timer.periodic(interval, (_) => _refresh(providers));
    }
  }

  /// Stops polling the providers [bind] was given.
  void stopBinding() {
    _bindingTimer?.cancel();
    _bindingTimer = null;
  }

  void _refresh(_Providers providers) {
    final EcsDebuggerSnapshot snapshot;
    final PerformanceDebuggerSnapshot performance;
    final MemoryDebuggerSnapshot memory;
    try {
      snapshot = EcsDebuggerSnapshot.fromStats(
        providers.stats(),
        componentUsage: providers.componentUsage?.call(),
        systemTimesMs: providers.systemTimes?.call(),
      );
      final readPerformance = providers.performance;
      performance = readPerformance == null
          ? _performance
          : PerformanceDebuggerSnapshot.fromStats(readPerformance());
      final readMemory = providers.memory;
      if (readMemory == null) {
        memory = _memory;
      } else {
        final memoryStats = Map<String, dynamic>.from(readMemory());
        if (_memoryCleanupAction != null) {
          memoryStats['cleanupAvailable'] = true;
        }
        memory = MemoryDebuggerSnapshot.fromStats(memoryStats);
      }
    } catch (error) {
      if (!_refreshFailing) {
        _refreshFailing = true;
        log(
          'Reading the debugger stats failed: $error',
          category: 'debugger',
          level: DebuggerLogLevel.error,
        );
      }
      return;
    }

    _refreshFailing = false;
    _snapshot = snapshot;
    _performance = performance;
    _memory = memory;
    notifyListeners();
  }

  /// Runs the memory cleanup action [bind] was given, then shows the memory
  /// statistics it returns, and logs how it went.
  ///
  /// Without an action it logs a warning. While a cleanup runs, asking
  /// again returns the running one ([isCleaningMemory] is true meanwhile).
  /// A failing action is logged, not thrown. Once the controller is
  /// disposed, what a running action returns is dropped, and asking does
  /// nothing.
  Future<void> requestMemoryCleanup() {
    final running = _cleanup;
    if (running != null) {
      return running;
    }
    if (_disposed) {
      return Future<void>.value();
    }
    final action = _memoryCleanupAction;
    if (action == null) {
      log(
        'No memory cleanup action is attached.',
        category: 'memory',
        level: DebuggerLogLevel.warning,
      );
      return Future<void>.value();
    }

    final cleanup = _runCleanup(action).whenComplete(() {
      _cleanup = null;
      if (!_disposed) {
        notifyListeners();
      }
    });
    _cleanup = cleanup;
    notifyListeners();
    return cleanup;
  }

  Future<void> _runCleanup(MemoryCleanupAction action) async {
    try {
      final result = await action();
      if (_disposed) {
        return;
      }
      if (result != null) {
        final memoryStats = Map<String, dynamic>.from(result);
        memoryStats['cleanupAvailable'] = true;
        _memory = MemoryDebuggerSnapshot.fromStats(memoryStats);
      }
      log('Memory cleanup completed.', category: 'memory');
    } catch (error) {
      log(
        'Memory cleanup failed: $error',
        category: 'memory',
        level: DebuggerLogLevel.error,
      );
    }
  }

  /// Shows the overlay when [value] is true, hides it when false, and
  /// flips it when [value] is left out.
  void toggleOverlay([bool? value]) {
    final nextValue = value ?? !_overlayVisible;
    if (nextValue == _overlayVisible) {
      return;
    }
    _overlayVisible = nextValue;
    notifyListeners();
  }

  /// Stops polling and releases the controller.
  @override
  void dispose() {
    _disposed = true;
    stopBinding();
    super.dispose();
  }
}

/// What one [JustDebuggerController.bind] polls.
class _Providers {
  const _Providers({
    required this.stats,
    this.componentUsage,
    this.systemTimes,
    this.performance,
    this.memory,
  });

  final EcsStatsProvider stats;
  final EcsComponentUsageProvider? componentUsage;
  final EcsSystemTimesProvider? systemTimes;
  final PerformanceStatsProvider? performance;
  final MemoryStatsProvider? memory;
}
