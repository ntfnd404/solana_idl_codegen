import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../../idl_path_matcher.dart';
import '../account_leaf.dart';
import '../section_emitter.dart';
import 'initial_resolution_emitter.dart';
import 'resolution_failure_emitter.dart';
import 'resolution_loop_emitter.dart';

/// Emits the procedural body of a generated instruction account resolver.
final class InstructionResolveBodyEmitter extends SectionEmitter {
  /// Creates a resolve-body emitter for [context].
  const InstructionResolveBodyEmitter(super.context);

  /// This helper emits method bodies only, not top-level declarations.
  @override
  List<Spec> emit() => const [];

  /// Emits the body of the generated `resolve` method.
  Code emitBody(
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    String accountsType,
  ) {
    final out = StringBuffer()
      ..writeln('final causes = <${type('account_resolution_cause')}>[];');
    if (_hasAccountDataSeeds(leaves)) {
      out.writeln(
        '    final seedAccountCache = <${type('address')}, Future<${type('account_snapshot')}?>>{};',
      );
    }
    InitialResolutionEmitter(context).emitInitialResolution(out, leaves);
    ResolutionLoopEmitter(context).emitResolutionLoop(out, instruction, leaves);
    ResolutionFailureEmitter(context).emitRequiredChecks(out, leaves);
    _emitReturn(out, leaves, accountsType);
    return Code(out.toString());
  }

  void _emitReturn(
    StringBuffer out,
    List<AccountLeaf> leaves,
    String accountsType,
  ) {
    out
      ..writeln('    if (causes.isNotEmpty) {')
      ..writeln('      throw ${type('account_resolution_exception')}(causes);')
      ..writeln('    }')
      ..writeln('    return $accountsType(');
    for (final leaf in leaves) {
      out.writeln(
        '      ${member(leaf.path)}: ${member(leaf.path)}${leaf.item.optional ? '' : '!'},',
      );
    }
    out.writeln(');');
  }

  bool _hasAccountDataSeeds(List<AccountLeaf> leaves) {
    for (final leaf in leaves) {
      for (final seed in leaf.item.seeds.whereType<IdlPathSeed>()) {
        if (seed.kind != 'account') continue;
        if (!leaves.any(
          (candidate) =>
              IdlPathMatcher.pathsMatch(candidate.wirePath, seed.path),
        )) {
          return true;
        }
      }
    }
    return false;
  }
}
