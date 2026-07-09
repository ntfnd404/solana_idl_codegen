import 'dart:collection';

/// Severity of a stable IDL diagnostic.
enum DiagnosticSeverity {
  /// The condition prevents validation or generation.
  error,

  /// The condition is valid but may require caller attention.
  warning,
}

/// A source location in an IDL document.
final class SourceLocation {
  /// Creates a one-based source location.
  const SourceLocation({required this.line, required this.column});

  /// One-based line number.
  final int line;

  /// One-based column number.
  final int column;
}

/// An immutable validation or generation diagnostic.
final class IdlDiagnostic {
  /// Creates a diagnostic with a stable machine-readable [code].
  IdlDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.jsonPath,
    required this.location,
    this.sourceName,
    Iterable<IdlDiagnostic> related = const [],
    this.cause,
  }) : related = UnmodifiableListView(List.of(related));

  /// Stable diagnostic code.
  final String code;

  /// Diagnostic severity.
  final DiagnosticSeverity severity;

  /// Human-readable explanation.
  final String message;

  /// RFC 9535-style path to the affected JSON value.
  final String jsonPath;

  /// Optional caller-supplied source label.
  final String? sourceName;

  /// One-based source location.
  final SourceLocation location;

  /// Diagnostics that identify related declarations or locations.
  final List<IdlDiagnostic> related;

  /// Sanitized description of an underlying failure, when applicable.
  final String? cause;

  @override
  String toString() {
    final source = sourceName == null ? '' : '$sourceName:';
    final position = '${location.line}:${location.column}:';
    return '$source$position $code at $jsonPath: $message'.trim();
  }
}

/// Immutable result returned by non-throwing IDL validation.
final class ValidationResult {
  /// Creates a result and defensively copies [diagnostics].
  ValidationResult(Iterable<IdlDiagnostic> diagnostics)
    : diagnostics = UnmodifiableListView(List.of(diagnostics));

  /// Ordered diagnostics produced by the validation pipeline.
  final List<IdlDiagnostic> diagnostics;

  /// Whether validation completed without error diagnostics.
  bool get isValid =>
      diagnostics.every((item) => item.severity != DiagnosticSeverity.error);
}

/// Exception thrown when generation is requested for an invalid IDL.
final class GenerationException implements Exception {
  /// Creates an exception and defensively copies ordered [diagnostics].
  GenerationException(Iterable<IdlDiagnostic> diagnostics)
    : diagnostics = UnmodifiableListView(List.of(diagnostics));

  /// Ordered diagnostics that prevented generation.
  final List<IdlDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.isEmpty
      ? 'GenerationException: generation failed.'
      : 'GenerationException: ${diagnostics.first}';
}
