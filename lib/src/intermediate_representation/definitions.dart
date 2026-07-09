import 'instruction.dart';
import 'types.dart';

/// Named program account and its wire discriminator.
final class IdlAccountDefinition {
  /// Creates a named account definition.
  IdlAccountDefinition({
    required this.name,
    required List<int> discriminator,
    this.sourcePath = r'$',
  }) : discriminator = List.unmodifiable(discriminator);

  /// Account type wire name.
  final String name;

  /// Non-empty account discriminator.
  final List<int> discriminator;

  /// JSON path at which this account was declared.
  final String sourcePath;
}

/// Named Anchor event and its wire discriminator.
final class IdlEventDefinition {
  /// Creates a named event definition.
  IdlEventDefinition({
    required this.name,
    required List<int> discriminator,
    this.sourcePath = r'$',
  }) : discriminator = List.unmodifiable(discriminator);

  /// Event type wire name.
  final String name;

  /// Non-empty event discriminator.
  final List<int> discriminator;

  /// JSON path at which this event was declared.
  final String sourcePath;
}

/// Named custom program error.
final class IdlErrorDefinition {
  /// Creates a custom program error definition.
  const IdlErrorDefinition({
    required this.code,
    required this.name,
    required this.message,
    this.sourcePath = r'$',
  });

  /// Numeric custom program error code.
  final int code;

  /// Stable IDL error name.
  final String name;

  /// Human-readable error message.
  final String message;

  /// JSON path at which this error was declared.
  final String sourcePath;
}

/// Parsed and validated IDL constant.
final class IdlConstantDefinition {
  /// Creates a constant definition.
  IdlConstantDefinition({
    required this.name,
    required this.type,
    required this.value,
    List<String> docs = const [],
    this.sourcePath = r'$',
  }) : docs = List.unmodifiable(docs);

  /// Constant wire name.
  final String name;

  /// Declared wire type.
  final IdlType type;

  /// Parsed constant value.
  final IdlConstValue value;

  /// Documentation lines supplied by the IDL.
  final List<String> docs;

  /// JSON path at which this constant was declared.
  final String sourcePath;
}
