import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../diagnostics.dart';
import '../generation.dart';
import '../solana_idl_generator.dart';
import 'diagnostic_writer.dart';
import 'generated_output_scanner.dart';
import 'output_planner.dart';
import 'output_transaction.dart';

/// Implements deterministic batch SDK generation.
final class GenerateCommand extends Command<int> {
  /// Creates a generation command with replaceable collaborators.
  GenerateCommand(
    this.output,
    this.errors, {
    this.generator = const SolanaIdlGenerator(),
    this.scanner = const GeneratedOutputScanner(),
    this.planner = const CliOutputPlanner(),
    this.diagnostics = const DiagnosticWriter(),
    OutputTransactionWriter? writer,
  }) : writer =
           writer ??
           const OutputTransactionWriter(scanner: GeneratedOutputScanner()) {
    argParser
      ..addOption('input-root', defaultsTo: 'lib/idl')
      ..addOption('output', defaultsTo: 'lib/generated')
      ..addOption(
        'layout',
        allowed: const ['bundled', 'modular'],
        defaultsTo: 'bundled',
      )
      ..addOption('type-prefix', defaultsTo: 'auto')
      ..addOption('type-suffix', defaultsTo: '')
      ..addFlag('check', negatable: false)
      ..addOption(
        'diagnostics',
        allowed: const ['human', 'json'],
        defaultsTo: 'human',
      );
  }

  /// Standard output destination.
  final IOSink output;

  /// Standard error destination.
  final IOSink errors;

  /// Public generator facade.
  final SolanaIdlGenerator generator;

  /// Generated-file ownership scanner.
  final GeneratedOutputScanner scanner;

  /// Safe output planning policy.
  final CliOutputPlanner planner;

  /// Diagnostic presentation strategy.
  final DiagnosticWriter diagnostics;

  /// Transactional output writer.
  final OutputTransactionWriter writer;

  @override
  String get description => 'Generate SDKs for one or more IDLs as one batch.';

  @override
  String get name => 'generate';

  @override
  Future<int> run() async {
    final inputs = argResults!.rest;
    if (inputs.isEmpty) {
      throw UsageException('Expected at least one IDL path.', usage);
    }
    final inputRoot = Directory(argResults!['input-root'] as String).absolute;
    final configuredOutputRoot = Directory(
      argResults!['output'] as String,
    ).absolute;
    final canonicalInputRoot = await inputRoot.resolveSymbolicLinks();
    final canonicalOutputRoot = await planner.canonicalDestination(
      configuredOutputRoot,
    );
    final outputRoot = Directory(canonicalOutputRoot);
    final layout = argResults!['layout'] == 'modular'
        ? OutputLayout.modular
        : OutputLayout.bundled;
    final typePrefix = argResults!['type-prefix'] as String;
    final typeSuffix = argResults!['type-suffix'] as String;
    final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    if (typePrefix != 'auto' && !identifier.hasMatch(typePrefix)) {
      throw UsageException(
        '--type-prefix must be "auto" or a non-empty Dart identifier.',
        usage,
      );
    }
    if (typeSuffix.isNotEmpty && !identifier.hasMatch(typeSuffix)) {
      throw UsageException(
        '--type-suffix must be empty or a Dart identifier.',
        usage,
      );
    }
    final options = GenerationOptions(
      layout: layout,
      typePrefix: typePrefix,
      typeSuffix: typeSuffix,
    );
    final planned = <String, String>{};
    final outputStems = <String>{};
    for (final inputArgument in inputs) {
      final input = File(inputArgument).absolute;
      final canonicalInput = await input.resolveSymbolicLinks();
      planner.requireInside(canonicalInput, canonicalInputRoot, 'input');
      final relative = path.relative(input.path, from: inputRoot.path);
      planner.requireInside(
        path.join(canonicalOutputRoot, relative),
        canonicalOutputRoot,
        'output',
      );
      final stem = path.withoutExtension(relative);
      outputStems.add(path.join(canonicalOutputRoot, stem));
      final sourceStem = path.basename(stem);
      final GenerationOutput generated;
      try {
        generated = generator.generateString(
          await input.readAsString(),
          options: options,
          sourceName: input.path,
        );
      } on GenerationException catch (error) {
        diagnostics.write(
          error.diagnostics,
          argResults!['diagnostics'] as String,
          errors,
        );
        return 1;
      }
      final resolved = planner.resolveOutputs(
        generated,
        canonicalOutputRoot,
        stem,
        sourceStem,
        layout,
      );
      for (final entry in resolved.entries) {
        if (planned.containsKey(entry.key)) {
          throw UsageException('Output collision for ${entry.key}.', usage);
        }
        planned[entry.key] = entry.value;
      }
    }
    if (argResults!['check'] as bool) {
      await writer.verifyNoPendingRecovery(outputRoot);
      final stale = await scanner.staleForStems(
        outputStems,
        planned.keys.toSet(),
      );
      var drift = stale.isNotEmpty;
      for (final entry in planned.entries) {
        final file = File(entry.key);
        if (!await file.exists() || await file.readAsString() != entry.value) {
          output.writeln('DRIFT ${entry.key}');
          drift = true;
        }
      }
      for (final file in stale) {
        output.writeln('STALE ${file.path}');
      }
      return drift ? 3 : 0;
    }
    await writer.recover(outputRoot);
    final stale = await scanner.staleForStems(
      outputStems,
      planned.keys.toSet(),
    );
    await writer.write(outputRoot, planned, stale);
    for (final target in planned.keys) {
      output.writeln('WROTE $target');
    }
    return 0;
  }
}
