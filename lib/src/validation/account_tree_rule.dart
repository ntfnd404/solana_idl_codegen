import '../idl.dart';
import '../idl_path_matcher.dart';
import 'validation_issue.dart';

/// Result of validating and indexing a nested instruction-account tree.
final class AccountTreeValidationResult {
  /// Creates an immutable account-tree validation result.
  AccountTreeValidationResult({
    required Set<String> paths,
    required Set<String> leaves,
    required Map<String, IdlAccountItem> leafItems,
  }) : paths = Set.unmodifiable(paths),
       leaves = Set.unmodifiable(leaves),
       leafItems = Map.unmodifiable(leafItems);

  /// All nested account paths, including account groups.
  final Set<String> paths;

  /// Leaf account paths only.
  final Set<String> leaves;

  /// Leaf account declarations keyed by canonical nested path.
  final Map<String, IdlAccountItem> leafItems;
}

/// Validates nested account path uniqueness and indexes leaf accounts.
final class AccountTreeValidationRule {
  /// Creates a stateless account-tree validation rule.
  const AccountTreeValidationRule();

  /// Validates [accounts] and returns path indexes for downstream rules.
  AccountTreeValidationResult validate(
    List<IdlInstructionAccount> accounts,
    ValidationIssue issue,
  ) {
    final paths = <String>{};
    final leaves = <String>{};
    final leafItems = <String, IdlAccountItem>{};
    final canonicalPaths = <String, String>{};
    _visit(accounts, '', paths, leaves, leafItems, canonicalPaths, issue);
    return AccountTreeValidationResult(
      paths: paths,
      leaves: leaves,
      leafItems: leafItems,
    );
  }

  void _visit(
    List<IdlInstructionAccount> nodes,
    String prefix,
    Set<String> paths,
    Set<String> leaves,
    Map<String, IdlAccountItem> leafItems,
    Map<String, String> canonicalPaths,
    ValidationIssue issue,
  ) {
    final siblings = <String>{};
    for (final node in nodes) {
      if (!siblings.add(node.name)) {
        issue(
          'IDL_ACCOUNT_DUPLICATE',
          'Duplicate nested account name "${node.name}".',
          node.sourcePath,
        );
      }
      final path = prefix.isEmpty ? node.name : '$prefix.${node.name}';
      if (!paths.add(path)) {
        issue(
          'IDL_ACCOUNT_PATH_COLLISION',
          'Nested account path "$path" collides.',
          node.sourcePath,
        );
      }
      final canonicalPath = IdlPathMatcher.canonicalPath(path);
      final existingPath = canonicalPaths[canonicalPath];
      if (existingPath == null) {
        canonicalPaths[canonicalPath] = path;
      } else if (existingPath != path) {
        issue(
          'IDL_ACCOUNT_PATH_COLLISION',
          'Nested account path "$path" canonically collides with "$existingPath".',
          node.sourcePath,
        );
      }
      switch (node) {
        case IdlAccountGroup(:final accounts):
          _visit(
            accounts,
            path,
            paths,
            leaves,
            leafItems,
            canonicalPaths,
            issue,
          );
        case IdlAccountItem():
          leaves.add(path);
          leafItems[path] = node;
      }
    }
  }
}
