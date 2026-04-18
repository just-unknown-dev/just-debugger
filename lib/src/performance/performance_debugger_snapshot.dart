import 'package:flutter/foundation.dart';

@immutable
class PerformanceDebuggerSnapshot {
  const PerformanceDebuggerSnapshot({
    this.currentFps = 0,
    this.frameNumber = 0,
    this.lastUpdateMs = 0,
    this.budgetRemainingMs = 0,
    this.isOverBudget = false,
    this.systemTimesMs = const <String, double>{},
    this.capturedAt,
  });

  factory PerformanceDebuggerSnapshot.fromStats(Map<String, dynamic> stats) {
    return PerformanceDebuggerSnapshot(
      currentFps: _readInt(stats, const ['currentFPS', 'fps']),
      frameNumber: _readInt(stats, const ['frame', 'frameNumber']),
      lastUpdateMs: _readDouble(stats, const ['lastUpdateMs', 'updateMs']),
      budgetRemainingMs: _readDouble(stats, const ['budgetRemainingMs']),
      isOverBudget: stats['isOverBudget'] == true,
      systemTimesMs: _readDoubleMap(stats['systemTimesMs'] as Map?),
      capturedAt: DateTime.now(),
    );
  }

  final int currentFps;
  final int frameNumber;
  final double lastUpdateMs;
  final double budgetRemainingMs;
  final bool isOverBudget;
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

  static double _readDouble(Map<String, dynamic> stats, List<String> keys) {
    for (final key in keys) {
      final value = stats[key];
      if (value is num) {
        return value.toDouble();
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
}
