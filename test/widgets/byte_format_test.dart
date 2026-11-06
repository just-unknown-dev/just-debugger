import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/src/widgets/byte_format.dart';

void main() {
  test('formatBytes picks the largest unit at 1 or more', () {
    expect(formatBytes(-5), '0 B');
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    expect(formatBytes(2048 * 1024 * 1024 * 1024 * 1024), '2048.0 TB');
  });

  test('the soft budget is 512 MiB', () {
    expect(formatBytes(memorySoftBudgetBytes), '512.0 MB');
  });
}
