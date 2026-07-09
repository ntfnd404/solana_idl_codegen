import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits the generated immutable account metadata value object.
final class AccountMetaSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const AccountMetaSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[_accountMeta(type('account_meta'))];

  Class _accountMeta(String name) {
    final address = type('address');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add(
          '/// Immutable account metadata for one instruction account position.',
        )
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates account metadata.')
              ..optionalParameters.addAll([
                _thisParameter('address'),
                _thisParameter('isSigner'),
                _thisParameter('isWritable'),
              ]),
          ),
        )
        ..fields.addAll([
          _finalField('address', address, '/// Account address.'),
          _finalField(
            'isSigner',
            'bool',
            '/// Whether the transaction requires this account to sign.',
          ),
          _finalField(
            'isWritable',
            'bool',
            '/// Whether the instruction may write this account.',
          ),
        ]),
    );
  }

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );

  Field _finalField(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add(docs),
  );
}
