/// Converts IDL wire names into valid Dart identifiers.
abstract interface class NamingStrategy {
  /// Converts IDL [wireName] into a Dart type identifier.
  String typeName(String wireName);

  /// Converts IDL [wireName] into a Dart member identifier.
  String memberName(String wireName);
}

/// Default deterministic naming strategy for generated Dart identifiers.
final class DartNamingStrategy implements NamingStrategy {
  /// Creates the default Dart naming strategy.
  const DartNamingStrategy();

  static const _keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  @override
  String typeName(String wireName) {
    final words = _words(wireName);
    final result = words.map(_capitalize).join();
    return result.isEmpty ? 'Unnamed' : _safe(result);
  }

  @override
  String memberName(String wireName) {
    final type = typeName(wireName);
    final result = '${type[0].toLowerCase()}${type.substring(1)}';
    return _safe(result);
  }

  List<String> _words(String input) => input
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .split(RegExp('[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase())
      .toList();

  String _capitalize(String word) =>
      word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';

  String _safe(String value) {
    var result = value;
    if (RegExp(r'^[0-9]').hasMatch(result)) result = 'n$result';
    if (_keywords.contains(result)) result = '${result}Value';
    return result;
  }
}

/// Decorates another strategy with a prefix and suffix for generated types.
final class AffixedNamingStrategy implements NamingStrategy {
  /// Creates a naming decorator around [base].
  const AffixedNamingStrategy({
    this.prefix = '',
    this.suffix = '',
    this.base = const DartNamingStrategy(),
  });

  /// Prefix applied to generated type names.
  final String prefix;

  /// Suffix applied to generated type names.
  final String suffix;

  /// Underlying strategy responsible for normalization.
  final NamingStrategy base;

  @override
  String memberName(String wireName) => base.memberName(wireName);

  @override
  String typeName(String wireName) =>
      '$prefix${base.typeName(wireName)}$suffix';
}
