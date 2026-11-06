import 'package:flutter/foundation.dart';

/// How serious a [DebuggerLogEntry] is.
enum DebuggerLogLevel {
  /// Something happened.
  info,

  /// Something may be wrong.
  warning,

  /// Something failed.
  error,
}

/// One message in the debugger's log.
@immutable
class DebuggerLogEntry {
  /// An entry with the given [message], [category] and [level].
  const DebuggerLogEntry({
    required this.message,
    required this.category,
    this.level = DebuggerLogLevel.info,
    this.timestamp,
  });

  /// What happened.
  final String message;

  /// What it is about (`runtime`, `memory`, `physics`…), shown in capitals.
  final String category;

  /// How serious it is.
  final DebuggerLogLevel level;

  /// When it was logged; null when unknown.
  final DateTime? timestamp;

  /// [timestamp] as `HH:MM:SS`, or `--:--:--` when it is unknown.
  String get timeLabel {
    final time = timestamp;
    if (time == null) {
      return '--:--:--';
    }
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
