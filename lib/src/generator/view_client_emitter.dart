import 'package:code_builder/code_builder.dart';

import 'generated_feature_plan.dart';
import 'section_emitter.dart';
import 'types/type_mapping.dart';

/// Emits the generated read-only view simulation client.
final class ViewClientEmitter extends SectionEmitter {
  /// Creates a view-client emitter for [context].
  const ViewClientEmitter(super.context);

  /// Emits the view client declaration.
  @override
  List<Spec> emit() => [_viewClient()];

  Class _viewClient() {
    final mapping = DartTypeMapping(context);
    final views = context.program.instructions.where(isViewInstruction);
    return Class(
      (builder) => builder
        ..name = type('view_client')
        ..modifier = ClassModifier.final$
        ..docs.add('/// Typed read-only instruction simulation client.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add(
                '/// Creates a view client from a simulation capability.',
              )
              ..requiredParameters.add(
                Parameter(
                  (builder) => builder
                    ..name = 'simulator'
                    ..toThis = true,
                ),
              ),
          ),
        )
        ..fields.add(
          Field(
            (builder) => builder
              ..name = 'simulator'
              ..type = refer(type('transaction_simulator'))
              ..modifier = FieldModifier.final$
              ..docs.add('/// Single-instruction simulation capability.'),
          ),
        )
        ..methods.addAll(
          views.map((instruction) {
            final returnType = instruction.returns!;
            final codec = mapping.codecForType(returnType);
            return Method(
              (builder) => builder
                ..name = member(instruction.name)
                ..returns = refer('Future<${mapping.dartType(returnType)}>')
                ..modifier = MethodModifier.async
                ..docs.add(
                  '/// Simulates `${instruction.name}` and decodes exact return data.',
                )
                ..requiredParameters.add(
                  Parameter(
                    (builder) => builder
                      ..name = 'request'
                      ..type = refer(context.helpers(instruction).request),
                  ),
                )
                ..body = Code('''
final result = await simulator.simulate(request.instruction());
if (result.failure != null) {
  throw ${type('view_exception')}(code: 'VIEW_SIMULATION_FAILED', message: 'View simulation failed: \${result.failure!.message}');
}
final owner = result.returnProgramAddress;
final data = result.returnData;
if (owner != ${type('program')}.programAddress) {
  throw const ${type('view_exception')}(code: 'VIEW_PROGRAM_MISMATCH', message: 'View return program mismatch.');
}
if (data == null) {
  throw const ${type('view_exception')}(code: 'VIEW_RETURN_DATA_MISSING', message: 'View did not return data.');
}
return $codec.decodeExact(data);'''),
            );
          }),
        ),
    );
  }
}
