import 'package:flutter/foundation.dart';

import '../snapshots/snapshots.dart';

/// Warnings worth showing about a world, read from its snapshots.
@immutable
class DebuggerHealth {
  /// A health report of [messages]; [isHealthy] when there are none.
  const DebuggerHealth({required this.messages, required this.isHealthy});

  /// The warnings, most important first.
  final List<String> messages;

  /// Whether nothing needs attention.
  final bool isHealthy;

  /// Whether there is at least one warning.
  bool get hasWarnings => messages.isNotEmpty;

  /// The warnings for [snapshot], plus [performance] and [memory] when
  /// given.
  ///
  /// It warns when:
  /// - the world holds 200 entities or more;
  /// - fewer systems are active than exist;
  /// - the slowest system took 4 ms or more;
  /// - [performance] is over its frame budget;
  /// - [memory]'s cache has fallen back to memory.
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
