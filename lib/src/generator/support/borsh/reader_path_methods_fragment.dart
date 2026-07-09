import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_method_helpers.dart';

/// Emits logical path and nesting methods for the generated Borsh reader.
final class BorshReaderPathMethodsFragment extends SectionEmitter {
  /// Creates path method helpers for [context].
  const BorshReaderPathMethodsFragment(super.context);

  /// This helper contributes methods to `BorshReader`, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits logical path and nesting helper methods.
  List<Method> methods(String error) => [
    _scopedPathMethod('field', 'String name', r'$previous.$name'),
    _scopedPathMethod('index', 'int index', r'$previous[$index]'),
    _nestedMethod(error),
  ];

  Method _scopedPathMethod(String name, String firstParameter, String path) {
    final parts = firstParameter.split(' ');
    final helpers = const BorshReaderMethodHelpers();
    return Method(
      (builder) => builder
        ..name = name
        ..types.add(refer('T'))
        ..returns = refer('T')
        ..docs.add(
          name == 'field'
              ? '/// Executes [callback] with [name] appended to the logical field path.'
              : '/// Executes [callback] with [index] appended to the logical collection path.',
        )
        ..requiredParameters.addAll([
          helpers.parameter(parts.last, parts.first),
          helpers.parameter('callback', 'T Function()'),
        ])
        ..body = Code('''
final previous = _path;
_path = '$path';
try {
  return callback();
} finally {
  _path = previous;
}'''),
    );
  }

  Method _nestedMethod(String error) {
    final helpers = const BorshReaderMethodHelpers();
    return Method(
      (builder) => builder
        ..name = 'nested'
        ..types.add(refer('T'))
        ..returns = refer('T')
        ..docs.add(
          '/// Executes a nested decode while enforcing maxNestingDepth.',
        )
        ..requiredParameters.add(helpers.parameter('callback', 'T Function()'))
        ..optionalParameters.add(helpers.pathParameter())
        ..body = Code('''
_depth++;
if (_depth > limits.maxNestingDepth) {
  _depth--;
  throw $error(
    code: 'BORSH_NESTING_LIMIT',
    message: 'Value exceeds maxNestingDepth.',
    offset: _offset,
    path: path ?? _path,
  );
}
try {
  return callback();
} finally {
  _depth--;
}'''),
    );
  }
}
