import '../../idl.dart';
import 'pda_integer_seed_emitter.dart';
import 'pda_seed_literals.dart';

/// Emits PDA seed encoding for values whose IDL type is already known.
final class PdaTypedSeedEmitter {
  /// Creates a typed seed emitter using shared [literals].
  const PdaTypedSeedEmitter(this.literals);

  /// Shared generated-code literal helpers.
  final PdaSeedLiterals literals;

  /// Appends typed seed encoding for [expression].
  void emit(
    StringBuffer out,
    IdlType valueType,
    String expression,
    int index,
    String indent,
  ) {
    switch (valueType) {
      case IdlPrimitiveType(name: 'string'):
        out.writeln(
          '${indent}seeds.add(Uint8List.fromList(utf8.encode($expression)));',
        );
      case IdlPrimitiveType(name: 'bytes'):
        out.writeln('${indent}seeds.add(Uint8List.fromList($expression));');
      case IdlPrimitiveType(name: 'pubkey'):
        out.writeln('${indent}seeds.add($expression.bytes);');
      case IdlArrayType(inner: IdlPrimitiveType(name: 'u8')):
        out.writeln('${indent}seeds.add(Uint8List.fromList($expression));');
      case IdlPrimitiveType():
        PdaIntegerSeedEmitter(
          literals,
        ).emit(out, valueType, expression, index, indent);
      default:
        throw StateError('Validator allowed an unsupported PDA seed type.');
    }
  }
}
