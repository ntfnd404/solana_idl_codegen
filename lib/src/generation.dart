import 'dart:collection';

/// Supported physical layouts for a generated Dart SDK.
enum OutputLayout {
  /// Emits the complete generated SDK as one Dart library.
  bundled,

  /// Emits a barrel library and focused neighboring Dart libraries.
  modular,
}

/// Immutable limits applied before and while decoding an IDL document.
final class IdlParseLimits {
  /// Creates explicit parser resource limits.
  const IdlParseLimits({
    required this.maxSourceBytes,
    required this.maxJsonDepth,
    required this.maxDeclarations,
    required this.maxFieldsPerDeclaration,
    required this.maxTotalFields,
    required this.maxDocsBytes,
    required this.maxIdentifierLength,
  }) : assert(maxSourceBytes > 0),
       assert(maxJsonDepth > 0),
       assert(maxDeclarations > 0),
       assert(maxFieldsPerDeclaration > 0),
       assert(maxTotalFields > 0),
       assert(maxDocsBytes >= 0),
       assert(maxIdentifierLength > 0);

  /// Recommended limits for untrusted IDL input.
  static const defaults = IdlParseLimits(
    maxSourceBytes: 16 * 1024 * 1024,
    maxJsonDepth: 128,
    maxDeclarations: 10000,
    maxFieldsPerDeclaration: 4096,
    maxTotalFields: 100000,
    maxDocsBytes: 4 * 1024 * 1024,
    maxIdentifierLength: 512,
  );

  /// Maximum UTF-8 source size.
  final int maxSourceBytes;

  /// Maximum JSON container nesting depth.
  final int maxJsonDepth;

  /// Maximum number of declarations across the document.
  final int maxDeclarations;

  /// Maximum fields or variants in one declaration.
  final int maxFieldsPerDeclaration;

  /// Maximum fields and variants across the document.
  final int maxTotalFields;

  /// Maximum total UTF-8 documentation size.
  final int maxDocsBytes;

  /// Maximum wire identifier length.
  final int maxIdentifierLength;
}

/// Immutable options controlling generated names and physical output.
final class GenerationOptions {
  /// Creates generation options.
  const GenerationOptions({
    this.layout = OutputLayout.bundled,
    this.typePrefix = 'auto',
    this.typeSuffix = '',
  });

  /// Physical layout used for emitted files.
  final OutputLayout layout;

  /// `auto` or an explicit non-empty Dart identifier prefix.
  final String typePrefix;

  /// Optional Dart identifier suffix applied to public generated types.
  final String typeSuffix;
}

/// Immutable collection of logical generated file names and Dart sources.
final class GenerationOutput {
  /// Creates output and defensively copies [files].
  GenerationOutput(Map<String, String> files)
    : files = UnmodifiableMapView(Map.of(files));

  /// Generated Dart sources indexed by stable logical file name.
  final Map<String, String> files;
}
