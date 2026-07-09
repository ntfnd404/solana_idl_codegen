import 'package:code_builder/code_builder.dart';

import '../../account_dependency_graph.dart';
import '../../idl.dart';
import '../account_leaf.dart';
import '../section_emitter.dart';
import 'pda_seed_emitter.dart';

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
    _emitInitialResolution(out, leaves);
    _emitPdaAndRelations(out, instruction, leaves);
    _emitRequiredChecks(out, leaves);
    _emitReturn(out, leaves, accountsType);
    return Code(out.toString());
  }

  void _emitInitialResolution(StringBuffer out, List<AccountLeaf> leaves) {
    for (final leaf in leaves) {
      final local = member(leaf.path);
      final item = leaf.item;
      out
        ..writeln('    ${type('address')}? $local;')
        ..writeln('    switch (overrides.$local) {')
        ..writeln('      case ${type('use_account_override')}(:final address):')
        ..writeln('        $local = address;')
        ..writeln('      case ${type('absent_account_override')}():');
      if (item.optional) {
        out.writeln('        $local = null;');
      } else {
        out.writeln(
          "        causes.add(const ${type('account_resolution_cause')}(path: '${escape(leaf.wirePath)}', code: 'RESOLUTION_REQUIRED_ABSENT', message: 'Required account cannot be absent.'));",
        );
      }
      out.writeln('      case ${type('inherit_account_override')}():');
      if (item.address != null) {
        out.writeln(
          "        $local = ${type('address')}.fromBase58('${escape(item.address!)}');",
        );
      } else if (item.seeds.isEmpty && item.relations.isEmpty) {
        out
          ..writeln(
            "        if (context.identityAccountPaths.contains('${escape(leaf.wirePath)}') && context.identity != null) {",
          )
          ..writeln('          $local = context.identity;')
          ..writeln('        }');
      }
      out.writeln('    }');
    }
  }

  void _emitPdaAndRelations(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
  ) {
    var generatedSeedId = 0;
    for (final leaf in _resolutionOrder(instruction, leaves)) {
      final item = leaf.item;
      if (item.seeds.isNotEmpty) {
        generatedSeedId = _emitPdaResolution(
          out,
          instruction,
          leaves,
          leaf,
          generatedSeedId,
        );
      }
      if (item.relations.isNotEmpty) {
        _emitRelationResolution(out, leaves, leaf);
      }
    }
  }

  int _emitPdaResolution(
    StringBuffer out,
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
    AccountLeaf leaf,
    int generatedSeedId,
  ) {
    final local = member(leaf.path);
    final item = leaf.item;
    out
      ..writeln('    if ($local == null) {')
      ..writeln('      final deriver = context.pdaDeriver;')
      ..writeln('      if (deriver != null) {')
      ..writeln('        final seeds = <Uint8List>[];');
    var nextSeedId = generatedSeedId;
    for (var index = 0; index < item.seeds.length; index++) {
      _seedEmitter.emitSeed(
        out,
        instruction,
        leaves,
        item.seeds[index],
        nextSeedId++,
        '        ',
      );
    }
    final programExpression = _seedEmitter.pdaProgramExpression(
      item.pdaProgram,
      instruction,
      leaves,
    );
    out
      ..writeln('        for (var index = 0; index < seeds.length; index++) {')
      ..writeln('          if (seeds[index].length > 32) {')
      ..writeln(
        "            throw ${type('pda_exception')}(code: 'PDA_SEED_LENGTH', message: 'A PDA seed cannot exceed 32 bytes.', seedIndex: index);",
      )
      ..writeln('          }')
      ..writeln('        }')
      ..writeln(
        '        final derived = await deriver.derive(programAddress: $programExpression, seeds: seeds);',
      )
      ..writeln('        $local = derived.address;')
      ..writeln('      }')
      ..writeln('    }');
    return nextSeedId;
  }

  void _emitRelationResolution(
    StringBuffer out,
    List<AccountLeaf> leaves,
    AccountLeaf leaf,
  ) {
    final local = member(leaf.path);
    out
      ..writeln('    if ($local == null) {')
      ..writeln('      final relationResolver = context.relationResolver;')
      ..writeln('      if (relationResolver != null) {');
    for (final relation in leaf.item.relations) {
      out
        ..writeln('        $local ??= await relationResolver.resolveRelation(')
        ..writeln("          accountPath: '${escape(leaf.wirePath)}',")
        ..writeln("          relationPath: '${escape(relation)}',")
        ..writeln('          resolvedAccounts: {');
      for (final candidate in leaves) {
        out.writeln(
          "            if (${member(candidate.path)} != null) '${escape(candidate.wirePath)}': ${member(candidate.path)}!,",
        );
      }
      out
        ..writeln('          },')
        ..writeln('        );');
    }
    out
      ..writeln('      }')
      ..writeln('    }');
  }

  void _emitRequiredChecks(StringBuffer out, List<AccountLeaf> leaves) {
    for (final leaf in leaves.where((item) => !item.item.optional)) {
      final local = member(leaf.path);
      out
        ..writeln('    if ($local == null) {')
        ..writeln(
          "      causes.add(const ${type('account_resolution_cause')}(path: '${escape(leaf.wirePath)}', code: 'RESOLUTION_UNRESOLVED', message: 'No override, fixed address, allowed identity, PDA, or relation resolved this account.'));",
        )
        ..writeln('    }');
    }
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

  List<AccountLeaf> _resolutionOrder(
    IdlInstruction instruction,
    List<AccountLeaf> leaves,
  ) {
    final graph = AccountDependencyGraph.fromInstruction(instruction);
    final byPath = {for (final leaf in leaves) leaf.wirePath: leaf};
    return [for (final path in graph.topologicalOrder()) ?byPath[path]];
  }

  bool _hasAccountDataSeeds(List<AccountLeaf> leaves) {
    for (final leaf in leaves) {
      for (final seed in leaf.item.seeds.whereType<IdlPathSeed>()) {
        if (seed.kind != 'account') continue;
        if (!leaves.any((candidate) => candidate.wirePath == seed.path)) {
          return true;
        }
      }
    }
    return false;
  }

  PdaSeedEmitter get _seedEmitter => PdaSeedEmitter(context);
}
