import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits generated account discriminator metadata and decode helpers.
final class AccountDecoderEmitter extends SectionEmitter {
  /// Creates an account decoder emitter for [context].
  const AccountDecoderEmitter(super.context);

  /// Emits account decoder declarations in IDL source order.
  @override
  List<Spec> emit() => List.unmodifiable([
    for (final account in context.program.accounts)
      accountDecoder(account.name, account.discriminator),
  ]);

  /// Emits one account decoder helper class.
  Class accountDecoder(String accountName, List<int> discriminator) {
    final model = type(accountName);
    final api = type('${accountName}_account');
    final limits = type('decode_limits');
    return Class(
      (builder) => builder
        ..name = api
        ..abstract = true
        ..modifier = ClassModifier.final$
        ..docs.add(
          '/// Decoder and discriminator metadata for `$model` accounts.',
        )
        ..fields.add(
          Field(
            (builder) => builder
              ..name = 'discriminator'
              ..type = refer('List<int>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// IDL discriminator bytes.')
              ..assignment = Code('List.unmodifiable(${bytes(discriminator)})'),
          ),
        )
        ..methods.addAll([
          _decodeMethod(
            name: 'decodeAccount',
            model: model,
            limits: limits,
            exact: false,
          ),
          _decodeMethod(
            name: 'decodeAccountExact',
            model: model,
            limits: limits,
            exact: true,
          ),
          Method(
            (builder) => builder
              ..name = '_verifyDiscriminator'
              ..static = true
              ..returns = refer('void')
              ..requiredParameters.add(_parameter('data', 'List<int>'))
              ..body = const Code('''
if (data.length < discriminator.length) {
  throw FormatException('Account data is shorter than its discriminator.');
}
for (var index = 0; index < discriminator.length; index++) {
  if (data[index] != discriminator[index]) {
    throw FormatException('Account discriminator mismatch.');
  }
}'''),
          ),
        ]),
    );
  }

  Method _decodeMethod({
    required String name,
    required String model,
    required String limits,
    required bool exact,
  }) => Method(
    (builder) => builder
      ..name = name
      ..static = true
      ..returns = refer(model)
      ..docs.add(
        exact
            ? '/// Decodes account data and rejects trailing bytes.'
            : '/// Decodes account data and permits trailing allocation padding.',
      )
      ..requiredParameters.add(_parameter('data', 'List<int>'))
      ..optionalParameters.add(
        Parameter(
          (builder) => builder
            ..name = 'limits'
            ..type = refer(limits)
            ..named = true
            ..defaultTo = Code('$limits.defaults'),
        ),
      )
      ..body = Code('''
_verifyDiscriminator(data);
return $model.codec.${exact ? 'decodeExact' : 'decodePrefix'}(
  data.sublist(discriminator.length),
  limits: limits,
)${exact ? '' : '.value'};'''),
  );

  Parameter _parameter(String name, String parameterType) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType),
  );
}
