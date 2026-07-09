import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits the mutable, operation-scoped Borsh writer.
final class BorshWriterFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshWriterFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    Class(
      (builder) => builder
        ..name = type('borsh_writer')
        ..modifier = ClassModifier.final$
        ..docs.add('/// Mutable Borsh writer scoped to one encode operation.')
        ..fields.add(
          Field(
            (builder) => builder
              ..name = '_builder'
              ..modifier = FieldModifier.final$
              ..type = refer('BytesBuilder')
              ..assignment = const Code('BytesBuilder(copy: false)'),
          ),
        )
        ..methods.addAll([
          _method(
            'writeBytes',
            'Writes raw bytes after validating byte values.',
            [_parameter('bytes', 'List<int>')],
            const Code('''
for (final byte in bytes) {
  if (byte < 0 || byte > 255) {
    throw RangeError.range(byte, 0, 255, 'bytes');
  }
}
_builder.add(bytes);'''),
          ),
          _method(
            'writeUnsigned',
            'Writes an unsigned little-endian integer with overflow checking.',
            [_parameter('value', 'BigInt'), _parameter('byteLength', 'int')],
            const Code('''
final maximum = BigInt.one << (byteLength * 8);
if (value < BigInt.zero || value >= maximum) {
  throw ArgumentError.value(value, 'value', 'Unsigned integer overflow.');
}
var remaining = value;
for (var index = 0; index < byteLength; index++) {
  _builder.addByte((remaining & BigInt.from(255)).toInt());
  remaining >>= 8;
}'''),
          ),
          _method(
            'writeSigned',
            "Writes a signed two's-complement little-endian integer.",
            [_parameter('value', 'BigInt'), _parameter('byteLength', 'int')],
            const Code('''
final bits = byteLength * 8;
final minimum = -(BigInt.one << (bits - 1));
final maximum = (BigInt.one << (bits - 1)) - BigInt.one;
if (value < minimum || value > maximum) {
  throw ArgumentError.value(value, 'value', 'Signed integer overflow.');
}
writeUnsigned(
  value < BigInt.zero ? (BigInt.one << bits) + value : value,
  byteLength,
);'''),
          ),
          Method.returnsVoid(
            (builder) => builder
              ..name = 'writeBool'
              ..docs.add('/// Writes a strict Borsh boolean.')
              ..requiredParameters.add(_parameter('value', 'bool'))
              ..lambda = true
              ..body = const Code('_builder.addByte(value ? 1 : 0)'),
          ),
          _method(
            'writeFloat',
            'Writes an IEEE-754 floating-point value and rejects NaN.',
            [_parameter('value', 'double'), _parameter('byteLength', 'int')],
            const Code('''
if (value.isNaN) {
  throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
}
final bytes = Uint8List(byteLength);
final data = ByteData.sublistView(bytes);
if (byteLength == 4) {
  data.setFloat32(0, value, Endian.little);
} else {
  data.setFloat64(0, value, Endian.little);
}
_builder.add(bytes);'''),
          ),
          _method(
            'writeString',
            'Writes a length-prefixed UTF-8 string.',
            [_parameter('value', 'String')],
            const Code('''
final bytes = utf8.encode(value);
writeUnsigned(BigInt.from(bytes.length), 4);
writeBytes(bytes);'''),
          ),
          Method(
            (builder) => builder
              ..name = 'takeBytes'
              ..returns = refer('Uint8List')
              ..docs.add('/// Returns an immutable copy of encoded bytes.')
              ..lambda = true
              ..body = const Code(
                'Uint8List.fromList('
                '_builder.takeBytes()).asUnmodifiableView()',
              ),
          ),
        ]),
    ),
  ];

  Method _method(
    String name,
    String docs,
    List<Parameter> parameters,
    Code body,
  ) => Method.returnsVoid(
    (builder) => builder
      ..name = name
      ..docs.add('/// $docs')
      ..requiredParameters.addAll(parameters)
      ..body = body,
  );

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
