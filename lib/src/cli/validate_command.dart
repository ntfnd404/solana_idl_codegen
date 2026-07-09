import 'dart:io';

import 'package:args/command_runner.dart';

import '../solana_idl_generator.dart';
import 'diagnostic_writer.dart';

/// Implements the internal `validate` CLI command.
final class ValidateCommand extends Command<int> {
  /// Creates a validation command with replaceable collaborators.
  ValidateCommand(
    this.output,
    this.errors, {
    this.generator = const SolanaIdlGenerator(),
    this.diagnostics = const DiagnosticWriter(),
  }) {
    argParser.addOption(
      'diagnostics',
      allowed: const ['human', 'json'],
      defaultsTo: 'human',
    );
  }

  /// Standard output destination.
  final IOSink output;

  /// Standard error destination.
  final IOSink errors;

  /// Public generator facade used for validation.
  final SolanaIdlGenerator generator;

  /// Diagnostic presentation strategy.
  final DiagnosticWriter diagnostics;

  @override
  String get description => 'Validate one or more Anchor IDL documents.';

  @override
  String get name => 'validate';

  @override
  Future<int> run() async {
    final inputs = argResults!.rest;
    if (inputs.isEmpty) {
      throw UsageException('Expected at least one IDL path.', usage);
    }
    var valid = true;
    for (final input in inputs) {
      final result = generator.validateString(
        await File(input).readAsString(),
        sourceName: input,
      );
      if (!result.isValid) valid = false;
      diagnostics.write(
        result.diagnostics,
        argResults!['diagnostics'] as String,
        result.isValid ? output : errors,
      );
      if (result.isValid) output.writeln('VALID $input');
    }
    return valid ? 0 : 1;
  }
}
