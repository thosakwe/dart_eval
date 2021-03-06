# dart_eval

[![version v1.0.0-dev](https://img.shields.io/badge/pub-v1.0.0--dev-red.svg)](https://pub.dartlang.org/packages/eval)
[![build status](https://travis-ci.org/thosakwe/dart_eval.svg)](https://travis-ci.org/thosakwe/dart_eval)

Dart interpreter written in Dart. Highly experimental. It is very unlikely that this will ever be *complete*.
`eval` was mainly created to make things like template engines possible via Dart.

# Installation
If you use [scripts](https://github.com/thosakwe/dart_scripts), then it's as simple as the following:

```bash
$ scripts install eval
```

Otherwise:

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
    eval: ^1.0.0-dev
```

Then, run:

```bash
$ pub get
```

# Usage
`eval` runs Dart compilation units. You can optionally pass arguments. With `eval`, you can pass any
Dart object to the `main` function, instead of just primitives. This can eliminate the need for
`SendPort` use sometimes.

```dart
main() async {
    final len = await eval('''
    main(List<String> args) {
      return args.length;
    }
    ''', ['foo', 'bar', 'baz']);
    
    expect(len, equals(3));
}
```

# Coverage
*Some functions may have implementation present, but nothing will be marked
until it has thorough tests available.*

* [ ] Directives
  * [ ] `import`
    * [ ] deferred
  * [ ] `export`
  * [ ] `part`
* [ ] Expressions
  * [x] `as`
  * [ ] Assignment
  * [x] Await
  * [x] Binary
    * [x] Arithmetic (*, /, +, -)
    * [x] Bitwise (|, &, <<, >>)
    * [x] Boolean (==, !=, ||, &&, <, <=, >, >=)
  * [ ] Function (needs tests)
  * [ ] Is (`is`, `is!`)
  * [x] Literal
    * [x] Boolean
    * [x] List
    * [x] Map
    * [x] Null
    * [x] Number
    * [x] String
      * [x] Interpolation
    * [x] Symbol
  * [ ] Method Invocation (needs tests)
  * [ ] `new`
  * [ ] Unary
    * [ ] Postfix
    * [ ] Prefix
* [ ] Properties
  * [ ] Getting
  * [ ] Setting
* [ ] Statements
  * [ ] Blocks
    * [ ] If/Else
    * [ ] Switch
    * [ ] Try/Catch
  * [ ] `break`
  * [ ] `continue`
  * [ ] Loops
    * [ ] Do-while
    * [ ] For
    * [ ] Foreach
    * [ ] While
  * [ ] `rethrow`
  * [x] `return`
  * [ ] `throw`
* [ ] Top-level (needs tests)
  * [ ] Functions (needs tests)
    * [ ] Embedded
  * [ ] Variables (needs tests)
* [ ] Variables
  * [ ] Declaring
  * [ ] Assigning