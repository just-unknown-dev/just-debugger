import 'package:flutter_test/flutter_test.dart';
import 'package:just_debugger/src/snapshots/stat_reading.dart';

void main() {
  group('readStatInt', () {
    test('reads the first key that holds a number', () {
      expect(readStatInt({'b': 2, 'a': 1}, const ['a', 'b']), 1);
      expect(readStatInt({'b': 2.9}, const ['a', 'b']), 2);
      expect(readStatInt({'a': 'seven'}, const ['a']), 0);
      expect(readStatInt(const {}, const ['a']), 0);
    });

    test('skips non-finite values instead of throwing', () {
      expect(readStatInt({'a': double.infinity, 'b': 3}, const ['a', 'b']), 3);
      expect(readStatInt({'a': double.nan}, const ['a']), 0);
    });
  });

  group('readStatDouble', () {
    test('reads the first finite number', () {
      expect(readStatDouble({'a': 2}, const ['a']), 2.0);
      expect(
        readStatDouble(
          {'a': double.negativeInfinity, 'b': 1.5},
          const ['a', 'b'],
        ),
        1.5,
      );
      expect(readStatDouble({'a': null}, const ['a']), 0);
    });
  });

  group('stat maps', () {
    test('keep finite numbers under non-null keys', () {
      expect(readStatDoubleMap({'render': 2, null: 1, 'bad': double.nan}), {
        'render': 2.0,
      });
      expect(readStatIntMap({'pools': 2.0, 'arenas': 'x', 7: 1}), {
        'pools': 2,
        '7': 1,
      });
    });

    test('read anything but a map as empty', () {
      expect(readStatDoubleMap(null), isEmpty);
      expect(readStatDoubleMap(const [1, 2]), isEmpty);
      expect(readStatIntMap('counters'), isEmpty);
    });

    test('are unmodifiable', () {
      expect(
        () => readStatDoubleMap({'a': 1})['b'] = 2,
        throwsUnsupportedError,
      );
      expect(() => readStatIntMap({'a': 1})['b'] = 2, throwsUnsupportedError);
    });
  });
}
