library eval;

import 'dart:async';
import 'package:analyzer/analyzer.dart';
import 'src/interpreter.dart';
export 'src/interpreter.dart';

Future eval(String source, {List args: const [], bool debug: false}) {
  final ast = parseCompilationUnit(source);
  final interpreter = new DartInterpreter(debug: debug);
  return interpreter.visitCompilationUnit(ast, args);
}
