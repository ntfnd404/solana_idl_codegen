import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits the generated immutable instruction value object.
final class InstructionSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const InstructionSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[_instruction(type('instruction'))];

  Class _instruction(String name) {
    final address = type('address');
    final meta = type('account_meta');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add('/// Immutable transport-neutral Solana instruction.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..docs.add(
                '/// Creates an instruction and defensively copies collections.',
              )
              ..optionalParameters.addAll([
                _thisParameter('programAddress'),
                _namedParameter('accounts', 'List<$meta>'),
                _namedParameter('data', 'List<int>'),
              ])
              ..initializers.addAll([
                const Code('accounts = List.unmodifiable(accounts)'),
                const Code(
                  'data = Uint8List.fromList(data).asUnmodifiableView()',
                ),
              ]),
          ),
        )
        ..fields.addAll([
          _finalField(
            'programAddress',
            address,
            '/// Program invoked by this instruction.',
          ),
          _finalField(
            'accounts',
            'List<$meta>',
            '/// Ordered account metadata. Duplicate positions are preserved.',
          ),
          _finalField(
            'data',
            'Uint8List',
            '/// Immutable serialized instruction data.',
          ),
        ])
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'toWire'
              ..returns = refer(
                '({Uint8List programAddress, '
                'List<({Uint8List address, bool isSigner, bool isWritable})> '
                'accounts, Uint8List data})',
              )
              ..docs.add(
                '/// Returns a structural wire record for cross-program composition.',
              )
              ..lambda = true
              ..body = const Code('''
(
  programAddress: programAddress.bytes,
  accounts: List.unmodifiable(
    accounts.map(
      (item) => (
        address: item.address.bytes,
        isSigner: item.isSigner,
        isWritable: item.isWritable,
      ),
    ),
  ),
  data: Uint8List.fromList(data).asUnmodifiableView(),
)'''),
          ),
        ),
    );
  }

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

  Field _finalField(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add(docs),
  );
}
