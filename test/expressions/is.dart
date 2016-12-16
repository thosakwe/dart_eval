import 'package:test/test.dart';
import '../common.dart';

main() {
  test('typing', () async {
    await evalEquals('main(a) => a is int;', false, args: ['a']);
    await evalEquals('main(a) => a is! int;', true, args: ['a']);
  });
}
