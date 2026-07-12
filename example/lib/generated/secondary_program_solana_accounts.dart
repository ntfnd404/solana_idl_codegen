// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.2.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
/// Generated account API for `secondary_program`.
library;

import 'secondary_program_solana_support.dart';

/// Program-level registry of generated account metadata.
abstract final class SecondaryProgramAccountRegistry {
  /// Accounts declared by the IDL in source order.
  static final List<SecondaryProgramAccountMetadata> accounts =
      List.unmodifiable(<SecondaryProgramAccountMetadata>[]);

  /// Account metadata indexed by IDL account name.
  static final Map<String, SecondaryProgramAccountMetadata> byName =
      Map.unmodifiable({for (final account in accounts) account.name: account});
}

/// Typed account reader and scanner client.
final class SecondaryProgramAccountsClient {
  /// Creates a client from narrow account capabilities.
  const SecondaryProgramAccountsClient({required this.reader, this.scanner});

  /// Account read capability.
  final SecondaryProgramAccountReader reader;

  /// Optional account scan capability.
  final SecondaryProgramAccountScanner? scanner;
}
