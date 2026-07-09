import '../idl.dart';
import 'validation_issue.dart';

/// Validates that parsed integer constants fit their declared wire type.
final class ConstantValidationRule {
  /// Creates the stateless constant rule.
  const ConstantValidationRule();

  /// Reports range violations for [constant].
  void validate(IdlConstantDefinition constant, ValidationIssue issue) {
    if (constant.value case IdlIntegerConstValue(:final value)) {
      final primitive = constant.type;
      if (primitive is! IdlPrimitiveType) return;
      final match = RegExp(r'^([ui])(\d+)$').firstMatch(primitive.name);
      if (match == null) return;
      final signed = match.group(1) == 'i';
      final bits = int.parse(match.group(2)!);
      final minimum = signed ? -(BigInt.one << (bits - 1)) : BigInt.zero;
      final maximum = signed
          ? (BigInt.one << (bits - 1)) - BigInt.one
          : (BigInt.one << bits) - BigInt.one;
      if (value < minimum || value > maximum) {
        issue(
          'IDL_CONSTANT_RANGE',
          'Constant value is outside ${primitive.name} range.',
          '${constant.sourcePath}.value',
        );
      }
    }
  }
}
