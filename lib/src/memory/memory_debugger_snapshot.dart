import 'package:flutter/foundation.dart';

@immutable
class MemoryDebuggerSnapshot {
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

  factory MemoryDebuggerSnapshot.fromStats(Map<String, dynamic> stats) {
    final systemStats = switch (stats['systemMemory']) {
      final Map<dynamic, dynamic> value => Map<String, dynamic>.from(value),
      _ => const <String, dynamic>{},
    };

    return MemoryDebuggerSnapshot(
      componentCount: _readIntFromSources(
        [stats, systemStats],
        const ['componentCount'],
      ),
      entityCount: _readIntFromSources(
        [stats, systemStats],
        const ['entityCount', 'activeEntities'],
      ),
      usingCacheFallback:
          stats['cacheFallback'] == true || stats['usingCacheFallback'] == true,
      counters: _readIntMap(stats['counters'] as Map?),
      totalPhysicalMemoryBytes: _readIntFromSources(
        [stats, systemStats],
        const ['totalPhysicalMemoryBytes'],
      ),
      freePhysicalMemoryBytes: _readIntFromSources(
        [stats, systemStats],
        const ['freePhysicalMemoryBytes'],
      ),
      rssBytes: _readIntFromSources(
        [stats, systemStats],
        const ['rssBytes', 'currentRssBytes'],
      ),
      cleanupAvailable: stats['cleanupAvailable'] == true,
      capturedAt: DateTime.now(),
    );
  }

  final int componentCount;
  final int entityCount;
  final bool usingCacheFallback;
  final Map<String, int> counters;
  final int totalPhysicalMemoryBytes;
  final int freePhysicalMemoryBytes;
  final int rssBytes;
  final bool cleanupAvailable;
  final DateTime? capturedAt;

  bool get hasSystemMemoryStats => totalPhysicalMemoryBytes > 0;

  int get usedPhysicalMemoryBytes {
    final used = totalPhysicalMemoryBytes - freePhysicalMemoryBytes;
    if (used < 0) {
      return 0;
    }
    return used;
  }

  double get availabilityRatio {
    if (!hasSystemMemoryStats) {
      return 0.0;
    }
    return freePhysicalMemoryBytes / totalPhysicalMemoryBytes;
  }

  static int _readIntFromSources(
    Iterable<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      final value = _readInt(source, keys);
      if (value > 0) {
        return value;
      }
    }
    return 0;
  }

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

  static Map<String, int> _readIntMap(Map? source) {
    if (source == null) {
      return const <String, int>{};
    }

    final output = <String, int>{};
    source.forEach((key, value) {
      if (key == null || value == null) {
        return;
      }
      if (value is num) {
        output[key.toString()] = value.toInt();
      }
    });
    return Map.unmodifiable(output);
  }
}
