import '../idl.dart';
import 'strict_json_reader.dart';
import 'type_body_decoder.dart';
import 'type_expression_decoder.dart';
import 'type_metadata_decoder.dart';

/// Decodes named Anchor type definitions, fields, variants, and generics.
final class AnchorTypeDefinitionDecoder {
  /// Creates a type definition decoder.
  const AnchorTypeDefinitionDecoder(
    this.values,
    this.expressions, {
    this.metadata = const AnchorTypeMetadataDecoder(StrictJsonReader()),
    this.bodies = const AnchorTypeBodyDecoder(
      StrictJsonReader(),
      AnchorTypeExpressionDecoder(StrictJsonReader()),
    ),
  });

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Decoder for nested wire type expressions.
  final AnchorTypeExpressionDecoder expressions;

  /// Decoder for type metadata such as generics and representation.
  final AnchorTypeMetadataDecoder metadata;

  /// Decoder for struct, enum and alias bodies.
  final AnchorTypeBodyDecoder bodies;

  /// Decodes one named type definition.
  IdlTypeDefinition definition(Map<String, Object?> object, String path) {
    values.knownKeys(object, const {
      'name',
      'docs',
      'serialization',
      'repr',
      'generics',
      'type',
    }, path);
    final serialization = metadata.serialization(object, path);
    final representation = metadata.representation(object, '$path.repr');
    final type = values.requiredObject(object, 'type', '$path.type');
    final generics = metadata.generics(object, path);
    return IdlTypeDefinition(
      name: values.requiredString(object, 'name', '$path.name'),
      docs: values.docs(object, 'docs', '$path.docs'),
      body: bodies.body(type, '$path.type'),
      generics: generics.typeGenerics,
      constGenerics: generics.constGenerics,
      serialization: serialization,
      representation: representation,
      sourcePath: path,
    );
  }

  /// Decodes a list of named fields.
  List<IdlField> fields(
    List<Object?> raw,
    String path, {
    bool allowEventIndex = false,
  }) => [
    for (var index = 0; index < raw.length; index++)
      bodies.field(
        values.object(raw[index], '$path[$index]'),
        '$path[$index]',
        allowEventIndex: allowEventIndex,
      ),
  ];
}
