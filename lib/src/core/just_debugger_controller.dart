import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ecs/ecs_debugger_snapshot.dart';
import '../logs/debugger_log_entry.dart';
import '../memory/memory_debugger_snapshot.dart';
import '../performance/performance_debugger_snapshot.dart';

typedef EcsStatsProvider = Map<String, dynamic> Function();
typedef EcsComponentUsageProvider = Map<String, int> Function();
typedef EcsSystemTimesProvider = Map<String, double> Function();
typedef PerformanceStatsProvider = Map<String, dynamic> Function();
typedef MemoryStatsProvider = Map<String, dynamic> Function();
typedef MemoryCleanupAction = FutureOr<Map<String, dynamic>?> Function();

@immutable
class DebuggerHealth {
  const DebuggerHealth({required this.messages, required this.isHealthy});

  final List<String> messages;
  final bool isHealthy;

  bool get hasWarnings => messages.isNotEmpty;

  factory DebuggerHealth.fromSnapshot(
    EcsDebuggerSnapshot snapshot, {
    PerformanceDebuggerSnapshot? performance,
    MemoryDebuggerSnapshot? memory,
  }) {
    final messages = <String>[];

    if (snapshot.entityCount >= 200) {
      messages.add('High entity count detected. Consider reviewing ECS load.');
    }

    if (snapshot.activeSystemCount < snapshot.systemCount) {
      messages.add('Some ECS systems are currently inactive.');
    }

    final hottestSystem = _findHottestSystem(snapshot.systemTimesMs);
    if (hottestSystem != null && hottestSystem.value >= 4.0) {
      messages.add(
        '${hottestSystem.key} is taking ${hottestSystem.value.toStringAsFixed(1)} ms.',
      );
    }

    if (performance != null && performance.isOverBudget) {
      messages.add('Frame budget is currently being exceeded.');
    }

    if (memory != null && memory.usingCacheFallback) {
      messages.add('Memory cache fallback is active.');
    }

    return DebuggerHealth(
      messages: List.unmodifiable(messages),
      isHealthy: messages.isEmpty,
    );
  }

  static MapEntry<String, double>? _findHottestSystem(
    Map<String, double> times,
  ) {
    MapEntry<String, double>? hottest;
    for (final entry in times.entries) {
      if (hottest == null || entry.value > hottest.value) {
        hottest = entry;
      }
    }
    return hottest;
  }
}

class JustDebuggerController extends ChangeNotifier {
  JustDebuggerController({
    EcsDebuggerSnapshot? initialSnapshot,
    bool overlayVisible = true,
  }) : _snapshot = initialSnapshot ?? const EcsDebuggerSnapshot(),
       _overlayVisible = overlayVisible;

  EcsDebuggerSnapshot _snapshot;
  PerformanceDebuggerSnapshot _performance =
      const PerformanceDebuggerSnapshot();
  MemoryDebuggerSnapshot _memory = const MemoryDebuggerSnapshot();
  final List<DebuggerLogEntry> _logs = <DebuggerLogEntry>[];
  bool _overlayVisible;
  Timer? _bindingTimer;
  MemoryCleanupAction? _memoryCleanupAction;

  EcsDebuggerSnapshot get snapshot => _snapshot;
  PerformanceDebuggerSnapshot get performance => _performance;
  MemoryDebuggerSnapshot get memory => _memory;
  List<DebuggerLogEntry> get logs => List.unmodifiable(_logs);
  bool get overlayVisible => _overlayVisible;
  bool get isBound => _bindingTimer?.isActive ?? false;
  bool get canCleanupMemory =>
      _memory.cleanupAvailable || _memoryCleanupAction != null;
  DebuggerHealth get health => DebuggerHealth.fromSnapshot(
    _snapshot,
    performance: _performance,
    memory: _memory,
  );

  void updateSnapshot(EcsDebuggerSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  void updatePerformance(PerformanceDebuggerSnapshot snapshot) {
    _performance = snapshot;
    notifyListeners();
  }

  void updateMemory(MemoryDebuggerSnapshot snapshot) {
    _memory = snapshot;
    notifyListeners();
  }

  void log(
    String message, {
    String category = 'general',
    DebuggerLogLevel level = DebuggerLogLevel.info,
  }) {
    _logs.add(
      DebuggerLogEntry(
        message: message,
        category: category,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > 200) {
      _logs.removeRange(0, _logs.length - 200);
    }
    notifyListeners();
  }

  void clearLogs() {
    if (_logs.isEmpty) {
      return;
    }
    _logs.clear();
    notifyListeners();
  }

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

    if (fireImmediately) {
      _refreshFromProviders(
        statsProvider,
        componentUsageProvider,
        systemTimesProvider,
        performanceStatsProvider,
        memoryStatsProvider,
      );
    }

    if (interval > Duration.zero) {
      _bindingTimer = Timer.periodic(interval, (_) {
        _refreshFromProviders(
          statsProvider,
          componentUsageProvider,
          systemTimesProvider,
          performanceStatsProvider,
          memoryStatsProvider,
        );
      });
    }
  }

  void stopBinding() {
    _bindingTimer?.cancel();
    _bindingTimer = null;
  }

  void _refreshFromProviders(
    EcsStatsProvider statsProvider,
    EcsComponentUsageProvider? componentUsageProvider,
    EcsSystemTimesProvider? systemTimesProvider,
    PerformanceStatsProvider? performanceStatsProvider,
    MemoryStatsProvider? memoryStatsProvider,
  ) {
    _snapshot = EcsDebuggerSnapshot.fromStats(
      statsProvider(),
      componentUsage: componentUsageProvider?.call(),
      systemTimesMs: systemTimesProvider?.call(),
    );

    if (performanceStatsProvider != null) {
      _performance = PerformanceDebuggerSnapshot.fromStats(
        performanceStatsProvider(),
      );
    }

    if (memoryStatsProvider != null) {
      final memoryStats = Map<String, dynamic>.from(memoryStatsProvider());
      if (_memoryCleanupAction != null) {
        memoryStats['cleanupAvailable'] = true;
      }
      _memory = MemoryDebuggerSnapshot.fromStats(memoryStats);
    }

    notifyListeners();
  }

  Future<void> requestMemoryCleanup() async {
    final action = _memoryCleanupAction;
    if (action == null) {
      log(
        'No memory cleanup action is attached.',
        category: 'memory',
        level: DebuggerLogLevel.warning,
      );
      return;
    }

    try {
      final result = await action();
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

  void toggleOverlay([bool? value]) {
    final nextValue = value ?? !_overlayVisible;
    if (nextValue == _overlayVisible) {
      return;
    }
    _overlayVisible = nextValue;
    notifyListeners();
  }

  @override
  void dispose() {
    stopBinding();
    super.dispose();
  }
}
