import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_method_helpers.dart';

/// Emits string and collection read methods for the generated Borsh reader.
final class BorshReaderCollectionMethodsFragment extends SectionEmitter {
  /// Creates collection method helpers for [context].
  const BorshReaderCollectionMethodsFragment(super.context);

  /// This helper contributes methods to `BorshReader`, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits string and collection read methods.
  List<Method> methods(String error) {
    const helpers = BorshReaderMethodHelpers();
    return [
      helpers.method(
        'readString',
        'String',
        'Reads a strict UTF-8 Borsh string.',
        const [],
        helpers.pathParameter(),
        Code('''
final logicalPath = path ?? _path;
final length = readInt(4, path: path);
if (length > limits.maxStringBytes) {
  throw $error(
    code: 'BORSH_STRING_LIMIT',
    message: 'String exceeds maxStringBytes.',
    offset: _offset - 4,
    path: logicalPath,
  );
}
try {
  return utf8.decode(readBytes(length, path: path), allowMalformed: false);
} on FormatException catch (error) {
  throw $error(
    code: 'BORSH_INVALID_UTF8',
    message: 'String is not valid UTF-8.',
    offset: _offset - length,
    path: logicalPath,
    cause: error.message,
  );
}'''),
      ),
      Method(
        (builder) => builder
          ..name = 'collectionLength'
          ..returns = refer('int')
          ..docs.add('/// Validates a collection length before allocation.')
          ..optionalParameters.add(helpers.pathParameter())
          ..body = const Code('''
final length = readInt(4, path: path);
return fixedLength(length, path: path);'''),
      ),
      helpers.method(
        'fixedLength',
        'int',
        'Validates a fixed or already-decoded collection length.',
        [helpers.parameter('length', 'int')],
        helpers.pathParameter(),
        Code('''
if (length < 0 ||
    length > limits.maxCollectionLength ||
    _totalElements + length > limits.maxTotalElements) {
  throw $error(
    code: 'BORSH_COLLECTION_LIMIT',
    message: 'Collection exceeds configured decode limits.',
    offset: _offset,
    path: path ?? _path,
  );
}
_totalElements += length;
return length;'''),
      ),
    ];
  }
}
