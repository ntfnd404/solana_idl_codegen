import 'idl_format_exception.dart';

/// Strict typed access to decoded JSON values with exact JSON paths.
final class StrictJsonReader {
  /// Creates a strict JSON reader.
  const StrictJsonReader();

  /// Rejects object keys outside [known].
  void knownKeys(Map<String, Object?> object, Set<String> known, String path) {
    for (final key in object.keys) {
      if (!known.contains(key)) {
        throw IdlFormatException('Unknown field "$key".', '$path.$key');
      }
    }
  }

  /// Reads [value] as a string-keyed object.
  Map<String, Object?> object(Object? value, String path) {
    if (value is! Map<Object?, Object?>) {
      throw IdlFormatException('Expected an object.', path);
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw IdlFormatException('Expected string object keys.', path);
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  /// Reads a required object property.
  Map<String, Object?> requiredObject(
    Map<String, Object?> owner,
    String key,
    String path,
  ) => object(requiredValue(owner, key, path), path);

  /// Reads an optional object property.
  Map<String, Object?>? optionalObject(
    Map<String, Object?> owner,
    String key,
    String path,
  ) {
    if (!owner.containsKey(key) || owner[key] == null) return null;
    return object(owner[key], path);
  }

  /// Reads [value] as an immutable JSON array.
  List<Object?> list(Object? value, String path) {
    if (value is! List<Object?>) {
      throw IdlFormatException('Expected an array.', path);
    }
    return List<Object?>.unmodifiable(value);
  }

  /// Reads a required array property.
  List<Object?> requiredList(
    Map<String, Object?> owner,
    String key,
    String path,
  ) => list(requiredValue(owner, key, path), path);

  /// Reads an optional array property or an empty list.
  List<Object?> optionalList(
    Map<String, Object?> owner,
    String key,
    String path,
  ) {
    if (!owner.containsKey(key) || owner[key] == null) return const [];
    return list(owner[key], path);
  }

  /// Reads a required non-null property.
  Object? requiredValue(Map<String, Object?> owner, String key, String path) {
    if (!owner.containsKey(key) || owner[key] == null) {
      throw IdlFormatException('Required value is missing.', path);
    }
    return owner[key];
  }

  /// Reads a required non-empty string property.
  String requiredString(Map<String, Object?> owner, String key, String path) =>
      nonEmptyString(requiredValue(owner, key, path), path);

  /// Reads an optional non-empty string property.
  String? optionalString(Map<String, Object?>? owner, String key, String path) {
    if (owner == null || !owner.containsKey(key) || owner[key] == null) {
      return null;
    }
    return nonEmptyString(owner[key], path);
  }

  /// Reads an optional string property that may be empty.
  String? optionalPossiblyEmptyString(
    Map<String, Object?>? owner,
    String key,
    String path,
  ) {
    if (owner == null || !owner.containsKey(key) || owner[key] == null) {
      return null;
    }
    final value = owner[key];
    if (value is! String) {
      throw IdlFormatException('Expected a string.', path);
    }
    return value;
  }

  /// Reads [value] as a non-empty string.
  String nonEmptyString(Object? value, String path) {
    if (value is! String || value.isEmpty) {
      throw IdlFormatException('Expected a non-empty string.', path);
    }
    return value;
  }

  /// Reads [value] as an integer without numeric coercion.
  int integer(Object? value, String path) {
    if (value is! int) {
      throw IdlFormatException('Expected an integer.', path);
    }
    return value;
  }

  /// Reads an integer byte in the range 0–255.
  int byte(Object? value, String path) {
    final byte = integer(value, path);
    if (byte < 0 || byte > 255) {
      throw IdlFormatException('Expected a byte, got $byte.', path);
    }
    return byte;
  }

  /// Reads [value] as a boolean.
  bool boolean(Object? value, String path) {
    if (value is! bool) {
      throw IdlFormatException('Expected a boolean.', path);
    }
    return value;
  }

  /// Reads an immutable documentation-line array.
  List<String> docs(Map<String, Object?> owner, String key, String path) {
    final raw = optionalList(owner, key, path);
    return List<String>.unmodifiable([
      for (var index = 0; index < raw.length; index++)
        string(raw[index], '$path[$index]'),
    ]);
  }

  /// Reads [value] as a string, allowing an empty value.
  String string(Object? value, String path) {
    if (value is! String) {
      throw IdlFormatException('Expected a string.', path);
    }
    return value;
  }

  /// Throws a required-value diagnostic.
  Never missing(String description, String path) =>
      throw IdlFormatException('Required $description is missing.', path);
}
