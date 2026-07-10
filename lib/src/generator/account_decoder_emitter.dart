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
    _accountRegistry(),
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
        ..fields.addAll([
          Field(
            (builder) => builder
              ..name = 'name'
              ..type = refer('String')
              ..static = true
              ..modifier = FieldModifier.constant
              ..docs.add('/// IDL account name.')
              ..assignment = Code("'${escape(accountName)}'"),
          ),
          Field(
            (builder) => builder
              ..name = 'discriminatorLength'
              ..type = refer('int')
              ..static = true
              ..modifier = FieldModifier.constant
              ..docs.add('/// Number of discriminator bytes.')
              ..assignment = Code('${discriminator.length}'),
          ),
          Field(
            (builder) => builder
              ..name = 'metadata'
              ..type = refer(type('account_metadata'))
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// Data-only account metadata.')
              ..assignment = Code(
                "${type('account_metadata')}(name: name, "
                'discriminator: discriminator)',
              ),
          ),
        ])
        ..methods.addAll([
          _tryDecodeMethod(model: model, limits: limits),
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
if (!_hasDiscriminator(data)) {
  throw FormatException('Account discriminator mismatch.');
}'''),
          ),
          Method(
            (builder) => builder
              ..name = '_hasDiscriminator'
              ..static = true
              ..returns = refer('bool')
              ..requiredParameters.add(_parameter('data', 'List<int>'))
              ..body = const Code('''
if (data.length < discriminator.length) return false;
for (var index = 0; index < discriminator.length; index++) {
  if (data[index] != discriminator[index]) return false;
}
return true;'''),
          ),
        ]),
    );
  }

  Class _accountRegistry() {
    final metadata = type('account_metadata');
    return Class(
      (builder) => builder
        ..name = type('account_registry')
        ..abstract = true
        ..modifier = ClassModifier.final$
        ..docs.add('/// Program-level registry of generated account metadata.')
        ..fields.addAll([
          Field(
            (builder) => builder
              ..name = 'accounts'
              ..type = refer('List<$metadata>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// Accounts declared by the IDL in source order.')
              ..assignment = Code(
                'List.unmodifiable(<$metadata>['
                '${context.program.accounts.map((account) => '${type('${account.name}_account')}.metadata').join(', ')}'
                '])',
              ),
          ),
          Field(
            (builder) => builder
              ..name = 'byName'
              ..type = refer('Map<String, $metadata>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// Account metadata indexed by IDL account name.')
              ..assignment = const Code(
                'Map.unmodifiable({for (final account in accounts) '
                'account.name: account})',
              ),
          ),
        ]),
    );
  }

  Method _tryDecodeMethod({
    required String model,
    required String limits,
  }) => Method(
    (builder) => builder
      ..name = 'tryDecodeAccount'
      ..static = true
      ..returns = refer('$model?')
      ..docs.add(
        '/// Decodes account data or returns `null` on discriminator mismatch.',
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
if (!_hasDiscriminator(data)) return null;
return $model.codec.decodePrefix(
  data.sublist(discriminator.length),
  limits: limits,
).value;'''),
  );

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
