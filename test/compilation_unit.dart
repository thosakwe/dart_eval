import 'package:analyzer/analyzer.dart';
import 'package:eval/eval.dart';
import 'package:test/test.dart';

main() {
  var interpreter = new DartInterpreter();
  test('hello world', () {
    var compilationUnit = parseCompilationUnit('''
    main() {
      print('Hello, world!');
    }
    ''');

    interpreter.visitCompilationUnit(compilationUnit);
  });
}