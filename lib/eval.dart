library eval;

import 'dart:async';
import 'dart:io';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'src/interpreter.dart';
export 'src/interpreter.dart';

/// Interprets the provided Dart code.
///
/// The provided source must contain a `main` function.
Future eval(String source,
    {List args: const [], bool debug: false, String packageRoot}) {
  final ast = parseCompilationUnit(source);
  final interpreter = new DartInterpreter(debug: debug);
  return interpreter.visitCompilationUnit(ast, args);
}

CompilationUnit getAnalyzedCompilationUnit(String text, String packageRoot) {
  // Todo: Analyze beforehand
  return null;
  final ast = parseCompilationUnit(text);
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  DartSdk sdk = new FolderBasedDartSdk(resourceProvider,
      resourceProvider.getFolder(Directory.current.absolute.path));

  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(resourceProvider)
  ];

  if (packageRoot != null) {
    ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
    resolvers.add(new PackageMapUriResolver(resourceProvider,
        builder.convertPackagesToMap(builder.createPackageMap(packageRoot))));
  }

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);

  Source source = new _StringSource(text);
  ChangeSet changeSet = new ChangeSet()..addedSource(source);
  context.applyChanges(changeSet);
  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}
