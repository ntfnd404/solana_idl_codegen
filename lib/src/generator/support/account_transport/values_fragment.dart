import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits account snapshots, read options, and scanner filters.
final class AccountTransportValuesFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountTransportValuesFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final snapshot = type('account_snapshot');
    final commitment = type('commitment');
    final readOptions = type('account_read_options');
    final filter = type('account_filter');
    return <Spec>[
      _snapshot(snapshot, address),
      Enum(
        (builder) => builder
          ..name = commitment
          ..docs.add('/// Commitment used by generated account reads.')
          ..values.addAll([
            _enumValue('processed', 'Processed commitment.'),
            _enumValue('confirmed', 'Confirmed commitment.'),
            _enumValue('finalized', 'Finalized commitment.'),
          ]),
      ),
      _readOptions(readOptions, commitment),
      Class(
        (builder) => builder
          ..name = filter
          ..sealed = true
          ..docs.add(
            '/// Base class for transport-neutral account scanner filters.',
          )
          ..constructors.add(
            Constructor(
              (builder) => builder
                ..constant = true
                ..docs.add('/// Creates an account scanner filter.'),
            ),
          ),
      ),
      _memcmp(type('memcmp_filter'), filter),
      _dataSize(type('data_size_filter'), filter),
    ];
  }

  Class _snapshot(String name, String address) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add(
        '/// Immutable account state returned by an application adapter.',
      )
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates an account snapshot and copies [data].')
            ..optionalParameters.addAll([
              _thisParameter('address'),
              _thisParameter('owner'),
              _namedParameter('data', 'List<int>'),
              _thisParameter('lamports'),
              _thisParameter('executable'),
              _thisParameter('rentEpoch'),
              _thisParameter('slot'),
            ])
            ..initializers.add(
              const Code(
                'data = Uint8List.fromList(data).asUnmodifiableView()',
              ),
            ),
        ),
      )
      ..fields.addAll([
        _field('address', address, 'Account address.'),
        _field('owner', address, 'Owning program address.'),
        _field('data', 'Uint8List', 'Immutable account data.'),
        _field('lamports', 'BigInt', 'Account balance.'),
        _field(
          'executable',
          'bool',
          'Whether the account contains executable code.',
        ),
        _field('rentEpoch', 'BigInt', 'Rent epoch reported by the transport.'),
        _field('slot', 'BigInt', 'Context slot.'),
      ]),
  );

  Class _readOptions(String name, String commitment) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Transport-neutral account read options.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates account read options.')
            ..optionalParameters.addAll([
              Parameter(
                (builder) => builder
                  ..name = 'commitment'
                  ..named = true
                  ..toThis = true
                  ..defaultTo = Code('$commitment.confirmed'),
              ),
              Parameter(
                (builder) => builder
                  ..name = 'minContextSlot'
                  ..named = true
                  ..toThis = true,
              ),
            ]),
        ),
      )
      ..fields.addAll([
        _field('commitment', commitment, 'Requested commitment.'),
        _field('minContextSlot', 'BigInt?', 'Optional minimum context slot.'),
      ]),
  );

  Class _memcmp(String name, String filter) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..extend = refer(filter)
      ..docs.add('/// Immutable memcmp scanner filter.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates a memcmp filter and copies [bytes].')
            ..optionalParameters.addAll([
              _thisParameter('offset'),
              _namedParameter('bytes', 'List<int>'),
            ])
            ..initializers.add(
              const Code(
                'bytes = Uint8List.fromList(bytes).asUnmodifiableView()',
              ),
            )
            ..body = const Code('''
if (offset < 0) {
  throw ArgumentError.value(offset, 'offset');
}'''),
        ),
      )
      ..fields.addAll([
        _field('offset', 'int', 'Byte offset.'),
        _field('bytes', 'Uint8List', 'Bytes to compare.'),
      ]),
  );

  Class _dataSize(String name, String filter) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..extend = refer(filter)
      ..docs.add('/// Immutable account data-size scanner filter.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a data-size filter.')
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'size'
                  ..toThis = true,
              ),
            )
            ..initializers.add(const Code('assert(size >= 0)')),
        ),
      )
      ..fields.add(_field('size', 'int', 'Required byte length.')),
  );

  EnumValue _enumValue(String name, String docs) => EnumValue(
    (builder) => builder
      ..name = name
      ..docs.add('/// $docs'),
  );

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
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
      ..docs.add('/// $docs'),
  );
}
