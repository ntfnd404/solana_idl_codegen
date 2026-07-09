import 'dart:convert';
import 'dart:io';

import '../diagnostics.dart';

/// Renders ordered diagnostics for CLI consumers.
final class DiagnosticWriter {
  /// Creates the stateless diagnostic writer.
  const DiagnosticWriter();

  /// Writes [diagnostics] as human-readable lines or JSON Lines.
  void write(List<IdlDiagnostic> diagnostics, String format, IOSink sink) {
    if (format == 'json') {
      for (final item in diagnostics) {
        sink.writeln(
          jsonEncode({
            'code': item.code,
            'severity': item.severity.name,
            'message': item.message,
            'source': item.sourceName,
            'path': item.jsonPath,
            'line': item.location.line,
            'column': item.location.column,
          }),
        );
      }
      return;
    }
    for (final item in diagnostics) {
      sink.writeln(item);
    }
  }
}
