import 'package:code_builder/code_builder.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_style/dart_style.dart';

import 'generation.dart';
import 'generator/accounts_emitter.dart';
import 'generator/client_emitter.dart';
import 'generator/errors_emitter.dart';
import 'generator/events_emitter.dart';
import 'generator/generator_context.dart';
import 'generator/instructions_emitter.dart';
import 'generator/resolution_emitter.dart';
import 'generator/support_emitter.dart';
import 'generator/types_emitter.dart';
import 'idl.dart';
import 'naming.dart';
import 'validator.dart';

/// Validates immutable IR and orchestrates focused source emitters.
final class DartGenerator {
  /// Creates a generator with replaceable naming and validation strategies.
  const DartGenerator({
    this.naming = const DartNamingStrategy(),
    this.validator = const IdlValidator(),
  });

  /// Strategy used to map wire names to Dart identifiers.
  final NamingStrategy naming;

  /// Semantic validator run before any source is emitted.
  final IdlValidator validator;

  /// Emits a deterministic SDK for [program].
  GenerationOutput generate(
    IdlProgram program, {
    GenerationOptions options = const GenerationOptions(),
    String? sourceDigest,
  }) {
    validator.validate(program);
    final context = GeneratorContext(
      program: program,
      naming: naming,
      sourceDigest: sourceDigest ?? sha256.convert(const <int>[]).toString(),
    );
    final sections = <String, List<Spec>>{
      'support': SupportEmitter(context).emit(),
      'types': TypesEmitter(context).emit(),
      'accounts': AccountsEmitter(context).emit(),
      'instructions': InstructionsEmitter(context).emit(),
      'resolution': ResolutionEmitter(context).emit(),
      'events': EventsEmitter(context).emit(),
      'errors': ErrorsEmitter(context).emit(),
      'client': ClientEmitter(context).emit(),
    };
    if (options.layout == OutputLayout.bundled) {
      return GenerationOutput({
        'program.dart': _library(
          context,
          'Generated transport-neutral SDK for `${program.name}`.',
          const ['dart:async', 'dart:convert', 'dart:typed_data'],
          sections.values.expand((section) => section).toList(growable: false),
        ),
      });
    }
    return GenerationOutput({
      'program.dart': _library(
        context,
        'Generated public API for `${program.name}`.',
        const [],
        const [],
        exports: const [
          '__PROGRAM_STEM___solana_accounts.dart',
          '__PROGRAM_STEM___solana_client.dart',
          '__PROGRAM_STEM___solana_errors.dart',
          '__PROGRAM_STEM___solana_events.dart',
          '__PROGRAM_STEM___solana_instructions.dart',
          '__PROGRAM_STEM___solana_resolution.dart',
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
      ),
      'support.dart': _library(
        context,
        'Generated runtime support for `${program.name}`.',
        const ['dart:async', 'dart:convert', 'dart:typed_data'],
        sections['support']!,
      ),
      'types.dart': _library(
        context,
        'Generated value models for `${program.name}`.',
        const ['dart:typed_data', '__PROGRAM_STEM___solana_support.dart'],
        sections['types']!,
      ),
      'accounts.dart': _library(
        context,
        'Generated account API for `${program.name}`.',
        const [
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
        sections['accounts']!,
      ),
      'instructions.dart': _library(
        context,
        'Generated instruction API for `${program.name}`.',
        const [
          'dart:typed_data',
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
        sections['instructions']!,
      ),
      'resolution.dart': _library(
        context,
        'Generated account resolution API for `${program.name}`.',
        const [
          'dart:convert',
          'dart:typed_data',
          '__PROGRAM_STEM___solana_accounts.dart',
          '__PROGRAM_STEM___solana_instructions.dart',
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
        sections['resolution']!,
      ),
      'events.dart': _library(
        context,
        'Generated event API for `${program.name}`.',
        const [
          'dart:async',
          'dart:convert',
          'dart:typed_data',
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
        sections['events']!,
      ),
      'errors.dart': _library(
        context,
        'Generated program errors for `${program.name}`.',
        const ['__PROGRAM_STEM___solana_support.dart'],
        sections['errors']!,
      ),
      'client.dart': _library(
        context,
        'Generated client facades for `${program.name}`.',
        const [
          '__PROGRAM_STEM___solana_accounts.dart',
          '__PROGRAM_STEM___solana_events.dart',
          '__PROGRAM_STEM___solana_instructions.dart',
          '__PROGRAM_STEM___solana_resolution.dart',
          '__PROGRAM_STEM___solana_support.dart',
          '__PROGRAM_STEM___solana_types.dart',
        ],
        sections['client']!,
      ),
    });
  }

  String _library(
    GeneratorContext context,
    String summary,
    List<String> imports,
    List<Spec> bodies, {
    List<String> exports = const [],
  }) {
    final library = Library(
      (builder) => builder
        ..name = ''
        ..docs.add('/// $summary')
        ..directives.addAll([
          for (final import in imports) Directive.import(import),
          for (final export in exports) Directive.export(export),
        ])
        ..body.addAll(bodies),
    );
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format('${context.header}${library.accept(DartEmitter())}');
  }
}
