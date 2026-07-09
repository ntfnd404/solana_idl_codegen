import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'diagnostics.dart';
import 'generation.dart';
import 'generator.dart';
import 'naming.dart';
import 'parser/anchor_idl_parser.dart';
import 'parser/idl_format_exception.dart';
import 'validator.dart';

/// Public facade for validating Anchor IDLs and generating Dart SDKs.
final class SolanaIdlGenerator {
  /// Creates a generator facade with resource [parseLimits].
  const SolanaIdlGenerator({this.parseLimits = IdlParseLimits.defaults});

  /// Resource limits applied to untrusted IDL input.
  final IdlParseLimits parseLimits;

  /// Validates [source] without throwing for IDL validation failures.
  ValidationResult validateString(String source, {String? sourceName}) {
    try {
      final parsed = AnchorIdlParser(limits: parseLimits).parseDocument(source);
      try {
        const IdlValidator().validate(parsed.program);
      } on IdlFormatException catch (error) {
        throw error.located(parsed.sourceMap.locationFor);
      }
      return ValidationResult(const []);
    } on IdlFormatException catch (error) {
      return ValidationResult([_diagnostic(error, sourceName: sourceName)]);
    } on FormatException catch (error) {
      return ValidationResult([
        IdlDiagnostic(
          code: 'IDL_JSON_SYNTAX',
          severity: DiagnosticSeverity.error,
          message: error.message,
          jsonPath: r'$',
          sourceName: sourceName,
          location: error.offset == null
              ? const SourceLocation(line: 1, column: 1)
              : _location(source, error.offset!),
        ),
      ]);
    }
  }

  /// Validates [source] and generates a deterministic transport-neutral SDK.
  ///
  /// Throws [GenerationException] with ordered diagnostics when validation
  /// fails. Programming and configuration errors are reported as
  /// [ArgumentError].
  GenerationOutput generateString(
    String source, {
    required GenerationOptions options,
    String? sourceName,
  }) {
    _validateOptions(options);
    try {
      final parsed = AnchorIdlParser(limits: parseLimits).parseDocument(source);
      final program = parsed.program;
      try {
        const IdlValidator().validate(program);
      } on IdlFormatException catch (error) {
        throw error.located(parsed.sourceMap.locationFor);
      }
      final automaticPrefix = const DartNamingStrategy().typeName(program.name);
      final prefix = options.typePrefix == 'auto'
          ? automaticPrefix
          : options.typePrefix;
      return DartGenerator(
        naming: AffixedNamingStrategy(
          prefix: prefix,
          suffix: options.typeSuffix,
        ),
      ).generate(
        program,
        options: options,
        sourceDigest: sha256.convert(utf8.encode(source)).toString(),
      );
    } on IdlFormatException catch (error) {
      throw GenerationException([_diagnostic(error, sourceName: sourceName)]);
    }
  }

  IdlDiagnostic _diagnostic(
    IdlFormatException error, {
    required String? sourceName,
  }) => IdlDiagnostic(
    code: error.code,
    severity: DiagnosticSeverity.error,
    message: error.message,
    jsonPath: error.path,
    sourceName: sourceName,
    location: error.location ?? const SourceLocation(line: 1, column: 1),
    related: error.related
        .map((item) => _diagnostic(item, sourceName: sourceName))
        .toList(growable: false),
    cause: error.causeDescription,
  );

  SourceLocation _location(String source, int offset) {
    var line = 1;
    var column = 1;
    final end = offset.clamp(0, source.length);
    for (var index = 0; index < end; index++) {
      if (source.codeUnitAt(index) == 10) {
        line++;
        column = 1;
      } else {
        column++;
      }
    }
    return SourceLocation(line: line, column: column);
  }

  void _validateOptions(GenerationOptions options) {
    final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    if (options.typePrefix != 'auto' &&
        !identifier.hasMatch(options.typePrefix)) {
      throw ArgumentError.value(
        options.typePrefix,
        'options.typePrefix',
        'Expected "auto" or a non-empty Dart identifier.',
      );
    }
    if (options.typeSuffix.isNotEmpty &&
        !identifier.hasMatch(options.typeSuffix)) {
      throw ArgumentError.value(
        options.typeSuffix,
        'options.typeSuffix',
        'Expected an empty string or a Dart identifier.',
      );
    }
  }
}
