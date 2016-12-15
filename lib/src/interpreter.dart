import 'dart:async';
import 'dart:mirrors';
import 'package:analyzer/analyzer.dart';
import 'func.dart';
import 'symbol_table.dart';

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
      var result = callee is Func
          ? await callee(positional, named)
          : Function.apply(callee, positional, named);
      return result is Future ? await result : result;
    }
  }

  void printDebug(Object object) {
    if (debug) print(object);
  }


  resolveExpression(Expression ctx) async {
    var result = await _resolveExpression(ctx);
    printDebug('Resolution result: $result');
    return result;
  }

  // This is very long, beware
  _resolveExpression(Expression ctx) async {
    printDebug('Resolving this ${ctx.runtimeType}');

    if (ctx is AssignmentExpression) {
      var right = await resolveExpression(ctx.rightHandSide);
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
        var split = ctx.name.split('.');
        printDebug('Split: $split');
        var resolver;

        if (split.length > 1) {
          for (int i = 0; i < split.length; i++) {
            var str = split[i];

            if (i == 0) {
              resolver = symbolTable[new Symbol(str)];
            } else {
              var r = reflect(resolver);
              resolver = r.getField(new Symbol(str));
            }
          }

          return new Future.value(resolver);
        } else {
          var sym = new Symbol(ctx.name);
          var resolved = symbolTable[sym];

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
        var list = [];

        for (var elem in ctx.elements) {
          list.add(await resolveExpression(elem));
        }

        return list;
      }

      if (ctx is MapLiteral) {
        var map = {};

        for (var entry in ctx.entries) {
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
          var buf = new StringBuffer();

          for (var elem in ctx.elements) {
            printDebug("Interpolating this: '${elem.toSource()}'");
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

    for (var stmt in ctx.statements) {
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
          var sym = new Symbol(vardecl.name.name);
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
    var body = ctx.body;

    void injectArgs(List positional, Map<Symbol, dynamic> named) {
      symbolTable.enter();

      // Inject positional
      for (var i = 0; i < ctx.parameters.parameters.length; i++) {
        var elem = ctx.parameters.parameters[i];

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
          var result = await visitBlock(body.block);
          symbolTable.exit();
          return result;
        });
      } else if (body is ExpressionFunctionBody) {
        return new Future(() async {
          injectArgs(positional, named);
          var result = await resolveExpression(body.expression);
          symbolTable.exit();
          return result;
        });
      }
    }, symbolTable, debug: debug));
  }

  visitInvocationExpression(InvocationExpression ctx) async {
    var positional = [];
    var named = {};

    for (var expr in ctx.argumentList.arguments) {
      if (expr is NamedExpression) {
        var key = new Symbol(expr.name.label.name);
        var val = await resolveExpression(expr.expression);
        printDebug('Injecting named arg $key = $val');
        named[key] = val;
      } else {
        var val = await resolveExpression(expr);
        printDebug('Injecting positional arg $val');
        positional.add(val);
      }
    }

    var callee;

    if (ctx is MethodInvocation && ctx.realTarget != null) {
      printDebug(
          'Real target: ${ctx.realTarget.toSource()} (${ctx.realTarget.runtimeType})');
      var realTarget = await resolveExpression(ctx.realTarget);
      var r = reflect(realTarget);
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
      var declaration = ctx.functionDeclaration;
      symbolTable.set(new Symbol(declaration.name.name),
          await visitFunctionExpression(declaration.functionExpression));
      return null;
    }

    if (ctx is VariableDeclarationStatement) {
      for (VariableDeclaration vardecl in ctx.variables.variables) {
        var sym = new Symbol(vardecl.name.name);
        symbolTable[sym] = vardecl.initializer == null
            ? null
            : await resolveExpression(vardecl.initializer);
      }

      return null;
    }

    if (ctx is ReturnStatement) {
      if (ctx.expression == null)
        return null;
      else return await resolveExpression(ctx.expression);
    }
  }
}


