// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated instruction API for `secondary_program`.
library;

import 'dart:typed_data';
import 'secondary_program.solana.support.dart';
import 'secondary_program.solana.types.dart';

/// Immutable arguments for `consume`.
final class SecondaryProgramConsumeArgs {
  /// Creates instruction arguments.
  SecondaryProgramConsumeArgs({required List<int> payload})
    : payload = Uint8List.fromList(payload).asUnmodifiableView();

  /// IDL argument `payload`.
  final Uint8List payload;

  /// Borsh codec for these arguments.
  static final SecondaryProgramBorshCodec<SecondaryProgramConsumeArgs> codec =
      SecondaryProgramFunctionalBorshCodec<SecondaryProgramConsumeArgs>(
        (reader) => SecondaryProgramConsumeArgs(
          payload: reader.field(
            'payload',
            () => reader.readBytes(reader.collectionLength()),
          ),
        ),
        (writer, value) {
          writer
            ..writeUnsigned(BigInt.from(value.payload.length), 4)
            ..writeBytes(value.payload);
        },
      );
}

/// Fully resolved accounts for `consume`.
final class SecondaryProgramConsumeAccounts {
  /// Creates resolved instruction accounts.
  const SecondaryProgramConsumeAccounts({required this.authority});

  /// Resolved account `authority`.
  final SecondaryProgramAddress authority;
}

/// Immutable request for `consume`.
final class SecondaryProgramConsumeRequest {
  /// Creates a prepared instruction request.
  SecondaryProgramConsumeRequest({
    required this.args,
    required this.accounts,
    List<SecondaryProgramAccountMeta> remainingAccounts = const [],
  }) : remainingAccounts = List.unmodifiable(remainingAccounts);

  /// Typed instruction arguments.
  final SecondaryProgramConsumeArgs args;

  /// Fully resolved accounts.
  final SecondaryProgramConsumeAccounts accounts;

  /// Ordered remaining accounts. Duplicates are preserved.
  final List<SecondaryProgramAccountMeta> remainingAccounts;

  /// Builds the transport-neutral instruction.
  SecondaryProgramInstruction instruction() {
    final writer = SecondaryProgramBorshWriter()
      ..writeBytes(<int>[99, 1, 2, 3]);
    SecondaryProgramConsumeArgs.codec.write(writer, args);
    return SecondaryProgramInstruction(
      programAddress: SecondaryProgramProgram.programAddress,
      accounts: [
        SecondaryProgramAccountMeta(
          address: accounts.authority,
          isSigner: true,
          isWritable: false,
        ),
        ...remainingAccounts,
      ],
      data: writer.takeBytes(),
    );
  }
}
