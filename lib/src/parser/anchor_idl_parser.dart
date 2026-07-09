import 'dart:convert';

import '../generation.dart';
import '../idl.dart';
import 'anchor_program_decoder.dart';
import 'duplicate_aware_json_decoder.dart';
import 'idl_format_exception.dart';
import 'idl_parser.dart';
import 'parsed_idl_document.dart';
import 'source_location_calculator.dart';
import 'strict_json_reader.dart';

/// Decodes supported Anchor IDL dialects into the immutable generator IR.
///
/// The parser is intentionally strict at the wire boundary. Unknown fields,
/// incorrect JSON types, missing modern discriminators, and unsupported schema
/// constructs fail with an exact JSON path instead of being ignored.
final class AnchorIdlParser implements IdlParser {
  /// Creates a stateless Anchor IDL parser.
  const AnchorIdlParser({
    this.limits = IdlParseLimits.defaults,
    this.values = const StrictJsonReader(),
    this.programDecoder = const AnchorProgramDecoder(),
    this.locationCalculator = const SourceLocationCalculator(),
  });

  /// Resource limits applied while parsing.
  final IdlParseLimits limits;

  /// Strict decoded JSON accessor.
  final StrictJsonReader values;

  /// Decoder responsible for strict JSON object to IR conversion.
  final AnchorProgramDecoder programDecoder;

  /// Converts syntax-error offsets into line/column locations.
  final SourceLocationCalculator locationCalculator;

  @override
  IdlProgram parseString(String source) => parseDocument(source).program;

  /// Parses [source] and retains locations for subsequent semantic validation.
  ParsedIdlDocument parseDocument(String source) {
    if (utf8.encode(source).length > limits.maxSourceBytes) {
      throw const IdlFormatException(
        'IDL source exceeds maxSourceBytes.',
        r'$',
        code: 'IDL_LIMIT_SOURCE_BYTES',
      );
    }
    final sourceMap = DuplicateAwareJsonScanner(source, limits).scan();
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw IdlFormatException(
        error.message,
        r'$',
        code: 'IDL_JSON_SYNTAX',
        location: error.offset == null
            ? null
            : locationCalculator.locationFor(source, error.offset!),
      );
    }
    try {
      return ParsedIdlDocument(
        parseJson(values.object(decoded, r'$')),
        sourceMap,
      );
    } on IdlFormatException catch (error) {
      throw error.located(sourceMap.locationFor);
    }
  }

  @override
  IdlProgram parseJson(Map<String, Object?> json) =>
      programDecoder.decode(json);
}
