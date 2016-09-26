import 'package:analyzer/analyzer.dart';

class DartInterpreter extends SimpleAstVisitor {
  @override
  visitCompilationUnit(CompilationUnit ctx, [List args]) {
    FunctionDeclaration mainMethod;

    for (var declaration in ctx.declarations) {
      if (declaration is FunctionDeclaration) {
        if (declaration.name.name == "main")
          mainMethod = declaration;
      }
    }

    if (mainMethod == null)
      throw new NoSuchMethodError('top-level', #main, args, {});

    return visitFunctionExpression(mainMethod.functionExpression);
  }
}
