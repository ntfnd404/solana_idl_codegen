import '../idl.dart';

/// Resolves nested IDL field paths through defined struct and alias types.
final class TypePathResolver {
  /// Creates a stateless nested type-path resolver.
  const TypePathResolver();

  /// Resolves an instruction argument [path] to the type of its final segment.
  IdlType? resolveArgumentPath(
    List<IdlField> arguments,
    String path,
    Map<String, IdlTypeDefinition> definitions,
  ) {
    final segments = path.split('.');
    final root = _fieldByWirePathSegment(arguments, segments.first);
    if (root == null) return null;
    return resolveNestedType(root.type, segments.skip(1), definitions);
  }

  /// Returns whether [fieldPath] exists inside the defined [accountType].
  bool hasAccountFieldPath(
    String accountType,
    String fieldPath,
    Map<String, IdlTypeDefinition> definitions,
  ) => resolveAccountFieldPath(accountType, fieldPath, definitions) != null;

  /// Resolves [fieldPath] inside [accountType] to the final field type.
  IdlType? resolveAccountFieldPath(
    String accountType,
    String fieldPath,
    Map<String, IdlTypeDefinition> definitions,
  ) {
    final definition = definitions[accountType];
    if (definition == null) return null;
    final segments = fieldPath.split('.');
    final body = definition.body;
    if (body is! IdlStructBody) return null;
    final field = _fieldByWirePathSegment(body.fields, segments.first);
    if (field == null) return null;
    return resolveNestedType(field.type, segments.skip(1), definitions);
  }

  /// Resolves [segments] from [initial] through struct fields and aliases.
  IdlType? resolveNestedType(
    IdlType initial,
    Iterable<String> segments,
    Map<String, IdlTypeDefinition> definitions,
  ) {
    var current = initial;
    for (final segment in segments) {
      IdlTypeDefinition? definition;
      while (current is IdlDefinedType) {
        definition = definitions[current.name];
        if (definition == null) return null;
        if (definition.body case IdlAliasBody(:final value)) {
          current = value;
          continue;
        }
        break;
      }
      final body = definition?.body;
      if (body is! IdlStructBody) return null;
      final field = _fieldByWirePathSegment(body.fields, segment);
      if (field == null) return null;
      current = field.type;
    }
    return current;
  }

  IdlField? _fieldByWirePathSegment(List<IdlField> fields, String segment) {
    for (final field in fields) {
      if (field.name == segment) return field;
    }
    final normalized = _canonicalSegment(segment);
    for (final field in fields) {
      if (_canonicalSegment(field.name) == normalized) return field;
    }
    return null;
  }

  String _canonicalSegment(String value) => value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
      .toLowerCase();
}
