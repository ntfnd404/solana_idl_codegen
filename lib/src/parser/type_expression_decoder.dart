import '../idl.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';

/// Decodes Anchor wire type expressions.
final class AnchorTypeExpressionDecoder {
  /// Creates a type expression decoder backed by [values].
  const AnchorTypeExpressionDecoder(this.values);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  static const _primitiveNames = {
    'bool',
    'u8',
    'i8',
    'u16',
    'i16',
    'u32',
    'i32',
    'f32',
    'u64',
    'i64',
    'f64',
    'u128',
    'i128',
    'u256',
    'i256',
    'bytes',
    'string',
    'pubkey',
  };

  /// Decodes one Anchor wire type expression.
  IdlType typeExpression(Object? value, String path) {
    if (value is String) {
      final normalized = value == 'publicKey' ? 'pubkey' : value;
      if (_primitiveNames.contains(normalized)) {
        return IdlPrimitiveType(normalized);
      }
      throw IdlFormatException('Unknown primitive "$value".', path);
    }
    final object = values.object(value, path);
    if (object.length != 1) {
      throw IdlFormatException(
        'Type object must contain exactly one type key.',
        path,
      );
    }
    if (object.containsKey('option')) {
      return IdlOptionType(typeExpression(object['option'], '$path.option'));
    }
    if (object.containsKey('coption')) {
      return IdlCOptionType(typeExpression(object['coption'], '$path.coption'));
    }
    if (object.containsKey('vec')) {
      return IdlVectorType(typeExpression(object['vec'], '$path.vec'));
    }
    if (object.containsKey('array')) {
      return _array(object['array'], '$path.array');
    }
    if (object.containsKey('defined')) {
      return _defined(object['defined'], '$path.defined');
    }
    if (object.containsKey('generic')) {
      return IdlGenericType(
        values.nonEmptyString(object['generic'], '$path.generic'),
      );
    }
    throw IdlFormatException(
      'Unknown type constructor "${object.keys.single}".',
      path,
    );
  }

  IdlType _array(Object? raw, String path) {
    final array = values.list(raw, path);
    if (array.length != 2) {
      throw IdlFormatException(
        'Array must contain a type and an integer length.',
        path,
      );
    }
    if (array[1] is String) {
      return IdlGenericArrayType(
        typeExpression(array[0], '$path[0]'),
        values.nonEmptyString(array[1], '$path[1]'),
      );
    }
    if (array[1] is Map) {
      final length = values.object(array[1], '$path[1]');
      values.knownKeys(length, const {'generic'}, '$path[1]');
      return IdlGenericArrayType(
        typeExpression(array[0], '$path[0]'),
        values.requiredString(length, 'generic', '$path[1].generic'),
      );
    }
    final length = values.integer(array[1], '$path[1]');
    if (length < 0) {
      throw IdlFormatException('Array length cannot be negative.', '$path[1]');
    }
    return IdlArrayType(typeExpression(array[0], '$path[0]'), length);
  }

  IdlDefinedType _defined(Object? raw, String path) {
    if (raw is String) return IdlDefinedType(raw, const []);
    final definition = values.object(raw, path);
    values.knownKeys(definition, const {'name', 'generics'}, path);
    final rawGenerics = values.optionalList(
      definition,
      'generics',
      '$path.generics',
    );
    final typeGenerics = <IdlType>[];
    final constGenerics = <int>[];
    for (var index = 0; index < rawGenerics.length; index++) {
      final genericPath = '$path.generics[$index]';
      final rawGeneric = rawGenerics[index];
      if (rawGeneric is Map) {
        final generic = values.object(rawGeneric, genericPath);
        if (generic['kind'] == 'const') {
          values.knownKeys(generic, const {'kind', 'value'}, genericPath);
          constGenerics.add(
            values.integer(
              values.requiredValue(generic, 'value', '$genericPath.value'),
              '$genericPath.value',
            ),
          );
          continue;
        }
      }
      typeGenerics.add(genericArgument(rawGeneric, genericPath));
    }
    return IdlDefinedType(
      values.requiredString(definition, 'name', '$path.name'),
      typeGenerics,
      constGenerics: constGenerics,
    );
  }

  /// Decodes a generic argument as either a type or a typed wrapper object.
  IdlType genericArgument(Object? raw, String path) {
    if (raw is Map) {
      final object = values.object(raw, path);
      if (object.containsKey('kind') || object.containsKey('type')) {
        values.knownKeys(object, const {'kind', 'type'}, path);
        final kind = values.optionalString(object, 'kind', '$path.kind');
        if (kind != null && kind != 'type') {
          throw IdlFormatException(
            'Unresolved const generic arguments are unsupported.',
            '$path.kind',
            code: 'IDL_CONST_GENERIC_UNRESOLVED',
          );
        }
        return typeExpression(
          values.requiredValue(object, 'type', '$path.type'),
          '$path.type',
        );
      }
    }
    return typeExpression(raw, path);
  }
}
