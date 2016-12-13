import 'package:eval/eval.dart';
import 'package:test/test.dart';

main() {
  test('declaration', () async {
    final two = await eval('''
    main() {
      final two = 2;
      return two;
    }
    ''');
    expect(two, equals(2));
  });

  test('expression', () async {
    final two = await eval('''
    main() {
      int two = 3;
      return two -= 1;
    }
    ''');
    expect(two, equals(2));
  });

  test('re-assign', () async {
    final two = await eval('''
    main() {
      int two = 3;
      two = 2;
      return two;
    }
    ''');
    expect(two, equals(2));
  });

  test('with operator', () async {
    final two = await eval('''
    main() {
      int two = 3;
      two -= 1;
      return two;
    }
    ''');
    expect(two, equals(2));
  });
}
