import 'package:code_builder/code_builder.dart';

import '../../account_dependency_graph.dart';
import '../../idl.dart';
import '../account_leaf.dart';
import '../section_emitter.dart';
import 'pda_seed_emitter.dart';
import 'resolution_local_names.dart';

/// Emits PDA resolution attempts for generated account resolvers.
final class PdaResolutionEmitter extends SectionEmitter {
  /// Creates a PDA-resolution emitter for [context].
  const PdaResolutionEmitter(super.context);

  @override
  List<Spec> emit() => const [];

  /// Emits one PDA attempt and returns the next generated seed id.
  int emitPdaResolution(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    AccountLeaf leaf,
    int generatedSeedId,
    String indent,
  ) {
    final local = member(leaf.path);
    final suppressed = resolutionSuppressedMember(leaf, member);
    final item = leaf.item;
    final dependencies = _pdaAccountDependencies(instruction, leaves, item);
    final promotedAccountPaths = dependencies
        .map((dependency) => dependency.wirePath)
        .toSet();
    out
      ..writeln('${indent}if ($local == null && !$suppressed) {')
      ..writeln('$indent  final deriver = context.pdaDeriver;')
      ..writeln('$indent  if (deriver != null) {');
    final bodyIndent = dependencies.isEmpty ? '$indent    ' : '$indent      ';
    if (dependencies.isNotEmpty) {
      final dependencyCondition = dependencies
          .map((item) => '${member(item.path)} != null')
          .join(' && ');
      out.writeln('$indent    if ($dependencyCondition) {');
    }
    out.writeln('${bodyIndent}final seeds = <Uint8List>[];');
    var nextSeedId = generatedSeedId;
    for (var index = 0; index < item.seeds.length; index++) {
      _seedEmitter.emitSeed(
        out,
        instruction,
        leaves,
        item.seeds[index],
        nextSeedId++,
        bodyIndent,
        promotedAccountPaths: promotedAccountPaths,
      );
    }
    final programExpression = _seedEmitter.pdaProgramExpression(
      item.pdaProgram,
      instruction,
      leaves,
      promotedAccountPaths: promotedAccountPaths,
    );
    out
      ..writeln(
        '${bodyIndent}for (var index = 0; index < seeds.length; index++) {',
      )
      ..writeln('$bodyIndent  if (seeds[index].length > 32) {')
      ..writeln(
        "$bodyIndent    throw ${type('pda_exception')}(code: 'PDA_SEED_LENGTH', message: 'A PDA seed cannot exceed 32 bytes.', seedIndex: index);",
      )
      ..writeln('$bodyIndent  }')
      ..writeln('$bodyIndent}')
      ..writeln(
        '${bodyIndent}final derived = await deriver.derive(programAddress: $programExpression, seeds: seeds);',
      )
      ..writeln('$bodyIndent$local = derived.address;')
      ..writeln('${bodyIndent}progressed = true;');
    if (dependencies.isNotEmpty) {
      out.writeln('$indent    }');
    }
    out
      ..writeln('$indent  }')
      ..writeln('$indent}');
    return nextSeedId;
  }

  List<AccountLeaf> _pdaAccountDependencies(
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    IdlAccountItem item,
  ) {
    final graph = AccountDependencyGraph.pdaValidation(instruction);
    final byPath = {for (final leaf in leaves) leaf.wirePath: leaf};
    final result = <AccountLeaf>[];
    void addDependency(String path) {
      final dependency = graph.accountPathFor(path);
      final leaf = dependency == null ? null : byPath[dependency];
      if (leaf != null && !result.contains(leaf)) result.add(leaf);
    }

    for (final seed in item.seeds.whereType<IdlPathSeed>()) {
      if (seed.kind == 'account') addDependency(seed.path);
    }
    if (item.pdaProgram case final IdlPathSeed seed
        when seed.kind == 'account') {
      addDependency(seed.path);
    }
    return List.unmodifiable(result);
  }

  PdaSeedEmitter get _seedEmitter => PdaSeedEmitter(context);
}
