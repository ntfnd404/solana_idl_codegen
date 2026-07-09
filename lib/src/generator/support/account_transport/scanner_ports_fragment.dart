import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits account scanner port and callback adapter.
final class AccountScannerPortsFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountScannerPortsFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final snapshot = type('account_snapshot');
    final filter = type('account_filter');
    final options = type('account_read_options');
    final scanner = type('account_scanner');
    return <Spec>[
      _scanner(scanner, address, snapshot, filter, options),
      _scannerCallback(scanner, address, snapshot, filter, options),
    ];
  }

  Class _scanner(
    String name,
    String address,
    String snapshot,
    String filter,
    String options,
  ) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add('/// Port used to scan program-owned accounts.')
      ..methods.add(_scanMethod(address, snapshot, filter, options)),
  );

  Class _scannerCallback(
    String scanner,
    String address,
    String snapshot,
    String filter,
    String options,
  ) {
    final name = type('account_scanner_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(scanner))
        ..docs.add('/// Callback adapter for [$scanner].')
        ..constructors.add(
          Constructor(
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
          ),
        )
        ..fields.add(
          _field(
            'callback',
            'Future<List<$snapshot>> Function('
                '$address, List<$filter>, $options)',
            'Scanner callback.',
          ),
        )
        ..methods.add(
          _scanMethod(
            address,
            snapshot,
            filter,
            options,
            override: true,
            body: const Code(
              'List.unmodifiable(await callback('
              'programAddress, List.unmodifiable(filters), options))',
            ),
          ),
        ),
    );
  }

  Method _scanMethod(
    String address,
    String snapshot,
    String filter,
    String options, {
    bool override = false,
    Code? body,
  }) => Method(
    (builder) => builder
      ..name = 'scanAccounts'
      ..returns = refer('Future<List<$snapshot>>')
      ..docs.addAll(
        override
            ? const []
            : ['/// Scans accounts using ordered transport-neutral [filters].'],
      )
      ..annotations.addAll(override ? [refer('override')] : const [])
      ..modifier = body == null ? null : MethodModifier.async
      ..requiredParameters.add(_parameter('programAddress', address))
      ..optionalParameters.addAll([
        Parameter(
          (builder) => builder
            ..name = 'filters'
            ..type = refer('List<$filter>')
            ..named = true
            ..defaultTo = const Code('const []'),
        ),
        _optionsParameter(options),
      ])
      ..lambda = body == null ? null : true
      ..body = body,
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

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
