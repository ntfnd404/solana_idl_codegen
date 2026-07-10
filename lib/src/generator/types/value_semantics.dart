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
  String equal(IdlType value, String left, String right) =>
      _equal(value, left, right, 0);

  String _equal(
    IdlType value,
    String left,
    String right,
    int depth,
  ) => switch (value) {
    IdlPrimitiveType(name: 'bytes') =>
      '_${member('program')}ListEquals($left, $right, (left, right) => left == right)',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) =>
      '_${member('program')}ListEquals($left, $right, (left, right) => ${_equal(inner, 'left', 'right', depth + 1)})',
    IdlOptionType(:final inner) ||
    IdlCOptionType(:final inner) => _optionEqual(inner, left, right, depth),
    IdlPrimitiveType(name: 'f32' || 'f64') =>
      '($left == $right || ($left == 0.0 && $right == 0.0))',
    _ => '$left == $right',
  };

  String _optionEqual(IdlType inner, String left, String right, int depth) {
    final leftValue = 'leftValue$depth';
    final rightValue = 'rightValue$depth';
    return 'switch (($left, $right)) { '
        '(null, null) => true, '
        '(final $leftValue?, final $rightValue?) => '
        '${_equal(inner, leftValue, rightValue, depth + 1)}, '
        '_ => false }';
  }

  /// Builds a hash expression consistent with generated equality.
  String hash(IdlType value, String expression) => _hash(value, expression, 0);

  String _hash(IdlType value, String expression, int depth) => switch (value) {
    IdlPrimitiveType(name: 'bytes') => 'Object.hashAll($expression)',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) =>
      'Object.hashAll($expression.map((item) => ${_hash(inner, 'item', depth + 1)}))',
    IdlOptionType(:final inner) || IdlCOptionType(:final inner) =>
      'switch ($expression) { null => 0, '
          'final value$depth => ${_hash(inner, 'value$depth', depth + 1)} }',
    IdlPrimitiveType(name: 'f32' || 'f64') =>
      '($expression == 0.0 ? 0.0.hashCode : $expression.hashCode)',
    _ => '$expression.hashCode',
  };

  /// Builds a defensive-copy or validation expression for [value].
  String immutableExpression(IdlType value, String expression) =>
      _immutableExpression(value, expression, 0);

  String _immutableExpression(
    IdlType value,
    String expression,
    int depth,
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
      'List.unmodifiable($expression.map((item) => ${_immutableExpression(inner, 'item', depth + 1)}))',
    IdlOptionType(:final inner) || IdlCOptionType(:final inner) =>
      'switch ($expression) { null => null, '
          'final value$depth => ${_immutableExpression(inner, 'value$depth', depth + 1)} }',
    _ => expression,
  };
}
