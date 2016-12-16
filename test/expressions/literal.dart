import 'package:test/test.dart';
import '../common.dart';

main() {
  test('boolean', () async {
    await evalEquals('main() => true;', true);
    await evalEquals('main() => false;', false);
  });

  test('list', () async {
    await evalEquals('main() => [];', []);
    await evalEquals('main() => [1, -2, 3.0];', [1, -2, 3]);
    await evalEquals('main(a) => [a, "bar"];', ['foo', 'bar'], args: ['foo']);
  });

  test('map', () async {
    await evalEquals('main() => {};', {});
    await evalEquals('main() => {"foo": "bar"};', {'foo': 'bar'});
    await evalEquals('main() => {"one": 1, "two": "2", "three": -3.0};',
        {'one': 1, 'two': '2', 'three': -3});
    await evalEquals('main(c) => {"a": {"b": c}, "d": "e"};', {
      "a": {"b": 'C'},
      "d": "e"
    }, args: [
      'C'
    ]);
  });

  test('null', () => evalEquals('main() => null;', null));

  test('number', () async {
    await evalEquals('main() => 1;', 1);
    await evalEquals('main() => 1.4;', 1.4);
    await evalEquals('main() => -143.2;', -143.2, debug: true);
    await evalEquals('main() => -45;', -45);
  });

  test('string', () async {
    await evalEquals('main() => "Hello";', "Hello");
    await evalEquals(r'main() => "${7} nation army";', "7 nation army");
    await evalEquals(
        '''
    main() {
      var breezy = 'Barack', obeezy = 'Obama';
      return '\$breezy \$obeezy';
    }
    ''',
        'Barack Obama');
  });

  test('symbol', () => evalEquals('main() => #foo;', #foo));
}
