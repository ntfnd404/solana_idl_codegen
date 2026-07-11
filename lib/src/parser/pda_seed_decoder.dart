import '../idl.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes PDA seed declarations from Anchor account metadata.
final class AnchorPdaSeedDecoder {
  /// Creates a PDA seed decoder.
  const AnchorPdaSeedDecoder(this.values, this.types);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Anchor type expression decoder used by seed type declarations.
  final AnchorTypeDecoder types;

  /// Decodes one PDA seed declaration.
  IdlSeed seed(Map<String, Object?> object, String path) {
    values.knownKeys(object, const {
      'kind',
      'type',
      'value',
      'path',
      'account',
    }, path);
    final kind = values.requiredString(object, 'kind', '$path.kind');
    final valueType = object.containsKey('type') && object['type'] != null
        ? types.typeExpression(object['type'], '$path.type')
        : null;
    switch (kind) {
      case 'const':
        return _constSeed(object, path, valueType);
      case 'arg':
      case 'account':
        return IdlPathSeed(
          kind: kind,
          path: values.requiredString(object, 'path', '$path.path'),
          account: values.optionalString(object, 'account', '$path.account'),
          valueType: valueType,
          sourcePath: path,
        );
      default:
        throw IdlFormatException('Unknown seed kind "$kind".', '$path.kind');
    }
  }

  IdlConstSeed _constSeed(
    Map<String, Object?> object,
    String path,
    IdlType? valueType,
  ) {
    if (!object.containsKey('value') || object['value'] == null) {
      throw IdlFormatException(
        'Constant seed value is required.',
        '$path.value',
      );
    }
    final value = object['value']!;
    if (value is List<Object?>) {
      return IdlConstSeed(
        value: IdlBytesConstValue([
          for (var index = 0; index < value.length; index++)
            values.byte(value[index], '$path.value[$index]'),
        ]),
        valueType: valueType,
        sourcePath: path,
      );
    }
    if (value is! String && value is! int && value is! bool) {
      throw IdlFormatException(
        'Unsupported constant seed JSON value.',
        '$path.value',
      );
    }
    return IdlConstSeed(
      value: switch (value) {
        String() => IdlStringConstValue(value),
        int() => IdlIntegerConstValue(BigInt.from(value)),
        bool() => IdlBooleanConstValue(value),
        _ => throw StateError('Validated constant seed type.'),
      },
      valueType: valueType,
      sourcePath: path,
    );
  }
}
