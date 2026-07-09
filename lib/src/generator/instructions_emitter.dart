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
    ]);
  }
}
