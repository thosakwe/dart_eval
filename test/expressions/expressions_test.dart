import 'package:test/test.dart';
import 'assignment.dart' as assignment;
import 'await.dart' as await;
import 'binary.dart' as binary;
import 'literal.dart' as literal;
import 'is.dart' as isExpr;
import '../common.dart';

main() {
  group('assignment', assignment.main,
      skip: 'Assignments not yet implemented.');
  group('await', await.main);
  group('binary', binary.main);
  group('literal', literal.main);
  group('is', isExpr.main, skip: 'is expressions not yet implemented.');

  test('as', () => evalEquals('main() => 2 as int;', 2));
}
