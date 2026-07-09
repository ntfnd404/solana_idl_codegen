import '../../idl.dart';
import '../generator_context.dart';

/// Shared literal and naming helpers for generated PDA seed code.
final class PdaSeedLiterals {
  /// Creates helpers backed by [context].
  const PdaSeedLiterals(this.context);

  /// Shared immutable generation context.
  final GeneratorContext context;

  /// Maps a generated type name through the configured naming strategy.
  String type(String name) => context.type(name);

  /// Maps a generated member name through the configured naming strategy.
  String member(String name) => context.member(name);

  /// Builds a typed integer-list literal.
  String bytes(List<int> value) => '<int>[${value.join(', ')}]';

  /// Escapes text embedded in a generated single-quoted Dart literal.
  String escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');

  /// Returns a stable diagnostic name for a PDA seed [type].
  String seedTypeName(IdlType type) => switch (type) {
    IdlPrimitiveType(:final name) => name,
    IdlArrayType(inner: IdlPrimitiveType(name: 'u8'), :final length) =>
      '[u8;$length]',
    _ => throw StateError('Validator allowed an unsupported PDA seed type.'),
  };
}
