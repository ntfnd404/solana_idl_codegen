import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';
import 'reader_method_helpers.dart';

/// Emits primitive read methods for the generated Borsh reader.
final class BorshReaderPrimitiveMethodsFragment extends SectionEmitter {
  /// Creates primitive method helpers for [context].
  const BorshReaderPrimitiveMethodsFragment(super.context);

  /// This helper contributes methods to `BorshReader`, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits primitive read methods.
  List<Method> methods(String error) {
    const helpers = BorshReaderMethodHelpers();
    return [
      helpers.method(
        'readBytes',
        'Uint8List',
        'Reads exactly [length] bytes.',
        [helpers.parameter('length', 'int')],
        helpers.pathParameter(),
        Code('''
final logicalPath = path ?? _path;
if (length < 0 || length > remaining) {
  throw $error(
    code: 'BORSH_UNEXPECTED_EOF',
    message: 'Not enough bytes.',
    offset: _offset,
    path: logicalPath,
    expected: '\$length bytes',
    actual: '\$remaining bytes',
  );
}
final result = Uint8List.fromList(
  _bytes.sublist(_offset, _offset + length),
);
_offset += length;
return result.asUnmodifiableView();'''),
      ),
      helpers.method(
        'readUnsigned',
        'BigInt',
        'Reads an unsigned little-endian integer.',
        [helpers.parameter('byteLength', 'int')],
        helpers.pathParameter(),
        const Code('''
final value = readBytes(byteLength, path: path);
var result = BigInt.zero;
for (var index = value.length - 1; index >= 0; index--) {
  result = (result << 8) | BigInt.from(value[index]);
}
return result;'''),
      ),
      helpers.method(
        'readSigned',
        'BigInt',
        "Reads a signed two's-complement little-endian integer.",
        [helpers.parameter('byteLength', 'int')],
        helpers.pathParameter(),
        const Code('''
final unsigned = readUnsigned(byteLength, path: path);
final bits = byteLength * 8;
final sign = BigInt.one << (bits - 1);
return (unsigned & sign) == BigInt.zero
    ? unsigned
    : unsigned - (BigInt.one << bits);'''),
      ),
      Method(
        (builder) => builder
          ..name = 'readInt'
          ..returns = refer('int')
          ..docs.add(
            '/// Reads an unsigned integer that must fit a Dart [int].',
          )
          ..requiredParameters.add(helpers.parameter('byteLength', 'int'))
          ..optionalParameters.add(helpers.pathParameter())
          ..lambda = true
          ..body = const Code('readUnsigned(byteLength, path: path).toInt()'),
      ),
      helpers.method(
        'readBool',
        'bool',
        'Reads a strict Borsh boolean.',
        const [],
        helpers.pathParameter(),
        _tagBody(error, option: false),
      ),
      helpers.method(
        'readOptionTag',
        'bool',
        'Reads a strict Option or COption tag.',
        [helpers.parameter('byteLength', 'int')],
        helpers.pathParameter(),
        _tagBody(error, option: true),
      ),
      helpers.method(
        'readFloat',
        'double',
        'Reads an IEEE-754 floating-point value.',
        [helpers.parameter('byteLength', 'int')],
        helpers.pathParameter(),
        Code('''
final logicalPath = path ?? _path;
final bytes = readBytes(byteLength, path: path);
final data = ByteData.sublistView(bytes);
final value = byteLength == 4
    ? data.getFloat32(0, Endian.little)
    : data.getFloat64(0, Endian.little);
if (value.isNaN) {
  throw $error(
    code: 'BORSH_NAN',
    message: 'NaN is not a canonical Borsh value.',
    offset: _offset - byteLength,
    path: logicalPath,
  );
}
return value;'''),
      ),
    ];
  }

  Code _tagBody(String error, {required bool option}) {
    final byteLength = option ? 'byteLength' : '1';
    final code = option ? 'BORSH_INVALID_OPTION' : 'BORSH_INVALID_BOOL';
    final label = option ? 'Option' : 'Boolean';
    final offset = option ? '_offset - byteLength' : '_offset - 1';
    return Code('''
final logicalPath = path ?? _path;
final tag = readInt($byteLength, path: path);
return switch (tag) {
  0 => false,
  1 => true,
  _ => throw $error(
    code: '$code',
    message: '$label tag must be 0 or 1.',
    offset: $offset,
    path: logicalPath,
    expected: '0 or 1',
    actual: '\$tag',
  ),
};''');
  }
}
