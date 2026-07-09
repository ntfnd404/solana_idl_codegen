import 'package:code_builder/code_builder.dart';

import '../naming.dart';
import 'section_emitter.dart';

/// Emits the generated typed account fetch/scan client.
final class AccountsClientEmitter extends SectionEmitter {
  /// Creates an accounts client emitter for [context].
  const AccountsClientEmitter(super.context);

  /// Emits the account client declaration.
  @override
  List<Spec> emit() => [_accountsClient()];

  Class _accountsClient() => Class(
    (builder) => builder
      ..name = type('accounts_client')
      ..modifier = ClassModifier.final$
      ..docs.add('/// Typed account reader and scanner client.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a client from narrow account capabilities.')
            ..optionalParameters.addAll([
              Parameter(
                (builder) => builder
                  ..name = 'reader'
                  ..toThis = true
                  ..named = true
                  ..required = true,
              ),
              Parameter(
                (builder) => builder
                  ..name = 'scanner'
                  ..toThis = true
                  ..named = true,
              ),
            ]),
        ),
      )
      ..fields.addAll([
        _field('reader', type('account_reader'), 'Account read capability.'),
        _field(
          'scanner',
          '${type('account_scanner')}?',
          'Optional account scan capability.',
        ),
      ])
      ..methods.addAll([
        for (final account in context.program.accounts)
          ..._accountClientMethods(account.name),
      ]),
  );

  Iterable<Method> _accountClientMethods(String accountName) {
    final model = type(accountName);
    final api = type('${accountName}_account');
    final suffix = const DartNamingStrategy().typeName(accountName);
    return [
      _clientMethod(
        name: 'fetch$suffix',
        returnType: 'Future<$model>',
        docs: 'Fetches and validates one `$model` account.',
        parameters: _readParameters(address: true),
        body:
            '''
final snapshot = await reader.readAccount(address, options: options);
if (snapshot == null) {
  throw const ${type('account_exception')}(code: 'ACCOUNT_NOT_FOUND', message: 'Account does not exist.');
}
${_ownerCheck('snapshot')}
return $api.decodeAccount(snapshot.data, limits: limits);''',
      ),
      _clientMethod(
        name: 'fetch${suffix}Nullable',
        returnType: 'Future<$model?>',
        docs: 'Fetches one account or returns `null` only when absent.',
        parameters: _readParameters(address: true),
        body:
            '''
final snapshot = await reader.readAccount(address, options: options);
if (snapshot == null) return null;
${_ownerCheck('snapshot')}
return $api.decodeAccount(snapshot.data, limits: limits);''',
      ),
      _clientMethod(
        name: 'fetchMultiple$suffix',
        returnType: 'Future<List<$model?>>',
        docs: 'Fetches accounts while preserving order and missing positions.',
        parameters: _readParameters(addresses: true),
        body:
            '''
final snapshots = await reader.readAccounts(
  List.unmodifiable(addresses),
  options: options,
);
if (snapshots.length != addresses.length) {
  throw const ${type('account_exception')}(code: 'ACCOUNT_RESULT_CARDINALITY', message: 'AccountReader changed result cardinality.');
}
return List.unmodifiable(snapshots.map((snapshot) {
  if (snapshot == null) return null;
  ${_ownerCheck('snapshot')}
  return $api.decodeAccount(snapshot.data, limits: limits);
}));''',
      ),
      _clientMethod(
        name: 'all$suffix',
        returnType: 'Future<List<$model>>',
        docs: 'Scans every matching program account.',
        parameters: _readParameters(filters: true),
        body:
            '''
final capability = scanner;
if (capability == null) {
  throw const ${type('account_exception')}(code: 'ACCOUNT_SCANNER_UNAVAILABLE', message: 'AccountScanner capability is unavailable.');
}
final discriminatorFilter = ${type('memcmp_filter')}(
  offset: 0,
  bytes: $api.discriminator,
);
final snapshots = await capability.scanAccounts(
  ${type('program')}.programAddress,
  filters: [discriminatorFilter, ...filters],
  options: options,
);
return List.unmodifiable(snapshots.map((snapshot) {
  ${_ownerCheck('snapshot')}
  return $api.decodeAccount(snapshot.data, limits: limits);
}));''',
      ),
    ];
  }

  Method _clientMethod({
    required String name,
    required String returnType,
    required String docs,
    required Iterable<Parameter> parameters,
    required String body,
  }) => Method(
    (builder) => builder
      ..name = name
      ..returns = refer(returnType)
      ..modifier = MethodModifier.async
      ..docs.add('/// $docs')
      ..requiredParameters.addAll(
        parameters.where((parameter) => !parameter.named),
      )
      ..optionalParameters.addAll(
        parameters.where((parameter) => parameter.named),
      )
      ..body = Code(body),
  );

  List<Parameter> _readParameters({
    bool address = false,
    bool addresses = false,
    bool filters = false,
  }) => [
    if (address) _parameter('address', type('address')),
    if (addresses) _parameter('addresses', 'List<${type('address')}>'),
    if (filters)
      _namedParameter('filters', 'List<${type('account_filter')}>', 'const []'),
    _namedParameter(
      'options',
      type('account_read_options'),
      'const ${type('account_read_options')}()',
    ),
    _namedParameter(
      'limits',
      type('decode_limits'),
      '${type('decode_limits')}.defaults',
    ),
  ];

  String _ownerCheck(String snapshot) =>
      '''if ($snapshot.owner != ${type('program')}.programAddress) {
  throw const ${type('account_exception')}(code: 'ACCOUNT_OWNER_MISMATCH', message: 'Account owner mismatch.');
}''';

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );

  Parameter _parameter(String name, String parameterType) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType),
  );

  Parameter _namedParameter(
    String name,
    String parameterType,
    String defaultValue,
  ) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType)
      ..named = true
      ..defaultTo = Code(defaultValue),
  );
}
