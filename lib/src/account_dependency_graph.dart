import 'intermediate_representation/instruction.dart';

/// Canonical dependency graph for one instruction account tree.
final class AccountDependencyGraph {
  const AccountDependencyGraph._(this.accounts, this.dependencies);

  /// Builds PDA and relation dependencies using canonical dotted wire paths.
  factory AccountDependencyGraph.fromInstruction(IdlInstruction instruction) {
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
        _longestAccountPath(raw, accounts.keys);

    final dependencies = <String, Set<String>>{
      for (final account in accounts.keys) account: <String>{},
    };
    for (final entry in accounts.entries) {
      for (final seed in entry.value.seeds.whereType<IdlPathSeed>()) {
        if (seed.kind != 'account') continue;
        final dependency = dependencyPath(seed.path);
        if (dependency != null) dependencies[entry.key]!.add(dependency);
      }
      for (final relation in entry.value.relations) {
        final dependency = dependencyPath(relation);
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
    return _longestAccountPath(raw, accounts.keys);
  }

  static String? _longestAccountPath(String raw, Iterable<String> candidates) {
    String? result;
    for (final candidate in candidates) {
      if ((_pathMatches(raw, candidate) || _pathHasPrefix(raw, candidate)) &&
          (result == null || candidate.length > result.length)) {
        result = candidate;
      }
    }
    return result;
  }

  static bool _pathMatches(String raw, String candidate) =>
      _canonicalPath(raw) == _canonicalPath(candidate);

  static bool _pathHasPrefix(String raw, String candidate) {
    final rawSegments = raw.split('.');
    final candidateSegments = candidate.split('.');
    if (rawSegments.length <= candidateSegments.length) return false;
    for (var index = 0; index < candidateSegments.length; index++) {
      if (_canonicalSegment(rawSegments[index]) !=
          _canonicalSegment(candidateSegments[index])) {
        return false;
      }
    }
    return true;
  }

  static String _canonicalPath(String path) =>
      path.split('.').map(_canonicalSegment).join('.');

  static String _canonicalSegment(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
      .toLowerCase();

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

  /// Stable dependency-first ordering.
  List<String> topologicalOrder() {
    final result = <String>[];
    final visited = <String>{};
    void visit(String node) {
      if (!visited.add(node)) return;
      for (final dependency in dependencies[node] ?? const <String>{}) {
        visit(dependency);
      }
      result.add(node);
    }

    for (final node in accounts.keys) {
      visit(node);
    }
    return List.unmodifiable(result);
  }
}
