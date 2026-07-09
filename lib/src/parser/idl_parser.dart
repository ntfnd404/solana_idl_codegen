import '../idl.dart';

/// Converts serialized IDL data into immutable intermediate representation.
abstract interface class IdlParser {
  /// Parses a serialized JSON IDL [source].
  IdlProgram parseString(String source);

  /// Parses an already decoded IDL [json] object.
  IdlProgram parseJson(Map<String, Object?> json);
}
