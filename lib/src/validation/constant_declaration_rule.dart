import '../idl.dart';
import 'constant_rule.dart';
import 'type_rule.dart';
import 'validation_issue.dart';

/// Validates constant types and literal representations.
final class ConstantDeclarationValidationRule {
  /// Creates a constant declaration validation rule.
  const ConstantDeclarationValidationRule({
    this.constantRule = const ConstantValidationRule(),
    this.typeRule = const TypeValidationRule(),
  });

  /// Rule responsible for constant literal compatibility and ranges.
  final ConstantValidationRule constantRule;

  /// Rule responsible for constant type validation.
  final TypeValidationRule typeRule;

  /// Validates every constant in [program].
  void validate(
    IdlProgram program,
    Map<String, IdlTypeDefinition> definitions,
    ValidationIssue issue,
  ) {
    for (final constant in program.constants) {
      typeRule.validate(
        constant.type,
        definitions,
        const {},
        '${constant.sourcePath}.type',
        issue,
      );
      constantRule.validate(constant, issue);
    }
  }
}
