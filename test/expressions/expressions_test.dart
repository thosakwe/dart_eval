import 'package:test/test.dart';
import 'assignment.dart' as assignment;
import 'await.dart' as await;

main() {
  group('assignment', assignment.main,
      skip: 'Assignments not yet implemented.');
  group('await', await.main);
}
