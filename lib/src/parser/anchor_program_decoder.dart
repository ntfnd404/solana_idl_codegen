import '../generation.dart';
import '../idl.dart';
import 'account_decoder.dart';
import 'account_definition_decoder.dart';
import 'constant_decoder.dart';
import 'dialect_detector.dart';
import 'discriminator_decoder.dart';
import 'error_definition_decoder.dart';
import 'event_definition_decoder.dart';
import 'idl_format_exception.dart';
import 'idl_limits_validator.dart';
import 'instruction_decoder.dart';
import 'legacy_normalizer.dart';
import 'metadata_decoder.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes one strict JSON object into the immutable Anchor IDL IR.
final class AnchorProgramDecoder {
  /// Creates a program decoder from focused declaration decoders.
  const AnchorProgramDecoder({
    this.limits = IdlParseLimits.defaults,
    this.dialectDetector = const AnchorDialectDetector(),
    this.values = const StrictJsonReader(),
    this.typeDecoder = const AnchorTypeDecoder(StrictJsonReader()),
    this.constantDecoder = const AnchorConstantDecoder(
      StrictJsonReader(),
      AnchorTypeDecoder(StrictJsonReader()),
    ),
    this.metadataDecoder = const AnchorMetadataDecoder(StrictJsonReader()),
    this.accountDefinitionDecoder = const AnchorAccountDefinitionDecoder(
      StrictJsonReader(),
      AnchorTypeDecoder(StrictJsonReader()),
      AnchorDiscriminatorDecoder(StrictJsonReader(), LegacyIdlNormalizer()),
    ),
    this.eventDefinitionDecoder = const AnchorEventDefinitionDecoder(
      StrictJsonReader(),
      AnchorTypeDecoder(StrictJsonReader()),
      AnchorDiscriminatorDecoder(StrictJsonReader(), LegacyIdlNormalizer()),
    ),
    this.errorDefinitionDecoder = const AnchorErrorDefinitionDecoder(
      StrictJsonReader(),
    ),
    this.instructionDecoder = const AnchorInstructionDecoder(
      StrictJsonReader(),
      AnchorTypeDecoder(StrictJsonReader()),
      AnchorAccountDecoder(
        StrictJsonReader(),
        AnchorTypeDecoder(StrictJsonReader()),
      ),
      AnchorDiscriminatorDecoder(StrictJsonReader(), LegacyIdlNormalizer()),
      LegacyIdlNormalizer(),
    ),
  });

  /// Resource limits applied after IR construction.
  final IdlParseLimits limits;

  /// Strategy used to reject ambiguous IDL dialects.
  final AnchorDialectDetector dialectDetector;

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Decoder responsible for Anchor type declarations and expressions.
  final AnchorTypeDecoder typeDecoder;

  /// Decoder responsible for IDL constant declarations.
  final AnchorConstantDecoder constantDecoder;

  /// Decoder responsible for metadata validation.
  final AnchorMetadataDecoder metadataDecoder;

  /// Decoder responsible for top-level account declarations.
  final AnchorAccountDefinitionDecoder accountDefinitionDecoder;

  /// Decoder responsible for top-level event declarations.
  final AnchorEventDefinitionDecoder eventDefinitionDecoder;

  /// Decoder responsible for custom error declarations.
  final AnchorErrorDefinitionDecoder errorDefinitionDecoder;

  /// Decoder responsible for complete instruction declarations.
  final AnchorInstructionDecoder instructionDecoder;

  /// Decodes [json] into an [IdlProgram].
  IdlProgram decode(Map<String, Object?> json) {
    values.knownKeys(json, const {
      'address',
      'metadata',
      'docs',
      'name',
      'version',
      'instructions',
      'accounts',
      'events',
      'errors',
      'types',
      'constants',
    }, r'$');
    final metadata = values.optionalObject(json, 'metadata', r'$.metadata');
    final rawSpec = values.optionalString(metadata, 'spec', r'$.metadata.spec');
    final dialect = dialectDetector.detect(json, metadata);
    metadataDecoder.validate(metadata, dialect);
    if (dialect == AnchorIdlDialect.modern) {
      for (final legacyKey in const {'name', 'version'}) {
        if (json.containsKey(legacyKey)) {
          throw IdlFormatException(
            'Modern IDL cannot contain legacy top-level "$legacyKey".',
            r'$.'
                '$legacyKey',
            code: 'IDL_DIALECT_MIXED',
          );
        }
      }
    }

    final name =
        values.optionalString(metadata, 'name', r'$.metadata.name') ??
        values.optionalString(json, 'name', r'$.name') ??
        values.missing('program name', r'$.metadata.name');
    final version =
        values.optionalString(metadata, 'version', r'$.metadata.version') ??
        values.optionalString(json, 'version', r'$.version') ??
        '0.0.0';
    final address =
        values.optionalString(json, 'address', r'$.address') ??
        values.optionalString(metadata, 'address', r'$.metadata.address') ??
        values.missing('program address', r'$.address');

    final constants = _constants(json);
    final types = _types(json);
    final accounts = accountDefinitionDecoder.decodeAll(
      values.optionalList(json, 'accounts', r'$.accounts'),
      dialect,
      types,
    );
    final events = eventDefinitionDecoder.decodeAll(
      values.optionalList(json, 'events', r'$.events'),
      dialect,
      types,
    );
    final instructions = _instructions(json, dialect);
    final errors = errorDefinitionDecoder.decodeAll(
      values.optionalList(json, 'errors', r'$.errors'),
    );

    final program = IdlProgram(
      name: name,
      version: version,
      spec: rawSpec ?? 'legacy',
      address: address,
      docs: values.docs(json, 'docs', r'$.docs'),
      instructions: instructions,
      accounts: accounts,
      events: events,
      errors: errors,
      constants: constants,
      types: types,
      dialect: dialect,
    );
    IdlLimitsValidator(limits).validate(program);
    return program;
  }

  List<IdlConstantDefinition> _constants(Map<String, Object?> json) {
    final constants = <IdlConstantDefinition>[];
    final rawConstants = values.optionalList(json, 'constants', r'$.constants');
    for (var index = 0; index < rawConstants.length; index++) {
      final path =
          r'$.constants['
          '$index]';
      constants.add(
        constantDecoder.definition(
          values.object(rawConstants[index], path),
          path,
        ),
      );
    }
    return constants;
  }

  List<IdlTypeDefinition> _types(Map<String, Object?> json) {
    final types = <IdlTypeDefinition>[];
    final rawTypes = values.optionalList(json, 'types', r'$.types');
    for (var index = 0; index < rawTypes.length; index++) {
      final path =
          r'$.types['
          '$index]';
      types.add(
        typeDecoder.definition(values.object(rawTypes[index], path), path),
      );
    }
    return types;
  }

  List<IdlInstruction> _instructions(
    Map<String, Object?> json,
    AnchorIdlDialect dialect,
  ) {
    final instructions = <IdlInstruction>[];
    final rawInstructions = values.requiredList(
      json,
      'instructions',
      r'$.instructions',
    );
    for (var index = 0; index < rawInstructions.length; index++) {
      final path =
          r'$.instructions['
          '$index]';
      instructions.add(
        instructionDecoder.decode(
          values.object(rawInstructions[index], path),
          path,
          dialect,
        ),
      );
    }
    return instructions;
  }
}
