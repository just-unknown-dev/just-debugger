import 'package:flutter/foundation.dart';

import 'stat_reading.dart';

/// How memory looked at one moment: the app's footprint, the system's RAM,
/// and the counters a runtime publishes.
@immutable
class MemoryDebuggerSnapshot {
  /// A snapshot with the given values; everything left out is zero, empty
  /// or false.
  const MemoryDebuggerSnapshot({
    this.componentCount = 0,
    this.entityCount = 0,
    this.usingCacheFallback = false,
    this.counters = const <String, int>{},
    this.totalPhysicalMemoryBytes = 0,
    this.freePhysicalMemoryBytes = 0,
    this.rssBytes = 0,
    this.cleanupAvailable = false,
    this.capturedAt,
  });

  /// A snapshot read from [stats], taken now.
  ///
  /// The counts and sizes are read from [stats] first and then from the map
  /// under its `systemMemory` key; the first positive finite number wins,
  /// and 0 when there is none:
  ///
  /// | Field | Keys |
  /// |---|---|
  /// | [componentCount] | `componentCount` |
  /// | [entityCount] | `entityCount`, `activeEntities` |
  /// | [totalPhysicalMemoryBytes] | `totalPhysicalMemoryBytes` |
  /// | [freePhysicalMemoryBytes] | `freePhysicalMemoryBytes` |
  /// | [rssBytes] | `rssBytes`, `currentRssBytes` |
  ///
  /// [usingCacheFallback] is true when `cacheFallback` or
  /// `usingCacheFallback` is `true`; [cleanupAvailable] when
  /// `cleanupAvailable` is `true`; [counters] is the map under `counters`.
  factory MemoryDebuggerSnapshot.fromStats(Map<String, dynamic> stats) {
    final systemStats = switch (stats['systemMemory']) {
      final Map<dynamic, dynamic> nested => <String, dynamic>{
        for (final MapEntry(:key, :value) in nested.entries)
          if (key != null) key.toString(): value,
      },
      _ => const <String, dynamic>{},
    };
    final sources = [stats, systemStats];

    return MemoryDebuggerSnapshot(
      componentCount: _readPositive(sources, const ['componentCount']),
      entityCount: _readPositive(sources, const [
        'entityCount',
        'activeEntities',
      ]),
      usingCacheFallback:
          stats['cacheFallback'] == true || stats['usingCacheFallback'] == true,
      counters: readStatIntMap(stats['counters']),
      totalPhysicalMemoryBytes: _readPositive(sources, const [
        'totalPhysicalMemoryBytes',
      ]),
      freePhysicalMemoryBytes: _readPositive(sources, const [
        'freePhysicalMemoryBytes',
      ]),
      rssBytes: _readPositive(sources, const ['rssBytes', 'currentRssBytes']),
      cleanupAvailable: stats['cleanupAvailable'] == true,
      capturedAt: DateTime.now(),
    );
  }

  /// How many components the entities carry.
  final int componentCount;

  /// How many entities are active.
  final int entityCount;

  /// Whether the runtime's cache has fallen back to memory.
  final bool usingCacheFallback;

  /// Named counts the runtime publishes (for example `pools`, `arenas`).
  final Map<String, int> counters;

  /// The machine's physical memory, in bytes; 0 when unknown.
  final int totalPhysicalMemoryBytes;

  /// The machine's free physical memory, in bytes; 0 when unknown.
  final int freePhysicalMemoryBytes;

  /// The app's resident set size, in bytes; 0 when unknown.
  final int rssBytes;

  /// Whether a memory cleanup action can be run.
  final bool cleanupAvailable;

  /// When the snapshot was taken; null when it was made by hand.
  final DateTime? capturedAt;

  /// Whether the machine's memory is known ([totalPhysicalMemoryBytes] > 0).
  bool get hasSystemMemoryStats => totalPhysicalMemoryBytes > 0;

  /// The machine's physical memory in use, in bytes; never negative.
  int get usedPhysicalMemoryBytes {
    final used = totalPhysicalMemoryBytes - freePhysicalMemoryBytes;
    if (used < 0) {
      return 0;
    }
    return used;
  }

  /// The free share of the machine's physical memory, 0 to 1; 0 when it is
  /// unknown.
  double get availabilityRatio {
    if (!hasSystemMemoryStats) {
      return 0.0;
    }
    return freePhysicalMemoryBytes / totalPhysicalMemoryBytes;
  }

  static int _readPositive(
    Iterable<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final value = readStatInt(source, keys);
      if (value > 0) {
        return value;
      }
    }
    return 0;
  }
}
