import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits generated program metadata declarations used by type libraries.
final class TypeMetadataFragment extends SectionEmitter {
  /// Creates a metadata fragment for [context].
  const TypeMetadataFragment(super.context);

  /// Emits required value helpers and generated program metadata.
  @override
  List<Spec> emit() => [
    if (context.features.usesStructuralListEquality) _listEquals(),
    _programMetadata(),
  ];

  Method _listEquals() => Method(
    (builder) => builder
      ..name = '_${member('program')}ListEquals'
      ..types.add(refer('T'))
      ..returns = refer('bool')
      ..requiredParameters.addAll([
        _parameter('left', 'List<T>'),
        _parameter('right', 'List<T>'),
        _parameter('equals', 'bool Function(T left, T right)'),
      ])
      ..body = const Code('''
if (left.length != right.length) {
  return false;
}
for (var index = 0; index < left.length; index++) {
  if (!equals(left[index], right[index])) {
    return false;
  }
}
return true;'''),
  );

  Class _programMetadata() {
    final program = context.program;
    final address = type('address');
    return Class(
      (builder) => builder
        ..name = type('program')
        ..abstract = true
        ..modifier = ClassModifier.final$
        ..docs.addAll(
          documentation(
            'Generated metadata for `${program.name}`.',
            program.docs,
          ),
        )
        ..fields.addAll([
          _staticConstant(
            'name',
            'String',
            literalString(program.name).code,
            'Program name declared by the IDL.',
          ),
          _staticConstant(
            'version',
            'String',
            literalString(program.version).code,
            'Program version declared by the IDL.',
          ),
          _staticConstant(
            'spec',
            'String',
            literalString(program.spec).code,
            'Anchor IDL specification dialect.',
          ),
          _staticConstant(
            'address',
            'String',
            literalString(program.address).code,
            'Base58 program address declared by the IDL.',
          ),
          Field(
            (builder) => builder
              ..name = 'programAddress'
              ..type = refer(address)
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// Parsed program address.')
              ..assignment = Code('$address.fromBase58(address)'),
          ),
        ]),
    );
  }

  /// Formats documentation lines with a generated summary and IDL docs.
  static List<String> documentation(String summary, List<String> idlDocs) => [
    '/// $summary',
    if (idlDocs.isNotEmpty) '///',
    for (final line in idlDocs)
      for (final part in line.replaceAll('\r\n', '\n').split('\n'))
        part.isEmpty ? '///' : '/// $part',
  ];

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );

  Field _staticConstant(
    String name,
    String type,
    Code assignment,
    String docs,
  ) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..static = true
      ..modifier = FieldModifier.constant
      ..docs.add('/// $docs')
      ..assignment = assignment,
  );
}
