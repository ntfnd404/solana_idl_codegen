import '../idl.dart';
import 'account_rule.dart';
import 'address_rule.dart';
import 'discriminator_rule.dart';
import 'type_rule.dart';
import 'uniqueness_rule.dart';
import 'validation_issue.dart';

/// Validates instruction discriminators, arguments, accounts, and returns.
final class InstructionValidationRule {
  /// Creates an instruction validation rule.
  const InstructionValidationRule({
    this.accountRule = const AccountValidationRule(),
    this.addressRule = const AddressValidationRule(),
    this.discriminatorRule = const DiscriminatorValidationRule(),
    this.typeRule = const TypeValidationRule(),
    this.uniquenessRule = const UniquenessValidationRule(),
  });

  /// Rule responsible for nested account metadata.
  final AccountValidationRule accountRule;

  /// Rule responsible for fixed account addresses.
  final AddressValidationRule addressRule;

  /// Rule responsible for instruction discriminator validation.
  final DiscriminatorValidationRule discriminatorRule;

  /// Rule responsible for argument and return type validation.
  final TypeValidationRule typeRule;

  /// Rule responsible for duplicate instruction argument names.
  final UniquenessValidationRule uniquenessRule;

  /// Validates every instruction in [program].
  void validate(
    IdlProgram program,
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    final accountTypes = program.accounts.map((item) => item.name).toSet();
    for (final instruction in program.instructions) {
      discriminatorRule.validate(
        instruction.discriminator,
        instruction.sourcePath,
        issue,
      );
      uniquenessRule.names(
        instruction.arguments.map((item) => (item.name, item.sourcePath)),
        'instruction argument',
        issue,
      );
      accountRule.validate(
        instruction,
        definitions,
        accountTypes,
        addressRule,
        issue,
      );
      for (final argument in instruction.arguments) {
        typeRule.validate(
          argument.type,
          definitions,
          const {},
          argument.sourcePath,
          issue,
        );
      }
      if (instruction.returns case final returns?) {
        typeRule.validate(
          returns,
          definitions,
          const {},
          '${instruction.sourcePath}.returns',
          issue,
        );
      }
    }
  }
}
