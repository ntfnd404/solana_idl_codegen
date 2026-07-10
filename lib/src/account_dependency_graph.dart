import 'idl_path_matcher.dart';
import 'intermediate_representation/instruction.dart';

/// Canonical dependency graph for one instruction account tree.
final class AccountDependencyGraph {
  const AccountDependencyGraph._(this.accounts, this.dependencies);

  /// Builds only PDA account-seed dependencies for validation.
  ///
  /// Relation edges are intentionally excluded because relation/PDA cycles can
  /// be valid when the application breaks them with runtime overrides.
  factory AccountDependencyGraph.pdaValidation(IdlInstruction instruction) =>
      AccountDependencyGraph._fromInstruction(instruction);

  factory AccountDependencyGraph._fromInstruction(IdlInstruction instruction) {
    final accounts = <String, IdlAccountItem>{};
    void flatten(List<IdlInstructionAccount> nodes, String prefix) {
      for (final node in nodes) {
        final wirePath = prefix.isEmpty ? node.name : '$prefix.${node.name}';
        switch (node) {
          case IdlAccountItem():
            accounts[wirePath] = node;
          case IdlAccountGroup(:final accounts):
            flatten(accounts, wirePath);
        }
      }
    }

    flatten(instruction.accounts, '');
    String? dependencyPath(String raw) =>
        IdlPathMatcher.longestPathPrefix(raw, accounts.keys);

    final dependencies = <String, Set<String>>{
      for (final account in accounts.keys) account: <String>{},
    };
    for (final entry in accounts.entries) {
      for (final seed in entry.value.seeds.whereType<IdlPathSeed>()) {
        if (seed.kind != 'account') continue;
        final dependency = dependencyPath(seed.path);
        if (dependency != null) dependencies[entry.key]!.add(dependency);
      }
    }
    return AccountDependencyGraph._(
      Map.unmodifiable(accounts),
      Map.unmodifiable({
        for (final entry in dependencies.entries)
          entry.key: Set.unmodifiable(entry.value),
      }),
    );
  }

  /// Account definitions indexed by canonical dotted wire path.
  final Map<String, IdlAccountItem> accounts;

  /// Direct dependencies indexed by canonical dotted wire path.
  final Map<String, Set<String>> dependencies;

  /// Resolves an account or account-field path to its longest account prefix.
  String? accountPathFor(String raw) {
    return IdlPathMatcher.longestPathPrefix(raw, accounts.keys);
  }

  /// First cycle in deterministic source order, or `null`.
  List<String>? findCycle() {
    final visiting = <String>[];
    final visited = <String>{};
    List<String>? visit(String node) {
      final active = visiting.indexOf(node);
      if (active >= 0) return [...visiting.sublist(active), node];
      if (!visited.add(node)) return null;
      visiting.add(node);
      for (final dependency in dependencies[node] ?? const <String>{}) {
        final cycle = visit(dependency);
        if (cycle != null) return cycle;
      }
      visiting.removeLast();
      return null;
    }

    for (final node in accounts.keys) {
      final cycle = visit(node);
      if (cycle != null) return cycle;
    }
    return null;
  }
}
