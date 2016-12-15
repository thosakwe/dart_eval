import 'package:test/test.dart';
import '../common.dart';

main() {
  test('boolean', () async {
    await evalEquals('main() => true;', true);
    await evalEquals('main() => false;', false);
  });

  test('list', () async {});

  test('map', () async {});

  test('null', () => evalEquals('main() => null;', null));

  test('number', () async {
    await evalEquals('main() => 1;', 1);
    await evalEquals('main() => 1.4;', 1.4);
    await evalEquals('main() => -143.2;', -143.2);
    await evalEquals('main() => -45;', -45);
  });

  test('string', () async {
    await evalEquals('main() => "Hello";', "Hello");
    await evalEquals(r'main() => "${7} nation army";', "7 nation army");
    await evalEquals('''
    main() {
      var breezy = 'Barack', obeezy = 'Obama';
      return '\$breezy \$obeezy';
    }
    ''', 'Barack Obama', debug: true);
  });

  test('symbol', () => evalEquals('main() => #foo;', #foo));
}
