import 'dart:async';
import 'package:eval/eval.dart';
import 'package:test/test.dart';

main() {
  test('block body', () async {
    var func = await eval('''
    main() async {
      return (x, y) async {
        print('x: \$x');
        print('y: \$y');
        print('x * y = \${x * y}');
        return x * y;
      };
    }
    ''');
    print('func: $func');

    var fiftySix = func(7, 8);
    expect(fiftySix, new isInstanceOf<Future>());
    expect(await fiftySix, equals(56));
  });

  test('expression body', () async {
    var func = await eval('''
    main() async {
      return (x, y) async => x * y;
    }
    ''');
    print('func: $func');

    var fiftySix = func(7, 8);
    expect(fiftySix, new isInstanceOf<Future>());
    expect(await fiftySix, equals(56));
  });

  test('top-level', () async {
    var func = await eval('''
    func(x, y) async {
      print('x: \$x');
      print('y: \$y');
      print('x * y = \${x * y}');
      return x * y;
    }

    main() async {
      return func;
    }
    ''');
    print('func: $func');

    var fiftySix = func(7, 8);
    expect(fiftySix, new isInstanceOf<Future>());
    expect(await fiftySix, equals(56));
  });
}
