import 'idl_format_exception.dart';
import 'strict_json_reader.dart';

/// Decodes type-definition metadata: serialization, repr, and generics.
final class AnchorTypeMetadataDecoder {
  /// Creates a type metadata decoder.
  const AnchorTypeMetadataDecoder(this.values);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Decodes and validates the serialization marker.
  String serialization(Map<String, Object?> object, String path) {
    final rawSerialization = object['serialization'];
    if (rawSerialization != null && rawSerialization is! String) {
      throw IdlFormatException(
        'Custom serialization is recognized but unsupported.',
        '$path.serialization',
        code: 'IDL_SERIALIZATION_UNSUPPORTED',
      );
    }
    final serialization = rawSerialization as String? ?? 'borsh';
    if (serialization != 'borsh') {
      final recognized = const {
        'bytemuck',
        'bytemuckunsafe',
      }.contains(serialization);
      throw IdlFormatException(
        recognized
            ? 'Serialization "$serialization" is recognized but unsupported.'
            : 'Custom serialization "$serialization" is unsupported.',
        '$path.serialization',
        code: 'IDL_SERIALIZATION_UNSUPPORTED',
      );
    }
    return serialization;
  }

  /// Decodes a Rust representation marker.
  String? representation(Map<String, Object?> object, String path) =>
      object['repr'] == null ? null : _representation(object['repr'], path);

  /// Decodes type and const generic declarations.
  ({List<String> typeGenerics, List<String> constGenerics}) generics(
    Map<String, Object?> object,
    String path,
  ) {
    final generics = <String>[];
    final constGenerics = <String>[];
    final rawGenerics = values.optionalList(
      object,
      'generics',
      '$path.generics',
    );
    for (var index = 0; index < rawGenerics.length; index++) {
      final generic = _genericDeclaration(
        rawGenerics[index],
        '$path.generics[$index]',
      );
      (generic.$1 == 'type' ? generics : constGenerics).add(generic.$2);
    }
    return (
      typeGenerics: List.unmodifiable(generics),
      constGenerics: List.unmodifiable(constGenerics),
    );
  }

  (String, String) _genericDeclaration(Object? raw, String path) {
    if (raw is String) return ('type', values.nonEmptyString(raw, path));
    final object = values.object(raw, path);
    values.knownKeys(object, const {'kind', 'name', 'type'}, path);
    final kind = values.optionalString(object, 'kind', '$path.kind') ?? 'type';
    if (kind != 'type' && kind != 'const') {
      throw IdlFormatException(
        'Unknown generic declaration kind "$kind".',
        '$path.kind',
      );
    }
    if (kind == 'const') {
      final constType = values.requiredString(object, 'type', '$path.type');
      if (constType != 'usize') {
        throw IdlFormatException(
          'Only usize const generic lengths are supported.',
          '$path.type',
          code: 'IDL_CONST_GENERIC_TYPE',
        );
      }
    }
    return (kind, values.requiredString(object, 'name', '$path.name'));
  }

  String _representation(Object? raw, String path) {
    if (raw is String) {
      if (const {'rust', 'c', 'transparent'}.contains(raw)) return raw;
      throw IdlFormatException('Unknown representation "$raw".', path);
    }
    final object = values.object(raw, path);
    values.knownKeys(object, const {'kind', 'packed', 'align'}, path);
    final kind = values.requiredString(object, 'kind', '$path.kind');
    if (!const {'rust', 'c', 'transparent'}.contains(kind)) {
      throw IdlFormatException('Unknown representation "$kind".', path);
    }
    if (object['packed'] case final packed?) {
      values.boolean(packed, '$path.packed');
    }
    if (object['align'] case final align?) {
      values.integer(align, '$path.align');
    }
    return kind;
  }
}
