import '../idl.dart';
import 'duplicate_aware_json_decoder.dart';

/// Parsed IDL and the source map used to locate semantic diagnostics.
final class ParsedIdlDocument {
  /// Creates a parsed document.
  const ParsedIdlDocument(this.program, this.sourceMap);

  /// Immutable normalized IDL.
  final IdlProgram program;

  /// Locations of decoded JSON values.
  final JsonSourceMap sourceMap;
}
