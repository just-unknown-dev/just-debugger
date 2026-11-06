import 'package:flutter/foundation.dart';

/// The app memory the widgets measure the footprint against when the
/// machine's RAM is unknown: 512 MiB.
@internal
const int memorySoftBudgetBytes = 512 * 1024 * 1024;

/// [bytes] in the largest unit that keeps it at 1 or more: `0 B`, `512 B`,
/// `1.5 KB` … `2.0 TB`.
@internal
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final precision = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}
