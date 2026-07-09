// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated account API for `example_program`.
library;

import 'example_program.solana.support.dart';
import 'example_program.solana.types.dart';

/// Decoder and discriminator metadata for `ExampleProgramMessage` accounts.
abstract final class ExampleProgramMessageAccount {
  /// IDL discriminator bytes.
  static final List<int> discriminator = List.unmodifiable(<int>[
    77,
    101,
    115,
    115,
    97,
    103,
    101,
    1,
  ]);

  /// Decodes account data and permits trailing allocation padding.
  static ExampleProgramMessage decodeAccount(
    List<int> data, {
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) {
    _verifyDiscriminator(data);
    return ExampleProgramMessage.codec
        .decodePrefix(data.sublist(discriminator.length), limits: limits)
        .value;
  }

  /// Decodes account data and rejects trailing bytes.
  static ExampleProgramMessage decodeAccountExact(
    List<int> data, {
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) {
    _verifyDiscriminator(data);
    return ExampleProgramMessage.codec.decodeExact(
      data.sublist(discriminator.length),
      limits: limits,
    );
  }

  static void _verifyDiscriminator(List<int> data) {
    if (data.length < discriminator.length) {
      throw FormatException('Account data is shorter than its discriminator.');
    }
    for (var index = 0; index < discriminator.length; index++) {
      if (data[index] != discriminator[index]) {
        throw FormatException('Account discriminator mismatch.');
      }
    }
  }
}

/// Typed account reader and scanner client.
final class ExampleProgramAccountsClient {
  /// Creates a client from narrow account capabilities.
  const ExampleProgramAccountsClient({required this.reader, this.scanner});

  /// Account read capability.
  final ExampleProgramAccountReader reader;

  /// Optional account scan capability.
  final ExampleProgramAccountScanner? scanner;

  /// Fetches and validates one `ExampleProgramMessage` account.
  Future<ExampleProgramMessage> fetchMessage(
    ExampleProgramAddress address, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) async {
    final snapshot = await reader.readAccount(address, options: options);
    if (snapshot == null) {
      throw const ExampleProgramAccountException(
        code: 'ACCOUNT_NOT_FOUND',
        message: 'Account does not exist.',
      );
    }
    if (snapshot.owner != ExampleProgramProgram.programAddress) {
      throw const ExampleProgramAccountException(
        code: 'ACCOUNT_OWNER_MISMATCH',
        message: 'Account owner mismatch.',
      );
    }
    return ExampleProgramMessageAccount.decodeAccount(
      snapshot.data,
      limits: limits,
    );
  }

  /// Fetches one account or returns `null` only when absent.
  Future<ExampleProgramMessage?> fetchMessageNullable(
    ExampleProgramAddress address, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) async {
    final snapshot = await reader.readAccount(address, options: options);
    if (snapshot == null) return null;
    if (snapshot.owner != ExampleProgramProgram.programAddress) {
      throw const ExampleProgramAccountException(
        code: 'ACCOUNT_OWNER_MISMATCH',
        message: 'Account owner mismatch.',
      );
    }
    return ExampleProgramMessageAccount.decodeAccount(
      snapshot.data,
      limits: limits,
    );
  }

  /// Fetches accounts while preserving order and missing positions.
  Future<List<ExampleProgramMessage?>> fetchMultipleMessage(
    List<ExampleProgramAddress> addresses, {
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) async {
    final snapshots = await reader.readAccounts(
      List.unmodifiable(addresses),
      options: options,
    );
    if (snapshots.length != addresses.length) {
      throw const ExampleProgramAccountException(
        code: 'ACCOUNT_RESULT_CARDINALITY',
        message: 'AccountReader changed result cardinality.',
      );
    }
    return List.unmodifiable(
      snapshots.map((snapshot) {
        if (snapshot == null) return null;
        if (snapshot.owner != ExampleProgramProgram.programAddress) {
          throw const ExampleProgramAccountException(
            code: 'ACCOUNT_OWNER_MISMATCH',
            message: 'Account owner mismatch.',
          );
        }
        return ExampleProgramMessageAccount.decodeAccount(
          snapshot.data,
          limits: limits,
        );
      }),
    );
  }

  /// Scans every matching program account.
  Future<List<ExampleProgramMessage>> allMessage({
    List<ExampleProgramAccountFilter> filters = const [],
    ExampleProgramAccountReadOptions options =
        const ExampleProgramAccountReadOptions(),
    ExampleProgramDecodeLimits limits = ExampleProgramDecodeLimits.defaults,
  }) async {
    final capability = scanner;
    if (capability == null) {
      throw const ExampleProgramAccountException(
        code: 'ACCOUNT_SCANNER_UNAVAILABLE',
        message: 'AccountScanner capability is unavailable.',
      );
    }
    final discriminatorFilter = ExampleProgramMemcmpFilter(
      offset: 0,
      bytes: ExampleProgramMessageAccount.discriminator,
    );
    final snapshots = await capability.scanAccounts(
      ExampleProgramProgram.programAddress,
      filters: [discriminatorFilter, ...filters],
      options: options,
    );
    return List.unmodifiable(
      snapshots.map((snapshot) {
        if (snapshot.owner != ExampleProgramProgram.programAddress) {
          throw const ExampleProgramAccountException(
            code: 'ACCOUNT_OWNER_MISMATCH',
            message: 'Account owner mismatch.',
          );
        }
        return ExampleProgramMessageAccount.decodeAccount(
          snapshot.data,
          limits: limits,
        );
      }),
    );
  }
}
