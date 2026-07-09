import '../idl.dart';
import 'discriminator_decoder.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes top-level Anchor event declarations.
final class AnchorEventDefinitionDecoder {
  /// Creates an event definition decoder.
  const AnchorEventDefinitionDecoder(
    this.values,
    this.typeDecoder,
    this.discriminatorDecoder,
  );

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Decoder used for legacy inline event fields.
  final AnchorTypeDecoder typeDecoder;

  /// Decoder used for modern or legacy event discriminators.
  final AnchorDiscriminatorDecoder discriminatorDecoder;

  /// Decodes all event declarations from [rawEvents].
  ///
  /// Legacy inline event field declarations are appended to [types] when they
  /// are not already present.
  List<IdlEventDefinition> decodeAll(
    List<Object?> rawEvents,
    AnchorIdlDialect dialect,
    List<IdlTypeDefinition> types,
  ) {
    final events = <IdlEventDefinition>[];
    for (var index = 0; index < rawEvents.length; index++) {
      final path =
          r'$.events['
          '$index]';
      events.add(
        decode(values.object(rawEvents[index], path), path, dialect, types),
      );
    }
    return events;
  }

  /// Decodes one top-level event declaration.
  IdlEventDefinition decode(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
    List<IdlTypeDefinition> types,
  ) {
    values.knownKeys(object, const {
      'name',
      'docs',
      'discriminator',
      'fields',
    }, path);
    final eventName = values.requiredString(object, 'name', '$path.name');
    final inlineFields = object['fields'];
    if (inlineFields != null) {
      _decodeLegacyInlineFields(object, path, dialect, eventName, types);
    }
    return IdlEventDefinition(
      name: eventName,
      discriminator: discriminatorDecoder.decode(
        object,
        dialect: dialect,
        legacyPrefix: 'event',
        name: eventName,
        path: '$path.discriminator',
      ),
      sourcePath: path,
    );
  }

  void _decodeLegacyInlineFields(
    Map<String, Object?> object,
    String path,
    AnchorIdlDialect dialect,
    String eventName,
    List<IdlTypeDefinition> types,
  ) {
    if (dialect != AnchorIdlDialect.legacy) {
      throw IdlFormatException(
        'Modern event definitions must reference an entry in types.',
        '$path.fields',
      );
    }
    if (types.any((type) => type.name == eventName)) return;
    final fields = values.requiredList(object, 'fields', '$path.fields');
    types.add(
      IdlTypeDefinition(
        name: eventName,
        docs: values.docs(object, 'docs', '$path.docs'),
        body: IdlStructBody(
          fields: typeDecoder.fields(
            fields,
            '$path.fields',
            allowEventIndex: true,
          ),
          tupleFields: const [],
        ),
        generics: const [],
        sourcePath: path,
      ),
    );
  }
}
