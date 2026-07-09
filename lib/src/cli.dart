import 'dart:io';

import 'package:args/command_runner.dart';

import 'cli/clean_command.dart';
import 'cli/generate_command.dart';
import 'cli/output_transaction.dart';
import 'cli/validate_command.dart';

/// Runs the command-line facade and returns a documented process exit code.
Future<int> runCli(
  List<String> arguments, {
  IOSink? stdoutSink,
  IOSink? stderrSink,
}) async {
  final output = stdoutSink ?? stdout;
  final errors = stderrSink ?? stderr;
  final runner =
      CommandRunner<int>(
          'solana_idl_codegen',
          'Strict Anchor IDL to transport-neutral Dart SDK generator.',
        )
        ..addCommand(ValidateCommand(output, errors))
        ..addCommand(GenerateCommand(output, errors))
        ..addCommand(CleanCommand(output));
  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    errors.writeln(error);
    return 2;
  } on OutputRecoveryException catch (error) {
    errors.writeln(error);
    return 4;
  } on FileSystemException catch (error) {
    errors.writeln(error);
    return 1;
  } on Object catch (error) {
    errors.writeln(error);
    return 1;
  }
}
