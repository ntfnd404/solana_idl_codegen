// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.2.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
/// Generated value models for `example_program`.
library;

import 'example_program_solana_support.dart';

/// Generated metadata for `example_program`.
abstract final class ExampleProgramProgram {
  /// Program name declared by the IDL.
  static const String name = 'example_program';

  /// Program version declared by the IDL.
  static const String version = '1.0.0';

  /// Anchor IDL specification dialect.
  static const String spec = '0.1.0';

  /// Base58 program address declared by the IDL.
  static const String address = '11111111111111111111111111111111';

  /// Parsed program address.
  static final ExampleProgramAddress programAddress =
      ExampleProgramAddress.fromBase58(address);
}

/// Immutable Borsh value for `Message`.
///
/// Persistent message state.
final class ExampleProgramMessage {
  /// Creates a validated immutable value.
  ExampleProgramMessage({
    required this.authority,
    required this.id,
    required this.text,
  });

  /// Value of the IDL field `authority`.
  final ExampleProgramAddress authority;

  /// Value of the IDL field `id`.
  final BigInt id;

  /// Value of the IDL field `text`.
  final String text;

  /// Borsh codec for [ExampleProgramMessage].
  static final ExampleProgramBorshCodec<ExampleProgramMessage> codec =
      ExampleProgramFunctionalBorshCodec<ExampleProgramMessage>(
        (reader) => ExampleProgramMessage(
          authority: reader.field(
            'authority',
            () => ExampleProgramAddress.fromBytes(reader.readBytes(32)),
          ),
          id: reader.field('id', () => reader.readUnsigned(8)),
          text: reader.field('text', () => reader.readString()),
        ),
        (writer, value) {
          writer.writeBytes(value.authority.bytes);
          writer.writeUnsigned(value.id, 8);
          writer.writeString(value.text);
        },
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExampleProgramMessage &&
          authority == other.authority &&
          id == other.id &&
          text == other.text);

  @override
  int get hashCode =>
      Object.hashAll([authority.hashCode, id.hashCode, text.hashCode]);
}

/// Immutable Borsh value for `MessageCreated`.
final class ExampleProgramMessageCreated {
  /// Creates a validated immutable value.
  ExampleProgramMessageCreated({required this.message, required this.id});

  /// Value of the IDL field `message`.
  final ExampleProgramAddress message;

  /// Value of the IDL field `id`.
  final BigInt id;

  /// Borsh codec for [ExampleProgramMessageCreated].
  static final ExampleProgramBorshCodec<ExampleProgramMessageCreated> codec =
      ExampleProgramFunctionalBorshCodec<ExampleProgramMessageCreated>(
        (reader) => ExampleProgramMessageCreated(
          message: reader.field(
            'message',
            () => ExampleProgramAddress.fromBytes(reader.readBytes(32)),
          ),
          id: reader.field('id', () => reader.readUnsigned(8)),
        ),
        (writer, value) {
          writer.writeBytes(value.message.bytes);
          writer.writeUnsigned(value.id, 8);
        },
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExampleProgramMessageCreated &&
          message == other.message &&
          id == other.id);

  @override
  int get hashCode => Object.hashAll([message.hashCode, id.hashCode]);
}
