import 'package:flutter/foundation.dart';

/// The first of [keys] in [stats] that holds a finite number, as an `int`;
/// 0 when none does.
///
/// A non-finite value (an `fps` of `Infinity` from a zero frame time, say)
/// reads as missing, so the next key is tried; `double.toInt` would throw.
@internal
int readStatInt(Map<String, dynamic> stats, List<String> keys) {
  for (final key in keys) {
    final value = stats[key];
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite) {
      return value.toInt();
    }
  }
  return 0;
}

/// The first of [keys] in [stats] that holds a finite number, as a
/// `double`; 0 when none does.
@internal
double readStatDouble(Map<String, dynamic> stats, List<String> keys) {
  for (final key in keys) {
    final value = stats[key];
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
  }
  return 0;
}

/// [source] as an unmodifiable map of names to finite `double`s.
///
/// Anything but a map reads as empty; entries with a null key or a value
/// that is not a finite number are left out.
@internal
Map<String, double> readStatDoubleMap(Object? source) {
  if (source is! Map) {
    return const <String, double>{};
  }
  final output = <String, double>{};
  source.forEach((key, value) {
    if (key != null && value is num && value.isFinite) {
      output[key.toString()] = value.toDouble();
    }
  });
  return Map.unmodifiable(output);
}

/// [source] as an unmodifiable map of names to `int`s.
///
/// Anything but a map reads as empty; entries with a null key or a value
/// that is not a finite number are left out.
@internal
Map<String, int> readStatIntMap(Object? source) {
  if (source is! Map) {
    return const <String, int>{};
  }
  final output = <String, int>{};
  source.forEach((key, value) {
    if (key != null && value is num && value.isFinite) {
      output[key.toString()] = value.toInt();
    }
  });
  return Map.unmodifiable(output);
}
