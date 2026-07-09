import 'package:code_builder/code_builder.dart';

import 'error_value_emitter.dart';
import 'program_exception_model_emitter.dart';
import 'section_emitter.dart';

/// Coordinates generated typed error values and exception classes.
final class ErrorModelEmitter extends SectionEmitter {
  /// Creates an error-model emitter for [context].
  const ErrorModelEmitter(super.context);

  /// Emits typed error model declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    ...ErrorValueEmitter(context).emit(),
    ...ProgramExceptionModelEmitter(context).emit(),
  ]);
}
