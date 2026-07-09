import '../idl.dart';
import 'strict_json_reader.dart';

/// Decodes Anchor custom error declarations.
final class AnchorErrorDefinitionDecoder {
  /// Creates an error definition decoder using [values].
  const AnchorErrorDefinitionDecoder(this.values);

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Decodes all custom error declarations from [rawErrors].
  List<IdlErrorDefinition> decodeAll(List<Object?> rawErrors) {
    final errors = <IdlErrorDefinition>[];
    for (var index = 0; index < rawErrors.length; index++) {
      final path =
          r'$.errors['
          '$index]';
      errors.add(decode(values.object(rawErrors[index], path), path));
    }
    return errors;
  }

  /// Decodes one custom error declaration.
  IdlErrorDefinition decode(Map<String, Object?> object, String path) {
    values.knownKeys(object, const {'code', 'name', 'msg'}, path);
    final name = values.requiredString(object, 'name', '$path.name');
    return IdlErrorDefinition(
      code: values.integer(
        values.requiredValue(object, 'code', '$path.code'),
        '$path.code',
      ),
      name: name,
      message:
          values.optionalPossiblyEmptyString(object, 'msg', '$path.msg') ??
          name,
      sourcePath: path,
    );
  }
}
