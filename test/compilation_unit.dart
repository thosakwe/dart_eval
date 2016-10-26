import 'dart:isolate';
import 'package:analyzer/analyzer.dart';
import 'package:eval/eval.dart';
import 'package:test/test.dart';

main() {
  var interpreter = new DartInterpreter(debug: true);

  group('expressions', () {
    group('assignments', () {
      test('basic', () async {
        await eval('''
        main() {
          var foo = "bar";
          print("foo was set to \$foo.");
        }
        ''');
      });
    });

    group('list of', () {
      test('ints', () async {
        final expr = new ListLiteral(
            null,
            null,
            null,
            [
              new IntegerLiteral(null, 1),
              new IntegerLiteral(null, 2),
              new IntegerLiteral(null, 3)
            ],
            null);

        final list = await interpreter.resolveExpression(expr);
        expect(list, equals([1, 2, 3]));
      });
    });
  });

  test('hello world', () async {
    final message = "Hello from eval world!";

    await eval(
        '''
    main() {
      print('$message');
    }
    ''',
        args: [2, 4],
        debug: true);
  });

  group('strings', () {
    test('interp', () async {
      final message = "Interp within eval?";
      final recv = new ReceivePort();
      await eval(
          '''
      final message = "$message";

      main(SendPort port) {
        port.send(message);
      }
      ''',
          args: [recv.sendPort],
          debug: true);
      final str = await recv.first;
      print(str);
      expect(str, equals(message));
    });
  });
}
