import '../idl.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_expression_decoder.dart';

/// Decodes struct, tuple struct, enum, and field bodies.
final class AnchorTypeBodyDecoder {
  /// Creates a type body decoder.
  const AnchorTypeBodyDecoder(this.values, this.expressions);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Decoder for nested wire type expressions.
  final AnchorTypeExpressionDecoder expressions;

  /// Decodes a type body object at [path].
  IdlTypeBody body(Map<String, Object?> type, String path) {
    values.knownKeys(type, const {
      'kind',
      'fields',
      'variants',
      'value',
      'alias',
    }, path);
    final kind = values.requiredString(type, 'kind', '$path.kind');
    return switch (kind) {
      'struct' => struct(
        values.optionalList(type, 'fields', '$path.fields'),
        '$path.fields',
      ),
      'enum' => enumeration(
        values.requiredList(type, 'variants', '$path.variants'),
        '$path.variants',
      ),
      'alias' => IdlAliasBody(
        expressions.typeExpression(
          values.requiredValue(type, 'value', '$path.value'),
          '$path.value',
        ),
      ),
      'type' => IdlAliasBody(
        expressions.typeExpression(
          values.requiredValue(type, 'alias', '$path.alias'),
          '$path.alias',
        ),
      ),
      _ => throw IdlFormatException('Unknown type kind "$kind".', '$path.kind'),
    };
  }

  /// Decodes a list of named fields.
  List<IdlField> fields(
    List<Object?> raw,
    String path, {
    bool allowEventIndex = false,
  }) => [
    for (var index = 0; index < raw.length; index++)
      field(
        values.object(raw[index], '$path[$index]'),
        '$path[$index]',
        allowEventIndex: allowEventIndex,
      ),
  ];

  /// Decodes a struct or tuple-struct body.
  IdlStructBody struct(List<Object?> raw, String path) {
    if (raw.isEmpty || _isNamedField(raw.first)) {
      return IdlStructBody(fields: fields(raw, path), tupleFields: const []);
    }
    return IdlStructBody(
      fields: const [],
      tupleFields: [
        for (var index = 0; index < raw.length; index++)
          expressions.typeExpression(raw[index], '$path[$index]'),
      ],
    );
  }

  /// Decodes an enum body.
  IdlEnumBody enumeration(List<Object?> raw, String path) => IdlEnumBody([
    for (var index = 0; index < raw.length; index++)
      variant(values.object(raw[index], '$path[$index]'), '$path[$index]'),
  ]);

  /// Decodes one enum variant.
  IdlEnumVariant variant(Map<String, Object?> object, String path) {
    values.knownKeys(object, const {'name', 'docs', 'fields'}, path);
    final raw = values.optionalList(object, 'fields', '$path.fields');
    final named = raw.isEmpty || _isNamedField(raw.first);
    return IdlEnumVariant(
      name: values.requiredString(object, 'name', '$path.name'),
      docs: values.docs(object, 'docs', '$path.docs'),
      fields: named ? fields(raw, '$path.fields') : const [],
      tupleFields: named
          ? const []
          : [
              for (var index = 0; index < raw.length; index++)
                expressions.typeExpression(raw[index], '$path.fields[$index]'),
            ],
      sourcePath: path,
    );
  }

  bool _isNamedField(Object? raw) {
    if (raw is! Map) return false;
    final object = values.object(raw, r'$');
    return object.containsKey('name') || object.containsKey('type');
  }

  /// Decodes one named field.
  IdlField field(
    Map<String, Object?> object,
    String path, {
    required bool allowEventIndex,
  }) {
    values.knownKeys(
      object,
      allowEventIndex
          ? const {'name', 'docs', 'type', 'index'}
          : const {'name', 'docs', 'type'},
      path,
    );
    if (allowEventIndex && object['index'] != null) {
      values.boolean(object['index'], '$path.index');
    }
    return IdlField(
      values.requiredString(object, 'name', '$path.name'),
      expressions.typeExpression(
        values.requiredValue(object, 'type', '$path.type'),
        '$path.type',
      ),
      docs: values.docs(object, 'docs', '$path.docs'),
      sourcePath: path,
    );
  }
}
