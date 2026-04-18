import 'package:flutter/foundation.dart';

enum DebuggerLogLevel { info, warning, error }

@immutable
class DebuggerLogEntry {
  const DebuggerLogEntry({
    required this.message,
    required this.category,
    this.level = DebuggerLogLevel.info,
    this.timestamp,
  });

  final String message;
  final String category;
  final DebuggerLogLevel level;
  final DateTime? timestamp;

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
