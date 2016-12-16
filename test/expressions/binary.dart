import '../common.dart';
import 'package:test/test.dart';

main() {
  test('arithmetic', () async {
    await evalEquals('main(a) => a * 3;', 6, args: [2]);
    await evalEquals('main() => 6 / 3;', 2);
    await evalEquals('main() => (2 + 3);', 5);
    await evalEquals('main() => 2 - 3;', -1);
  });

  test('bitwise', () async {
    await evalEquals('main() => 1 | 2;', 1 | 2);
    await evalEquals('main() => 1 & 2;', 1 & 2);
    await evalEquals('main() => 1 << 2;', 1 << 2);
    await evalEquals('main() => 1 >> 2;', 1 >> 2);
  });

  test('boolean', () async {
    await evalEquals('main() => 1 == 2;', 1 == 2);
    await evalEquals('main() => 1 != 2;', 1 != 2);
    await evalEquals('main() => true || false;', true);
    await evalEquals('main() => true && false;', false);
    await evalEquals('main() => 1 < 2;', true);
    await evalEquals('main() => 1 <= 2;', true);
    await evalEquals('main() => 1 <= 1;', true);
    await evalEquals('main() => 1 > 2;', false);
    await evalEquals('main() => 1 >= 2;', false);
    await evalEquals('main() => 2 >= 2;', true);
  });
}
