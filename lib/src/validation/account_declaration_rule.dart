import '../idl.dart';
import 'discriminator_rule.dart';
import 'validation_issue.dart';

/// Validates top-level account declarations and their discriminator metadata.
final class AccountDeclarationValidationRule {
  /// Creates an account declaration validation rule.
  const AccountDeclarationValidationRule({
    this.discriminatorRule = const DiscriminatorValidationRule(),
  });

  /// Rule responsible for discriminator shape validation.
  final DiscriminatorValidationRule discriminatorRule;

  /// Validates account declarations against known type [definitions].
  void validate(
    IdlProgram program,
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    for (final account in program.accounts) {
      if (!definitions.containsKey(account.name)) {
        issue(
          'IDL_ACCOUNT_TYPE_UNDEFINED',
          'Account type "${account.name}" is not defined.',
          account.sourcePath,
        );
      }
      final accountType = definitions[account.name];
      if (accountType != null &&
          (accountType.generics.isNotEmpty ||
              accountType.constGenerics.isNotEmpty)) {
        issue(
          'IDL_ACCOUNT_GENERIC',
          'Account type "${account.name}" must be fully concrete.',
          account.sourcePath,
        );
      }
      discriminatorRule.validate(
        account.discriminator,
        account.sourcePath,
        issue,
      );
      if (account.discriminator.every((byte) => byte == 0)) {
        issue(
          'IDL_ACCOUNT_DISCRIMINATOR_ZERO',
          'An account discriminator cannot be all zero.',
          '${account.sourcePath}.discriminator',
        );
      }
    }
  }
}
