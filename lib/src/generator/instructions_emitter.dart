import 'package:code_builder/code_builder.dart';

import 'instruction_accounts_emitter.dart';
import 'instruction_args_emitter.dart';
import 'instruction_request_emitter.dart';
import 'section_emitter.dart';

/// Emits typed arguments, resolved accounts, and instruction requests.
final class InstructionsEmitter extends SectionEmitter {
  /// Creates an instruction emitter for [context].
  const InstructionsEmitter(super.context);

  /// Emits instruction declarations in source order.
  @override
  List<Spec> emit() {
    final args = InstructionArgsEmitter(context);
    final accounts = InstructionAccountsEmitter(context);
    final requests = InstructionRequestEmitter(context);
    return List.unmodifiable([
      for (final instruction in context.program.instructions) ...[
        args.emitClass(instruction),
        accounts.emitClass(instruction),
        requests.emitClass(instruction),
      ],
      _instructionRegistry(),
    ]);
  }

  Class _instructionRegistry() {
    final metadata = type('instruction_metadata');
    return Class(
      (builder) => builder
        ..name = type('instruction_registry')
        ..abstract = true
        ..modifier = ClassModifier.final$
        ..docs.add(
          '/// Program-level registry of generated instruction metadata.',
        )
        ..fields.addAll([
          Field(
            (builder) => builder
              ..name = 'instructions'
              ..type = refer('List<$metadata>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add(
                '/// Instructions declared by the IDL in source order.',
              )
              ..assignment = Code(
                'List.unmodifiable(<$metadata>['
                '${context.program.instructions.map((instruction) => '${context.helpers(instruction).request}.metadata').join(', ')}'
                '])',
              ),
          ),
          Field(
            (builder) => builder
              ..name = 'byName'
              ..type = refer('Map<String, $metadata>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add(
                '/// Instruction metadata indexed by IDL instruction name.',
              )
              ..assignment = const Code(
                'Map.unmodifiable({for (final instruction in instructions) '
                'instruction.name: instruction})',
              ),
          ),
        ]),
    );
  }
}
