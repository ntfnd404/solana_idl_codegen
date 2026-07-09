import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../account_leaf.dart';
import '../section_emitter.dart';

/// Emits typed account override classes for generated instruction resolvers.
final class AccountOverridesEmitter extends SectionEmitter {
  /// Creates an overrides emitter for [context].
  const AccountOverridesEmitter(super.context);

  /// This helper emits instruction-specific classes through [emitClass].
  @override
  List<Spec> emit() => const [];

  /// Emits the account overrides class for [instruction].
  Class emitClass(
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    String name,
  ) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Typed account overrides for `${instruction.name}`.')
      ..constructors.add(
        Constructor((builder) {
          builder
            ..constant = true
            ..docs.add(
              leaves.isEmpty
                  ? '/// Creates an empty override set.'
                  : '/// Creates override states; every field inherits by default.',
            );
          for (final leaf in leaves) {
            builder.optionalParameters.add(
              Parameter(
                (builder) => builder
                  ..name = member(leaf.path)
                  ..named = true
                  ..toThis = true
                  ..defaultTo = Code(
                    "const ${type('account_override')}.inherit()",
                  ),
              ),
            );
          }
        }),
      )
      ..fields.addAll([
        for (final leaf in leaves)
          Field(
            (builder) => builder
              ..name = member(leaf.path)
              ..type = refer(type('account_override'))
              ..modifier = FieldModifier.final$
              ..docs.add('/// Override for `${leaf.path}`.'),
          ),
      ]),
  );
}
