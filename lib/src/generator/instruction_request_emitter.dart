import 'package:code_builder/code_builder.dart';

import '../idl.dart';
import 'account_leaf_flattener.dart';
import 'section_emitter.dart';

/// Emits immutable instruction request classes and wire instruction builders.
final class InstructionRequestEmitter extends SectionEmitter {
  /// Creates an instruction request emitter for [context].
  const InstructionRequestEmitter(super.context);

  /// Emits request classes for all instructions.
  @override
  List<Spec> emit() => List.unmodifiable([
    for (final instruction in context.program.instructions)
      emitClass(instruction),
  ]);

  /// Emits the immutable request class for [instruction].
  Class emitClass(IdlInstruction instruction) {
    final helpers = context.helpers(instruction);
    final name = helpers.request;
    final args = helpers.args;
    final accounts = helpers.accounts;
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add('/// Immutable request for `${instruction.name}`.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..docs.add('/// Creates a prepared instruction request.')
              ..optionalParameters.addAll([
                for (final field in const ['args', 'accounts'])
                  Parameter(
                    (builder) => builder
                      ..name = field
                      ..toThis = true
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (builder) => builder
                    ..name = 'remainingAccounts'
                    ..type = refer('List<${type('account_meta')}>')
                    ..named = true
                    ..defaultTo = const Code('const []'),
                ),
              ])
              ..initializers.add(
                const Code(
                  'remainingAccounts = List.unmodifiable(remainingAccounts)',
                ),
              ),
          ),
        )
        ..fields.addAll([
          _field('args', args, 'Typed instruction arguments.'),
          _field('accounts', accounts, 'Fully resolved accounts.'),
          _field(
            'remainingAccounts',
            'List<${type('account_meta')}>',
            'Ordered remaining accounts. Duplicates are preserved.',
          ),
        ])
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'instruction'
              ..returns = refer(type('instruction'))
              ..docs.add('/// Builds the transport-neutral instruction.')
              ..body = Code(_instructionBody(instruction)),
          ),
        ),
    );
  }

  String _instructionBody(IdlInstruction instruction) {
    final out = StringBuffer()
      ..writeln('final writer = ${type('borsh_writer')}()')
      ..writeln('  ..writeBytes(${bytes(instruction.discriminator)});')
      ..writeln(
        '${context.helpers(instruction).args}.codec.write(writer, args);',
      )
      ..writeln('return ${type('instruction')}(')
      ..writeln('  programAddress: ${type('program')}.programAddress,')
      ..writeln('  accounts: [');
    for (final leaf in const AccountLeafFlattener().flatten(
      instruction.accounts,
    )) {
      final access = 'accounts.${member(leaf.path)}';
      out
        ..writeln('    ${type('account_meta')}(')
        ..writeln(
          '      address: ${leaf.item.optional ? '$access ?? ${type('program')}.programAddress' : access},',
        )
        ..writeln(
          '      isSigner: ${leaf.item.optional ? '$access == null ? false : ' : ''}${leaf.item.signer},',
        )
        ..writeln(
          '      isWritable: ${leaf.item.optional ? '$access == null ? false : ' : ''}${leaf.item.writable},',
        )
        ..writeln('    ),');
    }
    out
      ..writeln('    ...remainingAccounts,')
      ..writeln('  ],')
      ..writeln('  data: writer.takeBytes(),')
      ..write(');');
    return out.toString();
  }

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
