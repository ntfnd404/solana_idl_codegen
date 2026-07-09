import 'package:build/build.dart';

/// Validated immutable configuration shared by both static builders.
final class SolanaIdlBuilderOptions {
  /// Creates builder naming options.
  const SolanaIdlBuilderOptions({
    this.typePrefix = 'auto',
    this.typeSuffix = '',
  });

  /// Parses naming values supplied by `build_runner`.
  factory SolanaIdlBuilderOptions.fromBuilderOptions(BuilderOptions options) {
    const supported = {'type_prefix', 'type_suffix'};
    final unknown = options.config.keys.where(
      (key) => !supported.contains(key),
    );
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown solana_idl builder option(s): ${unknown.join(', ')}. '
        'Supported options: ${supported.join(', ')}.',
      );
    }
    final prefix = _string(options.config, 'type_prefix', 'auto');
    final suffix = _string(options.config, 'type_suffix', '');
    final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    if (prefix != 'auto' && !identifier.hasMatch(prefix)) {
      throw ArgumentError.value(
        prefix,
        'type_prefix',
        'Expected "auto" or a non-empty Dart identifier.',
      );
    }
    if (suffix.isNotEmpty && !identifier.hasMatch(suffix)) {
      throw ArgumentError.value(
        suffix,
        'type_suffix',
        'Expected an empty string or a Dart identifier.',
      );
    }
    return SolanaIdlBuilderOptions(typePrefix: prefix, typeSuffix: suffix);
  }

  /// `auto` or an explicit prefix applied to every public generated type.
  final String typePrefix;

  /// Optional suffix applied to every public generated type.
  final String typeSuffix;

  static String _string(
    Map<String, Object?> values,
    String key,
    String fallback,
  ) {
    final value = values[key] ?? fallback;
    if (value is! String) {
      throw ArgumentError.value(value, key, 'Expected a string.');
    }
    return value;
  }
}
