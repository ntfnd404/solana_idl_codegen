import '../idl.dart';
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
      if (_canonicalPath(path) == _canonicalPath(relation)) return true;
    }
    return false;
  }

  String _canonicalPath(String path) =>
      path.split('.').map(_canonicalSegment).join('.');

  String _canonicalSegment(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
      .toLowerCase();
}
