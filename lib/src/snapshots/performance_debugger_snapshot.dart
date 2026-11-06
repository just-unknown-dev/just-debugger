import 'package:flutter/foundation.dart';

import 'stat_reading.dart';

/// How the game loop was doing at one moment: frame rate, frame number and
/// what the last update cost against its budget.
@immutable
class PerformanceDebuggerSnapshot {
  /// A snapshot with the given values; everything left out is zero, empty
  /// or false.
  const PerformanceDebuggerSnapshot({
    this.currentFps = 0,
    this.frameNumber = 0,
    this.lastUpdateMs = 0,
    this.budgetRemainingMs = 0,
    this.isOverBudget = false,
    this.systemTimesMs = const <String, double>{},
    this.capturedAt,
  });

  /// A snapshot read from [stats], taken now.
  ///
  /// Each value reads the first of its keys that holds a finite number, and
  /// is 0 when none does:
  ///
  /// | Field | Keys |
  /// |---|---|
  /// | [currentFps] | `currentFPS`, `fps` |
  /// | [frameNumber] | `frame`, `frameNumber` |
  /// | [lastUpdateMs] | `lastUpdateMs`, `updateMs` |
  /// | [budgetRemainingMs] | `budgetRemainingMs` |
  ///
  /// [isOverBudget] is true only when `isOverBudget` is `true`;
  /// [systemTimesMs] is the map under `systemTimesMs`, or empty.
  factory PerformanceDebuggerSnapshot.fromStats(Map<String, dynamic> stats) {
    return PerformanceDebuggerSnapshot(
      currentFps: readStatInt(stats, const ['currentFPS', 'fps']),
      frameNumber: readStatInt(stats, const ['frame', 'frameNumber']),
      lastUpdateMs: readStatDouble(stats, const ['lastUpdateMs', 'updateMs']),
      budgetRemainingMs: readStatDouble(stats, const ['budgetRemainingMs']),
      isOverBudget: stats['isOverBudget'] == true,
      systemTimesMs: readStatDoubleMap(stats['systemTimesMs']),
      capturedAt: DateTime.now(),
    );
  }

  /// Frames per second.
  final int currentFps;

  /// The number of the last frame.
  final int frameNumber;

  /// What the last update took, in milliseconds.
  final double lastUpdateMs;

  /// What was left of the frame budget after the last update, in
  /// milliseconds.
  final double budgetRemainingMs;

  /// Whether the last update went over the frame budget.
  final bool isOverBudget;

  /// What each system took on the last update, in milliseconds, by name.
  final Map<String, double> systemTimesMs;

  /// When the snapshot was taken; null when it was made by hand.
  final DateTime? capturedAt;
}
