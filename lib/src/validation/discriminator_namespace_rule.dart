import '../idl.dart';
import 'discriminator_rule.dart';
import 'validation_issue.dart';

/// Validates discriminator prefix ambiguity across program namespaces.
final class DiscriminatorNamespaceValidationRule {
  /// Creates a discriminator namespace validation rule.
  const DiscriminatorNamespaceValidationRule({
    this.discriminatorRule = const DiscriminatorValidationRule(),
  });

  /// Rule responsible for prefix ambiguity checks.
  final DiscriminatorValidationRule discriminatorRule;

  /// Validates discriminator prefixes for instructions, accounts, and events.
  void validate(IdlProgram program, ValidationIssue issue) {
    discriminatorRule.validatePrefixes(
      program.instructions
          .map((item) => (item.name, item.discriminator, item.sourcePath))
          .toList(),
      'instruction',
      issue,
    );
    discriminatorRule.validatePrefixes(
      program.accounts
          .map((item) => (item.name, item.discriminator, item.sourcePath))
          .toList(),
      'account',
      issue,
    );
    discriminatorRule.validatePrefixes(
      program.events
          .map((item) => (item.name, item.discriminator, item.sourcePath))
          .toList(),
      'event',
      issue,
    );
  }
}
