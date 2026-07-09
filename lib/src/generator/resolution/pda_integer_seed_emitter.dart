import '../../idl.dart';
import 'pda_seed_literals.dart';

/// Emits fixed-width little-endian integer PDA seed encoding statements.
final class PdaIntegerSeedEmitter {
  /// Creates an integer seed emitter using shared [literals].
  const PdaIntegerSeedEmitter(this.literals);

  /// Shared generated-code literal helpers.
  final PdaSeedLiterals literals;

  /// Appends integer seed encoding for [expression].
  void emit(
    StringBuffer out,
    IdlType? valueType,
    String expression,
    int index,
    String indent, {
    bool constant = false,
  }) {
    final primitive = valueType;
    if (primitive is! IdlPrimitiveType) {
      throw StateError('Validator allowed an untyped integer PDA seed.');
    }
    final match = RegExp(r'^([ui])(\d+)$').firstMatch(primitive.name);
    if (match == null) {
      throw StateError(
        'Validator allowed unsupported PDA seed type ${primitive.name}.',
      );
    }
    final signed = match.group(1) == 'i';
    final bits = int.parse(match.group(2)!);
    final length = bits ~/ 8;
    final numericExpression = bits > 32
        ? (constant ? "BigInt.parse('$expression')" : expression)
        : 'BigInt.from($expression)';
    out
      ..writeln(
        '${indent}final seedWriter$index = ${literals.type('borsh_writer')}();',
      )
      ..writeln(
        '$indent${signed ? 'seedWriter$index.writeSigned($numericExpression, $length);' : 'seedWriter$index.writeUnsigned($numericExpression, $length);'}',
      )
      ..writeln('${indent}seeds.add(seedWriter$index.takeBytes());');
  }
}
