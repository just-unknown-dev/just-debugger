import 'package:flutter/foundation.dart';

@immutable
class EcsDebuggerSnapshot {
  const EcsDebuggerSnapshot({
    this.entityCount = 0,
    this.activeEntityCount = 0,
    this.systemCount = 0,
    this.activeSystemCount = 0,
    this.archetypeCount = 0,
    this.componentUsage = const <String, int>{},
    this.systemTimesMs = const <String, double>{},
    this.capturedAt,
  });

  factory EcsDebuggerSnapshot.fromStats(
    Map<String, dynamic> stats, {
    Map<String, int>? componentUsage,
    Map<String, double>? systemTimesMs,
  }) {
    return EcsDebuggerSnapshot(
      entityCount: _readInt(stats, const ['entityCount', 'totalEntities']),
      activeEntityCount: _readInt(stats, const [
        'activeEntityCount',
        'activeEntities',
      ]),
      systemCount: _readInt(stats, const ['systemCount', 'systems']),
      activeSystemCount: _readInt(stats, const [
        'activeSystemCount',
        'activeSystems',
      ]),
      archetypeCount: _readInt(stats, const ['archetypeCount', 'archetypes']),
      componentUsage: componentUsage ?? const <String, int>{},
      systemTimesMs:
          systemTimesMs ?? _readDoubleMap(stats['systemTimesMs'] as Map?),
      capturedAt: DateTime.now(),
    );
  }

  final int entityCount;
  final int activeEntityCount;
  final int systemCount;
  final int activeSystemCount;
  final int archetypeCount;
  final Map<String, int> componentUsage;
  final Map<String, double> systemTimesMs;
  final DateTime? capturedAt;

  static int _readInt(Map<String, dynamic> stats, List<String> keys) {
    for (final key in keys) {
      final value = stats[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
    }
    return 0;
  }

  static Map<String, double> _readDoubleMap(Map? source) {
    if (source == null) {
      return const <String, double>{};
    }

    final output = <String, double>{};
    source.forEach((key, value) {
      if (key == null || value == null) {
        return;
      }
      if (value is num) {
        output[key.toString()] = value.toDouble();
      }
    });
    return Map.unmodifiable(output);
  }

  EcsDebuggerSnapshot copyWith({
    int? entityCount,
    int? activeEntityCount,
    int? systemCount,
    int? activeSystemCount,
    int? archetypeCount,
    Map<String, int>? componentUsage,
    Map<String, double>? systemTimesMs,
    DateTime? capturedAt,
  }) {
    return EcsDebuggerSnapshot(
      entityCount: entityCount ?? this.entityCount,
      activeEntityCount: activeEntityCount ?? this.activeEntityCount,
      systemCount: systemCount ?? this.systemCount,
      activeSystemCount: activeSystemCount ?? this.activeSystemCount,
      archetypeCount: archetypeCount ?? this.archetypeCount,
      componentUsage: componentUsage ?? this.componentUsage,
      systemTimesMs: systemTimesMs ?? this.systemTimesMs,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
