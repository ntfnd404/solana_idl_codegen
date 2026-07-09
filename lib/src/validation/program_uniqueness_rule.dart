import '../idl.dart';
import 'uniqueness_rule.dart';
import 'validation_issue.dart';

/// Validates duplicate top-level source names and error codes.
final class ProgramUniquenessValidationRule {
  /// Creates a program uniqueness validation rule.
  const ProgramUniquenessValidationRule({
    this.uniquenessRule = const UniquenessValidationRule(),
  });

  /// Rule responsible for duplicate name and code checks.
  final UniquenessValidationRule uniquenessRule;

  /// Validates all top-level uniqueness constraints in [program].
  void validate(IdlProgram program, ValidationIssue issue) {
    uniquenessRule.names(
      program.instructions.map((item) => (item.name, item.sourcePath)),
      'instruction',
      issue,
    );
    uniquenessRule.names(
      program.types.map((item) => (item.name, item.sourcePath)),
      'type',
      issue,
    );
    uniquenessRule.names(
      program.accounts.map((item) => (item.name, item.sourcePath)),
      'account',
      issue,
    );
    uniquenessRule.names(
      program.events.map((item) => (item.name, item.sourcePath)),
      'event',
      issue,
    );
    uniquenessRule.names(
      program.errors.map((item) => (item.name, item.sourcePath)),
      'error',
      issue,
    );
    uniquenessRule.names(
      program.constants.map((item) => (item.name, item.sourcePath)),
      'constant',
      issue,
    );
    uniquenessRule.errorCodes(program.errors, issue);
  }
}
