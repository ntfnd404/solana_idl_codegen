import 'package:code_builder/code_builder.dart';

import 'error_model_emitter.dart';
import 'program_error_parser_emitter.dart';
import 'section_emitter.dart';

/// Emits typed Anchor program errors and non-throwing log parsing.
final class ErrorsEmitter extends SectionEmitter {
  /// Creates an error emitter for [context].
  const ErrorsEmitter(super.context);

  /// Emits error declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    ...ErrorModelEmitter(context).emit(),
    ...ProgramErrorParserEmitter(context).emit(),
  ]);
}
