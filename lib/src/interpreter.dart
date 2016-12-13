import 'dart:async';
import 'dart:mirrors';
import 'package:analyzer/analyzer.dart';
import 'symbol_table.dart';

typedef Future DartFunction(List positional, Map<Symbol, dynamic> named);

class DartInterpreter extends SimpleAstVisitor<Future> {
  final bool debug;
  SymbolTable symbolTable;

  DartInterpreter({this.debug: false}) {
    symbolTable = new SymbolTable(debug: debug);

    // Todo: polyfill somehow
    symbolTable[#print] = print;
  }

  exec(AstNode ctx, callee, List positional, Map<Symbol, dynamic> named) async {
    printDebug('Executing this ${ctx.runtimeType}: ${ctx.toSource()}');

    if (callee == null) {
      throw new NoSuchMethodError(
          'top-level', new Symbol(ctx.toSource()), positional, named);
    } else {
      printDebug(
          'Calling $callee with positional $positional and named $named');
      printDebug('Invocation: ${ctx.toSource()}');
      final result = callee is Func
          ? await callee(positional, named)
          : Function.apply(callee, positional, named);
      return result is Future ? await result : result;
    }
  }

  void printDebug(Object object) {
    if (debug) print(object);
  }

  // This is very long, beware
  resolveExpression(Expression ctx) async {
    printDebug('Resolving this ${ctx.runtimeType}');

    if (ctx is AssignmentExpression) {
      final right = await resolveExpression(ctx.rightHandSide);
      printDebug(
          'Left: ${ctx.leftHandSide.toSource()} (${ctx.leftHandSide.runtimeType})');
      printDebug('Right: $right');
    }

    if (ctx is AwaitExpression)
      return await (await resolveExpression(ctx.expression));

    if (ctx is ConditionalExpression) {
      // Tern
      return ((await resolveExpression(ctx.condition))
          ? (await resolveExpression(ctx.thenExpression))
          : (await resolveExpression(ctx.elseExpression)));
    }

    if (ctx is FunctionExpression) return await visitFunctionExpression(ctx);

    if (ctx is FunctionExpressionInvocation)
      return await visitInvocationExpression(ctx);

    if (ctx is Identifier) {
      if (ctx is SimpleIdentifier) {
        final split = ctx.name.split('.');
        printDebug('Split: $split');
        var resolver;

        if (split.length > 1) {
          for (int i = 0; i < split.length; i++) {
            final str = split[i];

            if (i == 0) {
              resolver = symbolTable[new Symbol(str)];
            } else {
              final r = reflect(resolver);
              resolver = r.getField(new Symbol(str));
            }
          }

          return new Future.value(resolver);
        } else {
          final sym = new Symbol(ctx.name);
          final resolved = symbolTable[sym];

          if (resolved == null) {
            throw new NoSuchMethodError('top-level', sym, [], {});
          } else
            return new Future.value(resolved);
        }
      }
    }

    if (ctx is Literal) {
      if (ctx is BooleanLiteral) return new Future.value(ctx.value);

      if (ctx is DoubleLiteral) return new Future.value(ctx.value);

      if (ctx is IntegerLiteral) return new Future.value(ctx.value);

      if (ctx is ListLiteral) {
        final list = [];

        for (final elem in ctx.elements) {
          list.add(await resolveExpression(elem));
        }

        return list;
      }

      if (ctx is MapLiteral) {
        final map = {};

        for (final entry in ctx.entries) {
          map[await resolveExpression(entry.key)] =
              await resolveExpression(entry.value);
        }

        return new Future.value(map);
      }

      if (ctx is NullLiteral) {
        return new Future.value(null);
      }

      if (ctx is StringLiteral) {
        if (ctx is SimpleStringLiteral) {
          return new Future.value(ctx.stringValue);
        } else if (ctx is StringInterpolation) {
          final buf = new StringBuffer();

          for (final elem in ctx.elements) {
            if (elem is InterpolationString) {
              buf.write(elem.value);
            } else if (elem is InterpolationExpression) {
              buf.write(await resolveExpression(elem.expression));
            }
          }

          return new Future.value(buf.toString());
        }
      }

      if (ctx is SymbolLiteral) {
        return new Symbol(ctx.toSource().substring(1));
      }
    }

    if (ctx is MethodInvocation) return await visitInvocationExpression(ctx);

    printDebug("Couldn't resolve expression: ${ctx.runtimeType}");
    return new Future.value(null);
  }

  @override
  visitBlock(Block ctx) async {
    var result;

    for (final stmt in ctx.statements) {
      result = await visitStatement(stmt);
    }

    return result;
  }

  @override
  visitCompilationUnit(CompilationUnit ctx, [List args]) async {
    FunctionDeclaration mainMethod;

    for (var declaration in ctx.declarations) {
      if (declaration is FunctionDeclaration) {
        symbolTable.set(new Symbol(declaration.name.name),
            await visitFunctionExpression(declaration.functionExpression));
        if (declaration.name.name == 'main') mainMethod = declaration;
      } else if (declaration is TopLevelVariableDeclaration) {
        for (VariableDeclaration vardecl in declaration.variables.variables) {
          final sym = new Symbol(vardecl.name.name);
          symbolTable[sym] = vardecl.initializer == null
              ? null
              : await resolveExpression(vardecl.initializer);
        }
      }
    }

    if (mainMethod == null)
      throw new NoSuchMethodError('top-level', #main, args, {});

    if (debug) {
      print('Dumping symbols before running main(${args != null
              ? args.join(", ")
              : ""}): ');

      void dumpSymbolTable(SymbolTable table, int level) {
        print('Level ${level + 1}');

        table.symbols.forEach((sym, val) {
          print('  - $sym: $val');
        });

        if (table.child != null) {
          dumpSymbolTable(table.child, level + 1);
        }
      }

      dumpSymbolTable(symbolTable, 0);
    }

    return await exec(mainMethod, symbolTable[#main], args, {});
  }

  @override
  visitFunctionExpression(FunctionExpression ctx) {
    final body = ctx.body;

    void injectArgs(List positional, Map<Symbol, dynamic> named) {
      symbolTable.enter();

      // Inject positional
      for (var i = 0; i < ctx.parameters.parameters.length; i++) {
        final elem = ctx.parameters.parameters[i];

        if (elem == null) continue;

        if (elem is NormalFormalParameter) {
          if (elem.kind == ParameterKind.REQUIRED ||
              elem.kind == ParameterKind.POSITIONAL) {
            symbolTable[new Symbol(elem.identifier.name)] = positional[i];
          }
        } else {
          printDebug('This parameter (${elem.toSource()}) is a ${elem
              .runtimeType}, not a normal formal parameter.');
        }
      }

      // Inject named
      named.forEach(symbolTable.set);
    }

    return new Future.value(
        new Func(ctx, (List positional, Map<Symbol, dynamic> named) {
      if (body is BlockFunctionBody) {
        return new Future(() async {
          injectArgs(positional, named);
          final result = await visitBlock(body.block);
          symbolTable.exit();
          return result;
        });
      } else if (body is ExpressionFunctionBody) {
        return new Future(() async {
          injectArgs(positional, named);
          final result = await resolveExpression(body.expression);
          symbolTable.exit();
          return result;
        });
      }
    }, symbolTable, debug: debug));
  }

  visitInvocationExpression(InvocationExpression ctx) async {
    final positional = [];
    final named = {};

    for (final expr in ctx.argumentList.arguments) {
      if (expr is NamedExpression) {
        final key = new Symbol(expr.name.label.name);
        final val = await resolveExpression(expr.expression);
        printDebug('Injecting named arg $key = $val');
        named[key] = val;
      } else {
        final val = await resolveExpression(expr);
        printDebug('Injecting positional arg $val');
        positional.add(val);
      }
    }

    var callee;

    if (ctx is MethodInvocation && ctx.realTarget != null) {
      printDebug(
          'Real target: ${ctx.realTarget.toSource()} (${ctx.realTarget.runtimeType})');
      final realTarget = await resolveExpression(ctx.realTarget);
      final r = reflect(realTarget);
      callee = r.getField(new Symbol(ctx.methodName.name)).reflectee;
    } else
      callee = await resolveExpression(ctx.function);
    return await exec(ctx, callee, positional, named);
  }

  visitStatement(Statement ctx) async {
    if (ctx is Block) return await visitBlock(ctx);

    if (ctx is ExpressionStatement)
      return await resolveExpression(ctx.expression);

    if (ctx is FunctionDeclarationStatement) {
      final declaration = ctx.functionDeclaration;
      symbolTable.set(new Symbol(declaration.name.name),
          await visitFunctionExpression(declaration.functionExpression));
      return null;
    }

    if (ctx is VariableDeclarationStatement) {
      for (VariableDeclaration vardecl in ctx.variables.variables) {
        final sym = new Symbol(vardecl.name.name);
        symbolTable[sym] = vardecl.initializer == null
            ? null
            : await resolveExpression(vardecl.initializer);
      }

      return null;
    }
  }
}

class Func {
  final FunctionExpression ctx;
  final DartFunction exec;
  final bool debug;
  final SymbolTable symbolTable;

  Func(this.ctx, this.exec, this.symbolTable, {this.debug: false});

  call(List positional, Map<Symbol, dynamic> named) {
    printDebug('This is a Func instance');

    injectArgs(positional, named);
    return exec(positional, named);
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
