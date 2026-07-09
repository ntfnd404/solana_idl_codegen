import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits generic Borsh codec contracts and callback implementation.
final class BorshCodecFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshCodecFragment(super.context);

  @override
  List<Spec> emit() {
    final limits = type('decode_limits');
    final error = type('borsh_exception');
    final reader = type('borsh_reader');
    final writer = type('borsh_writer');
    final codec = type('borsh_codec');
    return <Spec>[
      _codec(codec, limits, error, reader, writer),
      _functional(type('functional_borsh_codec'), codec, reader, writer),
    ];
  }

  Class _codec(
    String name,
    String limits,
    String error,
    String reader,
    String writer,
  ) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.base
      ..types.add(refer('T'))
      ..docs.add('/// Base class for deterministic Borsh codecs.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a codec.'),
        ),
      )
      ..methods.addAll([
        Method(
          (builder) => builder
            ..name = 'read'
            ..returns = refer('T')
            ..docs.add('/// Reads one value from [reader].')
            ..requiredParameters.add(_parameter('reader', reader)),
        ),
        Method.returnsVoid(
          (builder) => builder
            ..name = 'write'
            ..docs.add('/// Writes one [value] to [writer].')
            ..requiredParameters.addAll([
              _parameter('writer', writer),
              _parameter('value', 'T'),
            ]),
        ),
        Method(
          (builder) => builder
            ..name = 'encode'
            ..returns = refer('Uint8List')
            ..docs.add('/// Encodes [value] into an immutable byte array.')
            ..requiredParameters.add(_parameter('value', 'T'))
            ..body = Code('''
final writer = $writer();
write(writer, value);
return writer.takeBytes();'''),
        ),
        Method(
          (builder) => builder
            ..name = 'decodeExact'
            ..returns = refer('T')
            ..docs.add(
              '/// Decodes one value and requires complete input consumption.',
            )
            ..requiredParameters.add(_parameter('input', 'List<int>'))
            ..optionalParameters.add(_limitsParameter(limits))
            ..body = Code('''
final result = decodePrefix(input, limits: limits);
if (result.consumed != input.length) {
  throw $error(
    code: 'BORSH_TRAILING_BYTES',
    message: 'Input contains trailing bytes.',
    offset: result.consumed,
    path: r'\$',
    expected: '\${result.consumed} bytes',
    actual: '\${input.length} bytes',
  );
}
return result.value;'''),
        ),
        Method(
          (builder) => builder
            ..name = 'decodePrefix'
            ..returns = refer('({T value, int consumed})')
            ..docs.add(
              '/// Decodes one value and returns its consumed byte count.',
            )
            ..requiredParameters.add(_parameter('input', 'List<int>'))
            ..optionalParameters.add(_limitsParameter(limits))
            ..body = Code('''
final reader = $reader(input, limits: limits);
return (value: read(reader), consumed: reader.offset);'''),
        ),
      ]),
  );

  Class _functional(String name, String codec, String reader, String writer) =>
      Class(
        (builder) => builder
          ..name = name
          ..modifier = ClassModifier.final$
          ..types.add(refer('T'))
          ..extend = refer('$codec<T>')
          ..docs.add(
            '/// Codec assembled from injected read and write functions.',
          )
          ..constructors.add(
            Constructor(
              (builder) => builder
                ..constant = true
                ..docs.add('/// Creates a codec from [reader] and [writer].')
                ..requiredParameters.addAll([
                  _thisParameter('reader'),
                  _thisParameter('writer'),
                ]),
            ),
          )
          ..fields.addAll([
            _field(
              'reader',
              'T Function($reader reader)',
              'Function that reads one value.',
            ),
            _field(
              'writer',
              'void Function($writer writer, T value)',
              'Function that writes one value.',
            ),
          ])
          ..methods.addAll([
            Method(
              (builder) => builder
                ..name = 'read'
                ..returns = refer('T')
                ..annotations.add(refer('override'))
                ..requiredParameters.add(_parameter('reader', reader))
                ..lambda = true
                ..body = const Code('this.reader(reader)'),
            ),
            Method.returnsVoid(
              (builder) => builder
                ..name = 'write'
                ..annotations.add(refer('override'))
                ..requiredParameters.addAll([
                  _parameter('writer', writer),
                  _parameter('value', 'T'),
                ])
                ..lambda = true
                ..body = const Code('this.writer(writer, value)'),
            ),
          ]),
      );

  Parameter _limitsParameter(String limits) => Parameter(
    (builder) => builder
      ..name = 'limits'
      ..type = refer(limits)
      ..named = true
      ..defaultTo = Code('$limits.defaults'),
  );

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..toThis = true,
  );

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
