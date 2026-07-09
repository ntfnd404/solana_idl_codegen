import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits account reader port and callback adapter.
final class AccountReaderPortsFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountReaderPortsFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final snapshot = type('account_snapshot');
    final options = type('account_read_options');
    final reader = type('account_reader');
    return <Spec>[
      _reader(reader, address, snapshot, options),
      _readerCallback(reader, address, snapshot, options),
    ];
  }

  Class _reader(
    String name,
    String address,
    String snapshot,
    String options,
  ) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add(
        '/// Port used by generated account clients to read addresses.',
      )
      ..methods.addAll([
        _readMethod(
          'readAccount',
          'Future<$snapshot?>',
          _parameter('address', address),
          options,
          'Reads one account or returns `null` when it does not exist.',
        ),
        _readMethod(
          'readAccounts',
          'Future<List<$snapshot?>>',
          _parameter('addresses', 'List<$address>'),
          options,
          'Reads accounts while preserving input order and missing positions.',
        ),
      ]),
  );

  Class _readerCallback(
    String reader,
    String address,
    String snapshot,
    String options,
  ) {
    final name = type('account_reader_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(reader))
        ..docs.add('/// Callback adapter for [$reader].')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates an adapter from callbacks.')
              ..optionalParameters.addAll([
                _thisParameter('readOne'),
                _thisParameter('readMany'),
              ]),
          ),
        )
        ..fields.addAll([
          _field(
            'readOne',
            'Future<$snapshot?> Function($address, $options)',
            'Single-account callback.',
          ),
          _field(
            'readMany',
            'Future<List<$snapshot?>> Function(List<$address>, $options)',
            'Multi-account callback.',
          ),
        ])
        ..methods.addAll([
          Method(
            (builder) => builder
              ..name = 'readAccount'
              ..returns = refer('Future<$snapshot?>')
              ..annotations.add(refer('override'))
              ..requiredParameters.add(_parameter('address', address))
              ..optionalParameters.add(_optionsParameter(options))
              ..lambda = true
              ..body = const Code('readOne(address, options)'),
          ),
          Method(
            (builder) => builder
              ..name = 'readAccounts'
              ..returns = refer('Future<List<$snapshot?>>')
              ..annotations.add(refer('override'))
              ..modifier = MethodModifier.async
              ..requiredParameters.add(
                _parameter('addresses', 'List<$address>'),
              )
              ..optionalParameters.add(_optionsParameter(options))
              ..lambda = true
              ..body = const Code(
                'List.unmodifiable('
                'await readMany(List.unmodifiable(addresses), options))',
              ),
          ),
        ]),
    );
  }

  Method _readMethod(
    String name,
    String returns,
    Parameter input,
    String options,
    String docs,
  ) => Method(
    (builder) => builder
      ..name = name
      ..returns = refer(returns)
      ..docs.add('/// $docs')
      ..requiredParameters.add(input)
      ..optionalParameters.add(_optionsParameter(options)),
  );

  Parameter _optionsParameter(String options) => Parameter(
    (builder) => builder
      ..name = 'options'
      ..type = refer(options)
      ..named = true
      ..defaultTo = Code('const $options()'),
  );

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
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
