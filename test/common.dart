import 'package:eval/eval.dart';
import 'package:test/test.dart';

evalEquals(String text, value, {List args: const [], bool debug: false}) async {
  expect(await eval(text, args: args, debug: debug), equals(value));
}
