import '../idl.dart';
import 'strict_json_reader.dart';
import 'type_definition_decoder.dart';
import 'type_expression_decoder.dart';

/// Facade that decodes Anchor type declarations and wire type expressions.
final class AnchorTypeDecoder {
  /// Creates a type decoder backed by the strict JSON [values] reader.
  const AnchorTypeDecoder(this.values);

  /// Strict JSON value reader shared with the parser facade.
  final StrictJsonReader values;

  /// Decodes one named type definition.
  IdlTypeDefinition definition(Map<String, Object?> object, String path) =>
      _definitions.definition(object, path);

  /// Decodes a list of named fields.
  List<IdlField> fields(
    List<Object?> raw,
    String path, {
    bool allowEventIndex = false,
  }) => _definitions.fields(raw, path, allowEventIndex: allowEventIndex);

  /// Decodes one Anchor wire type expression.
  IdlType typeExpression(Object? value, String path) =>
      _expressions.typeExpression(value, path);

  AnchorTypeExpressionDecoder get _expressions =>
      AnchorTypeExpressionDecoder(values);

  AnchorTypeDefinitionDecoder get _definitions =>
      AnchorTypeDefinitionDecoder(values, _expressions);
}
