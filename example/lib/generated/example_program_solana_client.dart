// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated client facades for `example_program`.
library;

import 'example_program_solana_accounts.dart';
import 'example_program_solana_events.dart';
import 'example_program_solana_instructions.dart';
import 'example_program_solana_resolution.dart';
import 'example_program_solana_support.dart';
import 'example_program_solana_types.dart';

/// Instruction construction facade.
final class ExampleProgramInstructionsClient {
  /// Creates a stateless instruction facade.
  const ExampleProgramInstructionsClient();

  /// Builds `create_message` from a prepared request.
  ExampleProgramInstruction createMessage(
    ExampleProgramCreateMessageRequest request,
  ) => request.instruction();

  /// Builds `read_message` from a prepared request.
  ExampleProgramInstruction readMessage(
    ExampleProgramReadMessageRequest request,
  ) => request.instruction();
}

/// Typed read-only instruction simulation client.
final class ExampleProgramViewClient {
  /// Creates a view client from a simulation capability.
  const ExampleProgramViewClient(this.simulator);

  /// Single-instruction simulation capability.
  final ExampleProgramTransactionSimulator simulator;

  /// Simulates `read_message` and decodes exact return data.
  Future<ExampleProgramMessage> readMessage(
    ExampleProgramReadMessageRequest request,
  ) async {
    final result = await simulator.simulate(request.instruction());
    if (result.failure != null) {
      throw ExampleProgramViewException(
        code: 'VIEW_SIMULATION_FAILED',
        message: 'View simulation failed: ${result.failure!.message}',
      );
    }
    final owner = result.returnProgramAddress;
    final data = result.returnData;
    if (owner != ExampleProgramProgram.programAddress) {
      throw const ExampleProgramViewException(
        code: 'VIEW_PROGRAM_MISMATCH',
        message: 'View return program mismatch.',
      );
    }
    if (data == null) {
      throw const ExampleProgramViewException(
        code: 'VIEW_RETURN_DATA_MISSING',
        message: 'View did not return data.',
      );
    }
    return ExampleProgramMessage.codec.decodeExact(data);
  }
}

/// Optional facade over specialized generated clients.
final class ExampleProgramClient {
  /// Creates a facade from only the capabilities an application uses.
  const ExampleProgramClient({
    this.instructions = const ExampleProgramInstructionsClient(),
    this.accounts,
    this.events,
    this.views,
  });

  /// Instruction construction client.
  final ExampleProgramInstructionsClient instructions;

  /// Optional account client.
  final ExampleProgramAccountsClient? accounts;

  /// Optional event client.
  final ExampleProgramEventsClient? events;

  /// Optional typed view client.
  final ExampleProgramViewClient? views;
}
