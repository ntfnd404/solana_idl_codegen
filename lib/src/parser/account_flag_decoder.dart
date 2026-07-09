import 'idl_format_exception.dart';
import 'strict_json_reader.dart';

/// Decodes modern/legacy boolean aliases on instruction accounts.
final class AnchorAccountFlagDecoder {
  /// Creates an account flag decoder.
  const AnchorAccountFlagDecoder(this.values);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Decodes a boolean available under modern and legacy field names.
  bool aliasedBoolean(
    Map<String, Object?> object, {
    required String modern,
    required String legacy,
    required String path,
  }) {
    final hasModern = object.containsKey(modern) && object[modern] != null;
    final hasLegacy = object.containsKey(legacy) && object[legacy] != null;
    final modernValue = hasModern
        ? values.boolean(object[modern], '$path.$modern')
        : null;
    final legacyValue = hasLegacy
        ? values.boolean(object[legacy], '$path.$legacy')
        : null;
    if (modernValue != null &&
        legacyValue != null &&
        modernValue != legacyValue) {
      throw IdlFormatException(
        'Conflicting "$modern" and "$legacy" values.',
        '$path.$modern',
      );
    }
    return modernValue ?? legacyValue ?? false;
  }
}
