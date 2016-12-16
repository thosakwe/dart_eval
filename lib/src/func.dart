import 'package:analyzer/analyzer.dart';
import 'common.dart';
import 'symbol_table.dart';

class Func {
  final FunctionExpression ctx;
  final DartFunction exec;
  final bool debug;
  final SymbolTable symbolTable;

  Func(this.ctx, this.exec, this.symbolTable, {this.debug: false});

  call(List positional, [Map<Symbol, dynamic> named]) {
    printDebug('This is a Func instance');

    injectArgs(positional, named ?? {});
    return exec(positional, named ?? {});
  }

  void injectArgs(List positional, Map<Symbol, dynamic> named) {
    symbolTable.enter();

    printDebug(
        'This ${ctx.runtimeType} (${ctx.toSource()} has ${ctx.parameters.parameters.length} parameter(s).');

    // Inject positional
    for (var i = 0; i < ctx.parameters.parameters.length; i++) {
      final elem = ctx.parameters.parameters[i];

      if (elem is NormalFormalParameter) {
        if (elem.kind == ParameterKind.REQUIRED ||
            elem.kind == ParameterKind.POSITIONAL) {
          final key = new Symbol(elem.identifier.name);
          final val = positional[i];

          if (debug) print('Injecting $key = $val into this Func');

          symbolTable[key] = val;
        }
      } else {
        printDebug('This parameter (${elem.toSource()}) is a ${elem
            .runtimeType}, not a normal formal parameter.');
      }
    }
  }

  void printDebug(Object object) {
    if (debug) print(object);
  }
}
