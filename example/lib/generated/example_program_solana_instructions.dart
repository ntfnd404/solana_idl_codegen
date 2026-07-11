// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated instruction API for `example_program`.
library;

import 'dart:typed_data';
import 'example_program_solana_support.dart';
import 'example_program_solana_types.dart';

/// Immutable arguments for `create_message`.
/// Creates a message account and returns its numeric identifier.
final class ExampleProgramCreateMessageArgs {
  /// Creates instruction arguments.
  ExampleProgramCreateMessageArgs({required BigInt id, required String text})
    : id = id,
      text = text;

  /// IDL argument `id`.
  final BigInt id;

  /// IDL argument `text`.
  final String text;

  /// Borsh codec for these arguments.
  static final ExampleProgramBorshCodec<ExampleProgramCreateMessageArgs> codec =
      ExampleProgramFunctionalBorshCodec<ExampleProgramCreateMessageArgs>(
        (reader) => ExampleProgramCreateMessageArgs(
          id: reader.field('id', () => reader.readUnsigned(8)),
          text: reader.field('text', () => reader.readString()),
        ),
        (writer, value) {
          writer.writeUnsigned(value.id, 8);
          writer.writeString(value.text);
        },
      );
}

/// Fully resolved accounts for `create_message`.
final class ExampleProgramCreateMessageAccounts {
  /// Creates resolved instruction accounts.
  const ExampleProgramCreateMessageAccounts({
    required this.authority,
    required this.stateMessage,
    required this.optionalReferrer,
    required this.systemProgram,
  });

  /// Resolved account `authority`.
  final ExampleProgramAddress authority;

  /// Resolved account `state_message`.
  final ExampleProgramAddress stateMessage;

  /// Resolved account `optional_referrer`.
  final ExampleProgramAddress? optionalReferrer;

  /// Resolved account `system_program`.
  final ExampleProgramAddress systemProgram;
}

/// Immutable request for `create_message`.
final class ExampleProgramCreateMessageRequest {
  /// Creates a prepared instruction request.
  ExampleProgramCreateMessageRequest({
    required this.args,
    required this.accounts,
    List<ExampleProgramAccountMeta> remainingAccounts = const [],
  }) : remainingAccounts = List.unmodifiable(remainingAccounts);

  /// IDL instruction name.
  static const String name = 'create_message';

  /// IDL discriminator bytes.
  static final List<int> discriminator = List.unmodifiable(<int>[
    34,
    211,
    52,
    19,
    81,
    9,
    201,
    7,
  ]);

  /// Number of discriminator bytes.
  static const int discriminatorLength = 8;

  /// Data-only instruction metadata.
  static final ExampleProgramInstructionMetadata metadata =
      ExampleProgramInstructionMetadata(
        name: name,
        discriminator: discriminator,
        accounts: [
          ExampleProgramInstructionAccountMetadata(
            name: 'authority',
            path: 'authority',
            isSigner: true,
            isWritable: false,
            isOptional: false,
          ),
          ExampleProgramInstructionAccountMetadata(
            name: 'message',
            path: 'state.message',
            isSigner: false,
            isWritable: true,
            isOptional: false,
          ),
          ExampleProgramInstructionAccountMetadata(
            name: 'optional_referrer',
            path: 'optional_referrer',
            isSigner: false,
            isWritable: false,
            isOptional: true,
          ),
          ExampleProgramInstructionAccountMetadata(
            name: 'system_program',
            path: 'system_program',
            isSigner: false,
            isWritable: false,
            isOptional: false,
          ),
        ],
      );

  /// Typed instruction arguments.
  final ExampleProgramCreateMessageArgs args;

  /// Fully resolved accounts.
  final ExampleProgramCreateMessageAccounts accounts;

  /// Ordered remaining accounts. Duplicates are preserved.
  final List<ExampleProgramAccountMeta> remainingAccounts;

