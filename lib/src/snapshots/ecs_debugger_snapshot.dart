import 'package:flutter/foundation.dart';

import 'stat_reading.dart';

/// What an ECS world looked like at one moment: how many entities and
/// systems it had, and what they cost.
///
/// Make one from a plain statistics map with [EcsDebuggerSnapshot.fromStats],
/// or directly with the constructor.
@immutable
class EcsDebuggerSnapshot {
  /// A snapshot with the given counts; everything left out is zero or empty.
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

  /// A snapshot read from [stats], taken now.
  ///
  /// Each count reads the first of its keys that holds a finite number, and
  /// is 0 when none does:
  ///
  /// | Field | Keys |
  /// |---|---|
  /// | [entityCount] | `entityCount`, `totalEntities` |
  /// | [activeEntityCount] | `activeEntityCount`, `activeEntities` |
  /// | [systemCount] | `systemCount`, `systems` |
  /// | [activeSystemCount] | `activeSystemCount`, `activeSystems` |
  /// | [archetypeCount] | `archetypeCount`, `archetypes` |
  ///
  /// [systemTimesMs] is the given map, or else the map under the
  /// `systemTimesMs` key. [componentUsage] is the given map, or empty.
  factory EcsDebuggerSnapshot.fromStats(
    Map<String, dynamic> stats, {
    Map<String, int>? componentUsage,
    Map<String, double>? systemTimesMs,
  }) {
    return EcsDebuggerSnapshot(
      entityCount: readStatInt(stats, const ['entityCount', 'totalEntities']),
      activeEntityCount: readStatInt(stats, const [
        'activeEntityCount',
        'activeEntities',
      ]),
      systemCount: readStatInt(stats, const ['systemCount', 'systems']),
      activeSystemCount: readStatInt(stats, const [
        'activeSystemCount',
        'activeSystems',
      ]),
      archetypeCount: readStatInt(stats, const [
        'archetypeCount',
        'archetypes',
      ]),
      componentUsage: componentUsage ?? const <String, int>{},
      systemTimesMs: systemTimesMs ?? readStatDoubleMap(stats['systemTimesMs']),
      capturedAt: DateTime.now(),
    );
  }

  /// How many entities the world holds.
  final int entityCount;

  /// How many of [entityCount] are active.
  final int activeEntityCount;

  /// How many systems the world runs.
  final int systemCount;

  /// How many of [systemCount] are enabled.
  final int activeSystemCount;

  /// How many archetypes (distinct sets of component types) the world has.
  final int archetypeCount;

  /// How many of each kind of component the entities carry, by name.
  final Map<String, int> componentUsage;

  /// What each system took on its last update, in milliseconds, by name.
  final Map<String, double> systemTimesMs;

  /// When the snapshot was taken; null when it was made by hand.
  final DateTime? capturedAt;

  /// A copy with the given fields replaced.
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
