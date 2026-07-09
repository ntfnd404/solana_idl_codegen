import 'dart:convert';

import '../idl.dart';
import 'validation_issue.dart';

/// Validates PDA seed wire compatibility.
///
/// This rule owns seed-specific checks: supported seed types, constant value
/// ranges, encoded seed length, and byte value ranges. Account-tree and
/// relation checks remain in `AccountValidationRule`.
final class PdaSeedValidationRule {
  /// Creates a stateless PDA seed validation rule.
  const PdaSeedValidationRule();

  static final RegExp _integerType = RegExp(r'^[ui](8|16|32|64|128|256)$');

  /// Reports an issue unless [type] can be encoded as a Solana PDA seed.
  void validateSeedType(IdlType type, String path, ValidationIssue issue) {
    final supported = switch (type) {
      IdlPrimitiveType(:final name) =>
        name == 'string' ||
            name == 'bytes' ||
            name == 'pubkey' ||
            _integerType.hasMatch(name),
      IdlArrayType(inner: IdlPrimitiveType(name: 'u8'), :final length) =>
        length <= 32,
      _ => false,
    };
    if (!supported) {
      issue(
        'IDL_PDA_SEED_TYPE',
        'Unsupported PDA seed type; expected an integer, string, bytes, '
            'pubkey, or fixed u8 array.',
        path,
      );
    }
  }

  /// Validates [seed] as a constant PDA seed.
  void validateConstSeed(IdlConstSeed seed, ValidationIssue issue) {
    final type = seed.valueType;
    switch (seed.value) {
      case IdlBooleanConstValue():
        issue(
          'IDL_PDA_SEED_TYPE',
          'Boolean PDA seeds are unsupported.',
          seed.sourcePath,
        );
      case IdlIntegerConstValue(:final value):
        _validateIntegerSeed(seed, value, type, issue);
      case IdlStringConstValue(:final value):
        _validateStringSeed(seed, value, type, issue);
      case IdlBytesConstValue(:final value):
        _validateBytesSeed(seed, value, issue);
    }
    if (type != null) validateSeedType(type, seed.sourcePath, issue);
  }

  void _validateIntegerSeed(
    IdlConstSeed seed,
    BigInt value,
    IdlType? type,
    ValidationIssue issue,
  ) {
    if (type is! IdlPrimitiveType || !_integerType.hasMatch(type.name)) {
      issue(
        'IDL_PDA_SEED_INTEGER_TYPE',
        'Integer PDA seed requires an explicit integer type.',
        seed.sourcePath,
      );
      return;
    }
    final match = RegExp(r'^([ui])(\d+)$').firstMatch(type.name)!;
    final signed = match.group(1) == 'i';
    final bits = int.parse(match.group(2)!);
    final minimum = signed ? -(BigInt.one << (bits - 1)) : BigInt.zero;
    final maximum = signed
        ? (BigInt.one << (bits - 1)) - BigInt.one
        : (BigInt.one << bits) - BigInt.one;
    if (value < minimum || value > maximum) {
      issue(
        'IDL_PDA_SEED_RANGE',
        'PDA seed value is outside ${type.name} range.',
        seed.sourcePath,
      );
    }
  }

  void _validateStringSeed(
    IdlConstSeed seed,
    String value,
    IdlType? type,
    ValidationIssue issue,
  ) {
    if (type != null && type is! IdlPrimitiveType) {
      issue(
        'IDL_PDA_SEED_TYPE',
        'String PDA seed has an incompatible declared type.',
        seed.sourcePath,
      );
    }
    _validateSeedByteLength(utf8.encode(value).length, seed.sourcePath, issue);
  }

  void _validateBytesSeed(
    IdlConstSeed seed,
    List<int> value,
    ValidationIssue issue,
  ) {
    if (value.any((byte) => byte < 0 || byte > 255)) {
      issue(
        'IDL_PDA_SEED_BYTE_RANGE',
        'PDA seed bytes must be in the range 0..255.',
        seed.sourcePath,
      );
    }
    _validateSeedByteLength(value.length, seed.sourcePath, issue);
  }

  void _validateSeedByteLength(
    int byteLength,
    String path,
    ValidationIssue issue,
  ) {
    if (byteLength > 32) {
      issue('IDL_PDA_SEED_LENGTH', 'A PDA seed cannot exceed 32 bytes.', path);
    }
  }
}
