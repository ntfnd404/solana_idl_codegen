// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated client facades for `secondary_program`.
library;

import 'secondary_program_solana_accounts.dart';
import 'secondary_program_solana_events.dart';
import 'secondary_program_solana_instructions.dart';
import 'secondary_program_solana_resolution.dart';
import 'secondary_program_solana_support.dart';
import 'secondary_program_solana_types.dart';

/// Instruction construction facade.
final class SecondaryProgramInstructionsClient {
  /// Creates a stateless instruction facade.
  const SecondaryProgramInstructionsClient();

  /// Builds `consume` from a prepared request.
  SecondaryProgramInstruction consume(SecondaryProgramConsumeRequest request) =>
      request.instruction();
}

/// Typed read-only instruction simulation client.
final class SecondaryProgramViewClient {
  /// Creates a view client from a simulation capability.
  const SecondaryProgramViewClient(this.simulator);

  /// Single-instruction simulation capability.
  final SecondaryProgramTransactionSimulator simulator;
}

/// Optional facade over specialized generated clients.
final class SecondaryProgramClient {
  /// Creates a facade from only the capabilities an application uses.
  const SecondaryProgramClient({
    this.instructions = const SecondaryProgramInstructionsClient(),
    this.accounts,
    this.events,
    this.views,
  });

  /// Instruction construction client.
  final SecondaryProgramInstructionsClient instructions;

  /// Optional account client.
  final SecondaryProgramAccountsClient? accounts;

  /// Optional event client.
  final SecondaryProgramEventsClient? events;

  /// Optional typed view client.
  final SecondaryProgramViewClient? views;
}
