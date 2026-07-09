import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits relation and external account-data seed resolver ports.
final class AccountResolutionPortsSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountResolutionPortsSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final snapshot = type('account_snapshot');
    final relation = type('relation_resolver');
    final externalSeed = type('external_account_seed_resolver');
    return <Spec>[
      _relationResolver(relation, address),
      _externalSeedResolver(externalSeed, address, snapshot),
      _externalSeedCallback(externalSeed, address, snapshot),
    ];
  }

  Class _relationResolver(String name, String address) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add(
        '/// Port used for application-specific account relation resolution.',
      )
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'resolveRelation'
            ..returns = refer('Future<$address?>')
            ..docs.add(
              '/// Resolves [relationPath] or returns `null` when unavailable.',
            )
            ..optionalParameters.addAll([
              _namedParameter('accountPath', 'String'),
              _namedParameter('relationPath', 'String'),
              _namedParameter('resolvedAccounts', 'Map<String, $address>'),
            ]),
        ),
      ),
  );

  Class _externalSeedResolver(
    String name,
    String address,
    String snapshot,
  ) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add(
        '/// Port used to decode a PDA seed from application-owned external account data.',
      )
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'resolve'
            ..returns = refer('Future<Uint8List>')
            ..docs.add(
              '/// Returns encoded seed bytes for the declared external account field.',
            )
            ..optionalParameters.addAll(
              _externalSeedParameters(address, snapshot),
            ),
        ),
      ),
  );

  Class _externalSeedCallback(
    String externalSeed,
    String address,
    String snapshot,
  ) {
    final name = type('external_account_seed_resolver_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(externalSeed))
        ..docs.add('/// Callback adapter for [$externalSeed].')
        ..constructors.add(_callbackConstructor())
        ..fields.add(
          _field(
            'callback',
            'Future<Uint8List> Function('
                'String accountPath, '
                'String fieldPath, '
                'String declaredType, '
                '$address address, '
                '$snapshot snapshot)',
            '/// External seed callback.',
          ),
        )
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'resolve'
              ..returns = refer('Future<Uint8List>')
              ..annotations.add(refer('override'))
              ..modifier = MethodModifier.async
              ..optionalParameters.addAll(
                _externalSeedParameters(address, snapshot),
              )
              ..lambda = true
              ..body = const Code('''
Uint8List.fromList(
  await callback(accountPath, fieldPath, declaredType, address, snapshot),
).asUnmodifiableView()'''),
          ),
        ),
    );
  }

  List<Parameter> _externalSeedParameters(String address, String snapshot) => [
    _namedParameter('accountPath', 'String'),
    _namedParameter('fieldPath', 'String'),
    _namedParameter('declaredType', 'String'),
    _namedParameter('address', address),
    _namedParameter('snapshot', snapshot),
  ];

  Constructor _callbackConstructor() => Constructor(
    (builder) => builder
      ..constant = true
      ..docs.add('/// Creates an adapter from [callback].')
      ..requiredParameters.add(
        Parameter(
          (builder) => builder
            ..name = 'callback'
            ..toThis = true,
        ),
      ),
  );

  Parameter _namedParameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..named = true
      ..required = true,
  );

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add(docs),
  );
}