  /// Builds the transport-neutral instruction.
  ExampleProgramInstruction instruction() {
    final writer = ExampleProgramBorshWriter()
      ..writeBytes(<int>[34, 211, 52, 19, 81, 9, 201, 7]);
    ExampleProgramCreateMessageArgs.codec.write(writer, args);
    return ExampleProgramInstruction(
      programAddress: ExampleProgramProgram.programAddress,
      accounts: [
        ExampleProgramAccountMeta(
          address: accounts.authority,
          isSigner: true,
          isWritable: false,
        ),
        ExampleProgramAccountMeta(
          address: accounts.stateMessage,
          isSigner: false,
          isWritable: true,
        ),
        ExampleProgramAccountMeta(
          address:
              accounts.optionalReferrer ?? ExampleProgramProgram.programAddress,
          isSigner: accounts.optionalReferrer == null ? false : false,
          isWritable: accounts.optionalReferrer == null ? false : false,
        ),
        ExampleProgramAccountMeta(
          address: accounts.systemProgram,
          isSigner: false,
          isWritable: false,
        ),
        ...remainingAccounts,
      ],
      data: writer.takeBytes(),
    );
  }
}

/// Immutable arguments for `read_message`.
final class ExampleProgramReadMessageArgs {
  /// Creates empty instruction arguments.
  const ExampleProgramReadMessageArgs();

  /// Borsh codec for these arguments.
  static final ExampleProgramBorshCodec<ExampleProgramReadMessageArgs> codec =
      ExampleProgramFunctionalBorshCodec<ExampleProgramReadMessageArgs>(
        (reader) => ExampleProgramReadMessageArgs(),
        (writer, value) {},
      );
}

/// Fully resolved accounts for `read_message`.
final class ExampleProgramReadMessageAccounts {
  /// Creates resolved instruction accounts.
  const ExampleProgramReadMessageAccounts({required this.message});

  /// Resolved account `message`.
  final ExampleProgramAddress message;
}

/// Immutable request for `read_message`.
final class ExampleProgramReadMessageRequest {
  /// Creates a prepared instruction request.
  ExampleProgramReadMessageRequest({
    required this.args,
    required this.accounts,
    List<ExampleProgramAccountMeta> remainingAccounts = const [],
  }) : remainingAccounts = List.unmodifiable(remainingAccounts);

  /// IDL instruction name.
  static const String name = 'read_message';

  /// IDL discriminator bytes.
  static final List<int> discriminator = List.unmodifiable(<int>[
    35,
    212,
    53,
    20,
    82,
    10,
    202,
    8,
  ]);

  /// Number of discriminator bytes.
  static const int discriminatorLength = 8;

  /// Data-only instruction metadata.
  static final ExampleProgramInstructionMetadata metadata =
      ExampleProgramInstructionMetadata(
        name: name,
        discriminator: discriminator,
        accounts: [
          ExampleProgramInstructionAccountMetadata(
            name: 'message',
            path: 'message',
            isSigner: false,
            isWritable: false,
            isOptional: false,
          ),
        ],
      );

  /// Typed instruction arguments.
  final ExampleProgramReadMessageArgs args;

  /// Fully resolved accounts.
  final ExampleProgramReadMessageAccounts accounts;

  /// Ordered remaining accounts. Duplicates are preserved.
  final List<ExampleProgramAccountMeta> remainingAccounts;

  /// Builds the transport-neutral instruction.
  ExampleProgramInstruction instruction() {
    final writer = ExampleProgramBorshWriter()
      ..writeBytes(<int>[35, 212, 53, 20, 82, 10, 202, 8]);
    ExampleProgramReadMessageArgs.codec.write(writer, args);
    return ExampleProgramInstruction(
      programAddress: ExampleProgramProgram.programAddress,
      accounts: [
        ExampleProgramAccountMeta(
          address: accounts.message,
          isSigner: false,
          isWritable: false,
        ),
        ...remainingAccounts,
      ],
      data: writer.takeBytes(),
    );
  }
}

/// Program-level registry of generated instruction metadata.
abstract final class ExampleProgramInstructionRegistry {
  /// Instructions declared by the IDL in source order.
  static final List<ExampleProgramInstructionMetadata> instructions =
      List.unmodifiable(<ExampleProgramInstructionMetadata>[
        ExampleProgramCreateMessageRequest.metadata,
        ExampleProgramReadMessageRequest.metadata,
      ]);

  /// Instruction metadata indexed by IDL instruction name.
  static final Map<String, ExampleProgramInstructionMetadata> byName =
      Map.unmodifiable({
        for (final instruction in instructions) instruction.name: instruction,
      });
}
