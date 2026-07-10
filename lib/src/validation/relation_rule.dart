import '../idl.dart';
import '../idl_path_matcher.dart';
import 'validation_issue.dart';

/// Validates Anchor account relation targets.
final class RelationValidationRule {
  /// Creates a stateless relation validation rule.
  const RelationValidationRule();

  /// Reports an issue for every relation target missing from [leafPaths].
  void validate(
    List<IdlInstructionAccount> accounts,
    Set<String> leafPaths,
    ValidationIssue issue,
  ) {
    for (final item in _accountItems(accounts)) {
      for (final relation in item.relations) {
        if (!_containsPath(leafPaths, relation)) {
          issue(
            'IDL_RELATION_TARGET',
            'Relation target "$relation" is undefined.',
            item.sourcePath,
          );
        }
      }
    }
  }

  Iterable<IdlAccountItem> _accountItems(
    List<IdlInstructionAccount> accounts,
  ) sync* {
    for (final account in accounts) {
      switch (account) {
        case IdlAccountItem():
          yield account;
        case IdlAccountGroup(:final accounts):
          yield* _accountItems(accounts);
      }
    }
  }

  bool _containsPath(Set<String> paths, String relation) {
    for (final path in paths) {
      if (IdlPathMatcher.pathsMatch(path, relation)) return true;
    }
    return false;
  }
}
