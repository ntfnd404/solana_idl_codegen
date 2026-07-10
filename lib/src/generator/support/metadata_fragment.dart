import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits immutable generated metadata value objects.
final class MetadataSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const MetadataSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    _accountMetadata(type('account_metadata')),
    _instructionAccountMetadata(type('instruction_account_metadata')),
    _instructionMetadata(type('instruction_metadata')),
  ];

  Class _accountMetadata(String name) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Immutable metadata for one generated account decoder.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates account metadata and copies byte lists.')
            ..optionalParameters.addAll([
              _thisNamed('name'),
              _named('discriminator', 'List<int>'),
            ])
            ..initializers.add(
              const Code('discriminator = List.unmodifiable(discriminator)'),
            ),
        ),
      )
      ..fields.addAll([
        _field('name', 'String', '/// IDL account name.'),
        _field(
          'discriminator',
          'List<int>',
          '/// Account discriminator bytes.',
        ),
      ])
      ..methods.add(_discriminatorLengthGetter()),
  );

  Class _instructionAccountMetadata(String name) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Immutable metadata for one instruction account position.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates instruction account metadata.')
            ..optionalParameters.addAll([
              _thisNamed('name'),
              _thisNamed('path'),
              _thisNamed('isSigner'),
              _thisNamed('isWritable'),
              _thisNamed('isOptional'),
            ]),
        ),
      )
      ..fields.addAll([
        _field('name', 'String', '/// Leaf account name from the IDL.'),
        _field(
          'path',
          'String',
          '/// Dot-separated account path from the IDL.',
        ),
        _field('isSigner', 'bool', '/// Whether this account signs.'),
        _field('isWritable', 'bool', '/// Whether this account is writable.'),
        _field('isOptional', 'bool', '/// Whether this account is optional.'),
      ]),
  );

  Class _instructionMetadata(String name) {
    final account = type('instruction_account_metadata');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add('/// Immutable metadata for one generated instruction.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..docs.add(
                '/// Creates instruction metadata and copies collections.',
              )
              ..optionalParameters.addAll([
                _thisNamed('name'),
                _named('discriminator', 'List<int>'),
                _named('accounts', 'List<$account>'),
              ])
              ..initializers.addAll([
                const Code('discriminator = List.unmodifiable(discriminator)'),
                const Code('accounts = List.unmodifiable(accounts)'),
              ]),
          ),
        )
        ..fields.addAll([
          _field('name', 'String', '/// IDL instruction name.'),
          _field(
            'discriminator',
            'List<int>',
            '/// Instruction discriminator bytes.',
          ),
          _field(
            'accounts',
            'List<$account>',
            '/// Ordered account metadata. Duplicate positions are preserved.',
          ),
        ])
        ..methods.add(_discriminatorLengthGetter()),
    );
  }

  Method _discriminatorLengthGetter() => Method(
    (builder) => builder
      ..name = 'discriminatorLength'
      ..type = MethodType.getter
      ..returns = refer('int')
      ..docs.add('/// Number of discriminator bytes.')
      ..lambda = true
      ..body = const Code('discriminator.length'),
  );

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add(docs),
  );

  Parameter _named(String name, String parameterType) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType)
      ..named = true
      ..required = true,
  );

  Parameter _thisNamed(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );
}
