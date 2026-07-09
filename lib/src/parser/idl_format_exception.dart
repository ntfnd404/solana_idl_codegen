import '../diagnostics.dart';

/// Internal parse or validation failure annotated with source context.
final class IdlFormatException extends FormatException {
  /// Creates a format failure at the JSON [path].
  const IdlFormatException(
    super.message,
    this.path, {
    this.code = 'IDL_SCHEMA_INVALID',
    this.location,
    this.related = const [],
    this.causeDescription,
  });

  /// JSON path identifying the invalid IDL value.
  final String path;

  /// Stable machine-readable diagnostic code.
  final String code;

  /// Source location when known by the duplicate-aware decoder.
  final SourceLocation? location;

  /// Related parse or validation failures.
  final List<IdlFormatException> related;

  /// Sanitized description of an underlying cause.
  final String? causeDescription;

  /// Returns this failure with missing source locations supplied by [resolve].
  IdlFormatException located(SourceLocation Function(String path) resolve) =>
      IdlFormatException(
        message,
        path,
        code: code,
        location: location ?? resolve(path),
        related: related.map((item) => item.located(resolve)).toList(),
        causeDescription: causeDescription,
      );

  @override
  String toString() => 'IDL error at $path: $message';
}
