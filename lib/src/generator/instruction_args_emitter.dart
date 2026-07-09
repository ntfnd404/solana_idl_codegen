import 'package:code_builder/code_builder.dart';

import '../idl.dart';
import 'section_emitter.dart';
import 'types/type_mapping.dart';
import 'types/value_semantics.dart';

/// Emits immutable instruction argument classes and their Borsh codecs.
final class InstructionArgsEmitter extends SectionEmitter {
  /// Creates an instruction-args emitter for [context].
  const InstructionArgsEmitter(super.context);

  /// Emits argument classes for all instructions.
  @override
  List<Spec> emit() => List.unmodifiable([
    for (final instruction in context.program.instructions)
      emitClass(instruction),
  ]);

  /// Emits the immutable args class for [instruction].
  Class emitClass(IdlInstruction instruction) {
    final name = context.helpers(instruction).args;
    final semantics = GeneratedValueSemantics(context);
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.addAll([
          '/// Immutable arguments for `${instruction.name}`.',
          for (final line in instruction.docs) '/// $line',
        ])
        ..constructors.add(
          Constructor((builder) {
            builder
              ..constant = instruction.arguments.isEmpty
              ..docs.add(
                instruction.arguments.isEmpty
                    ? '/// Creates empty instruction arguments.'
                    : '/// Creates instruction arguments.',
              );
            for (final argument in instruction.arguments) {
              final argumentName = context.fieldMember(
                instruction.arguments,
                argument,
              );
              builder.optionalParameters.add(
                Parameter(
                  (builder) => builder
                    ..name = argumentName
                    ..type = refer(_constructorType(argument.type))
                    ..named = true
                    ..required = true,
                ),
              );
              builder.initializers.add(
                Code(
                  '$argumentName = ${semantics.immutableExpression(argument.type, argumentName)}',
                ),
              );
            }
          }),
        )
        ..fields.addAll(
          instruction.arguments.map(
            (argument) => Field(
              (builder) => builder
                ..name = context.fieldMember(instruction.arguments, argument)
                ..type = refer(_mapping.dartType(argument.type))
                ..modifier = FieldModifier.final$
                ..docs.add('/// IDL argument `${argument.name}`.'),
            ),
          ),
        )
        ..fields.add(
          Field(
            (builder) => builder
              ..name = 'codec'
              ..type = refer('${type('borsh_codec')}<$name>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// Borsh codec for these arguments.')
              ..assignment = Code(_argumentsCodec(instruction, name)),
          ),
        ),
    );
  }

  String _argumentsCodec(IdlInstruction instruction, String name) {
    final out = StringBuffer()
      ..writeln('${type('functional_borsh_codec')}<$name>(')
      ..writeln('  (reader) => $name(');
    for (final argument in instruction.arguments) {
      out.writeln(
        "    ${context.fieldMember(instruction.arguments, argument)}: reader.field('${escape(argument.name)}', () => ${_mapping.read(argument.type, 'reader')}),",
      );
    }
    out
      ..writeln('  ),')
      ..writeln('  (writer, value) {');
    for (final argument in instruction.arguments) {
      out.writeln(
        '    ${_mapping.write(argument.type, 'writer', 'value.${context.fieldMember(instruction.arguments, argument)}')}',
      );
    }
    out
      ..writeln('  },')
      ..write(')');
    return out.toString();
  }

  String _constructorType(IdlType value) => switch (value) {
    IdlPrimitiveType(name: 'bytes') => 'List<int>',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) => 'List<${_mapping.dartType(inner)}>',
    _ => _mapping.dartType(value),
  };

  DartTypeMapping get _mapping => DartTypeMapping(context);
}
