import '../idl.dart';
import 'validation_issue.dart';

/// Validates source-level declaration uniqueness.
final class UniquenessValidationRule {
  /// Creates the stateless uniqueness rule.
  const UniquenessValidationRule();

  /// Rejects repeated source names in one namespace.
  void names(
    Iterable<(String, String)> values,
    String kind,
    ValidationIssue issue,
  ) {
    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value.$1)) {
        issue(
          'IDL_DUPLICATE_NAME',
          'Duplicate $kind name "${value.$1}".',
          value.$2,
        );
      }
    }
  }

  /// Rejects repeated numeric custom error codes.
  void errorCodes(List<IdlErrorDefinition> errors, ValidationIssue issue) {
    final codes = <int>{};
    for (final error in errors) {
      if (!codes.add(error.code)) {
        issue(
          'IDL_ERROR_CODE_DUPLICATE',
          'Duplicate error code ${error.code}.',
          error.sourcePath,
        );
      }
    }
  }
}
