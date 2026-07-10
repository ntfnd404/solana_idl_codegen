import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../account_leaf.dart';
import '../account_leaf_flattener.dart';
import '../section_emitter.dart';
import 'account_overrides_emitter.dart';
import 'instruction_resolve_body_emitter.dart';

/// Emits per-instruction overrides, resolvers, and prepare methods.
final class InstructionResolverFragment extends SectionEmitter {
  /// Creates an instruction resolver fragment for [context].
  const InstructionResolverFragment(super.context);

  /// Emits resolution declarations for all program instructions.
  @override
  List<Spec> emit() {
    final result = <Spec>[];
    for (final instruction in context.program.instructions) {
      result.addAll(_instructionSpecs(instruction));
    }
    return List<Spec>.unmodifiable(result);
  }

  List<Spec> _instructionSpecs(IdlInstruction instruction) {
    final leaves = flatten(instruction.accounts);
    final helpers = context.helpers(instruction);
    final overrides = helpers.accountOverrides;
    final resolver = helpers.accountResolver;
    final accounts = helpers.accounts;
    final args = helpers.args;
    return <Spec>[
      AccountOverridesEmitter(
        context,
      ).emitClass(instruction, leaves, overrides),
      Class(
        (builder) => builder
          ..name = resolver
          ..modifier = ClassModifier.final$
          ..docs.add(
            '/// Asynchronous resolver for `${instruction.name}` accounts.',
          )
          ..constructors.add(
            Constructor(
              (builder) => builder
                ..constant = true
                ..docs.add('/// Creates a resolver from injected capabilities.')
                ..requiredParameters.add(
                  Parameter(
                    (builder) => builder
                      ..name = 'context'
                      ..toThis = true,
                  ),
                ),
            ),
          )
          ..fields.add(
            Field(
              (builder) => builder
                ..name = 'context'
                ..type = refer(type('resolution_context'))
                ..modifier = FieldModifier.final$
                ..docs.add('/// Resolution dependencies.'),
            ),
          )
          ..methods.addAll([
            Method(
              (builder) => builder
                ..name = 'resolve'
                ..returns = refer('Future<$accounts>')
                ..modifier = MethodModifier.async
                ..docs.add(
                  '/// Resolves overrides, fixed addresses, identity, PDA, and relations.',
                )
                ..docs.add(
                  '/// Precedence is use override, absent override, fixed address, identity, PDA, then relation.',
                )
                ..docs.add(
                  '/// Relation/PDA cycles must be broken by use overrides, identity, or a relation resolver.',
                )
                ..optionalParameters.addAll([
                  _requiredNamed('args', args),
                  Parameter(
                    (builder) => builder
                      ..name = 'overrides'
                      ..type = refer(overrides)
                      ..named = true
                      ..defaultTo = Code('const $overrides()'),
                  ),
                ])
                ..body = InstructionResolveBodyEmitter(
                  context,
                ).emitBody(instruction, leaves, accounts),
            ),
            Method(
              (builder) => builder
                ..name = 'prepare'
                ..returns = refer('Future<${helpers.request}>')
                ..modifier = MethodModifier.async
                ..docs.add(
                  '/// Resolves accounts and constructs an immutable instruction request.',
                )
                ..optionalParameters.addAll([
                  _requiredNamed('args', args),
                  Parameter(
                    (builder) => builder
                      ..name = 'overrides'
                      ..type = refer(overrides)
                      ..named = true
                      ..defaultTo = Code('const $overrides()'),
                  ),
                  Parameter(
                    (builder) => builder
                      ..name = 'remainingAccounts'
                      ..type = refer('List<${type('account_meta')}>')
                      ..named = true
                      ..defaultTo = const Code('const []'),
                  ),
                ])
                ..lambda = true
                ..body = Code('''
${helpers.request}(
  args: args,
  accounts: await resolve(args: args, overrides: overrides),
  remainingAccounts: remainingAccounts,
)'''),
            ),
          ]),
      ),
    ];
  }

  Parameter _requiredNamed(String name, String typeName) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(typeName)
      ..named = true
      ..required = true,
  );

  /// Flattens nested account groups using instruction-emission semantics.
  List<AccountLeaf> flatten(
    List<IdlInstructionAccount> nodes, [
    String prefix = '',
  ]) => const AccountLeafFlattener().flatten(nodes, prefix);
}
