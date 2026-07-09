import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits the generated instruction construction client.
final class InstructionsClientEmitter extends SectionEmitter {
  /// Creates an instructions-client emitter for [context].
  const InstructionsClientEmitter(super.context);

  /// Emits the instruction client declaration.
  @override
  List<Spec> emit() => [_instructionsClient()];

  Class _instructionsClient() => Class(
    (builder) => builder
      ..name = type('instructions_client')
      ..modifier = ClassModifier.final$
      ..docs.add('/// Instruction construction facade.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a stateless instruction facade.'),
        ),
      )
      ..methods.addAll(
        context.program.instructions.map(
          (instruction) => Method(
            (builder) => builder
              ..name = member(instruction.name)
              ..returns = refer(type('instruction'))
              ..docs.add(
                '/// Builds `${instruction.name}` from a prepared request.',
              )
              ..requiredParameters.add(
                Parameter(
                  (builder) => builder
                    ..name = 'request'
                    ..type = refer(context.helpers(instruction).request),
                ),
              )
              ..lambda = true
              ..body = const Code('request.instruction()'),
          ),
        ),
      ),
  );
}
