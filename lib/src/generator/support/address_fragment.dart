import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits the generated immutable address value object.
final class AddressSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AddressSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[_address(type('address'), member('program'))];

  Class _address(String name, String prefix) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add(
        '/// Immutable 32-byte Solana address used by the generated SDK.',
      )
      ..constructors.addAll([
        Constructor(
          (builder) => builder
            ..name = '_'
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'bytes'
                  ..type = refer('Uint8List'),
              ),
            )
            ..initializers.add(
              const Code('_bytes = Uint8List.fromList(bytes)'),
            ),
        ),
        Constructor(
          (builder) => builder
            ..name = 'fromBytes'
            ..factory = true
            ..docs.add('/// Creates an address from exactly 32 bytes.')
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'bytes'
                  ..type = refer('List<int>'),
              ),
            )
            ..body = Code('''
if (bytes.length != 32) {
  throw ArgumentError.value(bytes.length, 'bytes', 'Expected 32 bytes.');
}
for (final byte in bytes) {
  if (byte < 0 || byte > 255) {
    throw ArgumentError.value(byte, 'bytes', 'Expected byte values.');
  }
}
return $name._(Uint8List.fromList(bytes));'''),
        ),
        Constructor(
          (builder) => builder
            ..name = 'fromBase58'
            ..factory = true
            ..docs.add('/// Decodes a canonical Base58 address.')
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'value'
                  ..type = refer('String'),
              ),
            )
            ..body = Code('''
final decoded = _${prefix}DecodeBase58(value);
if (decoded.length != 32) {
  throw FormatException('Address must decode to exactly 32 bytes.');
}
final address = $name.fromBytes(decoded);
if (address.toBase58() != value) {
  throw FormatException('Address is not canonical Base58.');
}
return address;'''),
        ),
      ])
      ..fields.add(
        Field(
          (builder) => builder
            ..name = '_bytes'
            ..modifier = FieldModifier.final$
            ..type = refer('Uint8List'),
        ),
      )
      ..methods.addAll([
        Method(
          (builder) => builder
            ..name = 'bytes'
            ..type = MethodType.getter
            ..returns = refer('Uint8List')
            ..docs.add(
              '/// Returns an unmodifiable defensive copy of the address bytes.',
            )
            ..lambda = true
            ..body = const Code(
              'Uint8List.fromList(_bytes).asUnmodifiableView()',
            ),
        ),
        Method(
          (builder) => builder
            ..name = 'toBase58'
            ..returns = refer('String')
            ..docs.add('/// Encodes this address as Base58.')
            ..lambda = true
            ..body = Code('_${prefix}EncodeBase58(_bytes)'),
        ),
        Method(
          (builder) => builder
            ..name = 'operator =='
            ..returns = refer('bool')
            ..annotations.add(refer('override'))
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'other'
                  ..type = refer('Object'),
              ),
            )
            ..lambda = true
            ..body = Code(
              'identical(this, other) || '
              'other is $name && _${prefix}BytesEqual(_bytes, other._bytes)',
            ),
        ),
        Method(
          (builder) => builder
            ..name = 'hashCode'
            ..type = MethodType.getter
            ..returns = refer('int')
            ..annotations.add(refer('override'))
            ..lambda = true
            ..body = const Code('Object.hashAll(_bytes)'),
        ),
        Method(
          (builder) => builder
            ..name = 'toString'
            ..returns = refer('String')
            ..annotations.add(refer('override'))
            ..lambda = true
            ..body = const Code('toBase58()'),
        ),
      ]),
  );
}
