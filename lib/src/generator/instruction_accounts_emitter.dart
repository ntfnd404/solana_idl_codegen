import 'package:code_builder/code_builder.dart';

import '../idl.dart';
import 'account_leaf_flattener.dart';
import 'section_emitter.dart';

/// Emits fully resolved instruction account model classes.
final class InstructionAccountsEmitter extends SectionEmitter {
  /// Creates an instruction accounts emitter for [context].
  const InstructionAccountsEmitter(super.context);

  /// Emits resolved account classes for all instructions.
  @override
  List<Spec> emit() => List.unmodifiable([
    for (final instruction in context.program.instructions)
      emitClass(instruction),
  ]);

  /// Emits the fully resolved account class for [instruction].
  Class emitClass(IdlInstruction instruction) {
    final name = context.helpers(instruction).accounts;
    final leaves = const AccountLeafFlattener().flatten(instruction.accounts);
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add('/// Fully resolved accounts for `${instruction.name}`.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add(
                leaves.isEmpty
                    ? '/// Creates empty resolved instruction accounts.'
                    : '/// Creates resolved instruction accounts.',
              )
              ..optionalParameters.addAll(
                leaves.map(
                  (leaf) => Parameter(
                    (builder) => builder
                      ..name = member(leaf.path)
                      ..toThis = true
                      ..named = true
                      ..required = true,
                  ),
                ),
              ),
          ),
        )
        ..fields.addAll(
          leaves.map(
            (leaf) => Field(
              (builder) => builder
                ..name = member(leaf.path)
                ..type = refer(
                  '${type('address')}${leaf.item.optional ? '?' : ''}',
                )
                ..modifier = FieldModifier.final$
                ..docs.add('/// Resolved account `${leaf.path}`.'),
            ),
          ),
        ),
    );
  }
}
