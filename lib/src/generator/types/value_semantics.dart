import '../../idl.dart';
import '../generator_context.dart';

/// Emits equality, hashing, validation, and defensive-copy expressions.
final class GeneratedValueSemantics {
  /// Creates value semantics for [context].
  const GeneratedValueSemantics(this.context);

  /// Shared immutable generation context.
  final GeneratorContext context;

  /// Maps a generated type name through the configured naming strategy.
  String type(String name) => context.type(name);

  /// Maps a generated member name through the configured naming strategy.
  String member(String name) => context.member(name);

  /// Builds a deep value-equality expression for [left] and [right].
  String equal(IdlType value, String left, String right) => switch (value) {
    IdlPrimitiveType(name: 'bytes') =>
      '_${member('program')}ListEquals($left, $right, (left, right) => left == right)',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) =>
      '_${member('program')}ListEquals($left, $right, (left, right) => ${equal(inner, 'left', 'right')})',
    IdlOptionType(:final inner) || IdlCOptionType(:final inner) =>
      '($left == null ? $right == null : $right != null && ${equal(inner, '$left!', '$right!')})',
    IdlPrimitiveType(name: 'f32' || 'f64') =>
      '($left == $right || ($left == 0.0 && $right == 0.0))',
    _ => '$left == $right',
  };

  /// Builds a hash expression consistent with generated equality.
  String hash(IdlType value, String expression) => switch (value) {
    IdlPrimitiveType(name: 'bytes') => 'Object.hashAll($expression)',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(
      :final inner,
    ) => 'Object.hashAll($expression.map((item) => ${hash(inner, 'item')}))',
    IdlOptionType(:final inner) || IdlCOptionType(:final inner) =>
      '$expression == null ? 0 : ${hash(inner, '$expression!')}',
    IdlPrimitiveType(name: 'f32' || 'f64') =>
      '($expression == 0.0 ? 0.0.hashCode : $expression.hashCode)',
    _ => '$expression.hashCode',
  };

  /// Builds a defensive-copy or validation expression for [value].
  String immutableExpression(
    IdlType value,
    String expression,
  ) => switch (value) {
    IdlPrimitiveType(name: 'bytes') =>
      'Uint8List.fromList($expression).asUnmodifiableView()',
    IdlPrimitiveType(name: 'f32') =>
      '${type('float_semantics')}.f32($expression)',
    IdlPrimitiveType(name: 'f64') =>
      '${type('float_semantics')}.f64($expression)',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) =>
      'List.unmodifiable($expression.map((item) => ${immutableExpression(inner, 'item')}))',
    IdlOptionType(:final inner) || IdlCOptionType(:final inner) =>
      '$expression == null ? null : ${immutableExpression(inner, '$expression!')}',
    _ => expression,
  };
}
