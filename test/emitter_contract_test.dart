import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:code_builder/code_builder.dart';
import 'package:crypto/crypto.dart';
import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:solana_idl_codegen/src/generator/accounts_emitter.dart';
import 'package:solana_idl_codegen/src/generator/client_emitter.dart';
import 'package:solana_idl_codegen/src/generator/errors_emitter.dart';
import 'package:solana_idl_codegen/src/generator/events_emitter.dart';
import 'package:solana_idl_codegen/src/generator/generator_context.dart';
import 'package:solana_idl_codegen/src/generator/instructions_emitter.dart';
import 'package:solana_idl_codegen/src/generator/resolution_emitter.dart';
import 'package:solana_idl_codegen/src/generator/section_emitter.dart';
import 'package:solana_idl_codegen/src/generator/support_emitter.dart';
import 'package:solana_idl_codegen/src/generator/types_emitter.dart';
import 'package:solana_idl_codegen/src/naming.dart';
import 'package:solana_idl_codegen/src/parser/anchor_idl_parser.dart';
import 'package:test/test.dart';

void main() {
  test('section emitters never return raw Code declarations', () {
    final source = File('test/fixtures/full_types.json').readAsStringSync();
    final context = GeneratorContext(
      program: const AnchorIdlParser().parseString(source),
      naming: const DartNamingStrategy(),
      sourceDigest: sha256.convert(source.codeUnits).toString(),
    );
    final emitters = <SectionEmitter>[
      SupportEmitter(context),
      TypesEmitter(context),
      AccountsEmitter(context),
      InstructionsEmitter(context),
      ResolutionEmitter(context),
      EventsEmitter(context),
      ErrorsEmitter(context),
      ClientEmitter(context),
    ];

    for (final emitter in emitters) {
      expect(
        emitter.emit().whereType<Code>(),
        isEmpty,
        reason:
            '${emitter.runtimeType} returned raw Code as a top-level declaration.',
      );
    }
  });

  test('bundled and modular layouts contain identical declarations', () {
    final source = File('test/fixtures/full_types.json').readAsStringSync();
    const generator = SolanaIdlGenerator();
    final bundled = generator.generateString(
      source,
      options: const GenerationOptions(),
    );
    final modular = generator.generateString(
      source,
      options: const GenerationOptions(layout: OutputLayout.modular),
    );

    final bundledDeclarations = _declarations(bundled.files['program.dart']!);
    final modularDeclarations = [
      for (final entry in modular.files.entries)
        if (entry.key != 'program.dart') ..._declarations(entry.value),
    ];

    expect(modularDeclarations, bundledDeclarations);
  });

  test('generated SDK has no forbidden runtime imports or dynamic', () {
    final source = File('test/fixtures/full_types.json').readAsStringSync();
    const generator = SolanaIdlGenerator();
    for (final output in [
      generator.generateString(source, options: const GenerationOptions()),
      generator.generateString(
        source,
        options: const GenerationOptions(layout: OutputLayout.modular),
      ),
    ]) {
      for (final entry in output.files.entries) {
        final dart = entry.value;
        expect(
          dart.startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND.\n'),
          isTrue,
          reason: '${entry.key} is missing the generated-code header.',
        );
        expect(
          dart,
          contains('// tool: solana_idl_codegen'),
          reason: '${entry.key} is missing the stable tool marker.',
        );
        expect(
          dart,
          isNot(
            contains(
              RegExp(r"import 'package:(solana|anchor|solana_idl_codegen)"),
            ),
          ),
          reason: '${entry.key} imports forbidden runtime packages.',
        );
        expect(
          dart,
          isNot(contains(RegExp(r"import 'dart:io'"))),
          reason: '${entry.key} imports dart:io.',
        );
        expect(
          dart,
          isNot(contains(RegExp(r'\bdynamic\b'))),
          reason: '${entry.key} contains dynamic.',
        );
      }
    }
  });
}

List<String> _declarations(String source) => parseString(
  content: source,
  throwIfDiagnostics: true,
).unit.declarations.map((declaration) => declaration.toSource()).toList();
