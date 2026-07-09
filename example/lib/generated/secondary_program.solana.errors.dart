// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: bfba19c124c33b827b5c139cc62b583f9c36aafb5951f72e02387a67705816a7
// semantic-ir-sha256: 116502c850c55b1b16510193442452e33c2161adb8e40f36a00d8c66826e6b0a
// SPDX-License-Identifier: MIT
// ignore_for_file: curly_braces_in_flow_control_structures, empty_constructor_bodies, prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated program errors for `secondary_program`.
library;

import 'secondary_program.solana.support.dart';

/// Origin reported by Anchor error logs.
sealed class SecondaryProgramErrorOrigin {
  /// Creates a error origin.
  const SecondaryProgramErrorOrigin();
}

/// Account-name error origin.
final class SecondaryProgramAccountErrorOrigin
    extends SecondaryProgramErrorOrigin {
  /// Creates Account-name error origin.
  const SecondaryProgramAccountErrorOrigin(this.name);

  /// IDL account name.
  final String name;
}

/// Program-address error origin.
final class SecondaryProgramProgramErrorOrigin
    extends SecondaryProgramErrorOrigin {
  /// Creates Program-address error origin.
  const SecondaryProgramProgramErrorOrigin(this.address);

  /// Program address.
  final SecondaryProgramAddress address;
}

/// Compared values reported by Anchor error logs.
sealed class SecondaryProgramComparedValues {
  /// Creates a compared values.
  const SecondaryProgramComparedValues();
}

/// Compared textual values whose wire type is unknown.
final class SecondaryProgramTextComparedValues
    extends SecondaryProgramComparedValues {
  /// Creates Compared textual values whose wire type is unknown.
  const SecondaryProgramTextComparedValues({
    required this.left,
    required this.right,
  });

  /// Left value.
  final String left;

  /// Right value.
  final String right;
}

/// Base typed program exception.
sealed class SecondaryProgramProgramException implements Exception {
  /// Creates a program exception and copies logs.
  SecondaryProgramProgramException({
    required this.code,
    required this.idlName,
    required this.idlMessage,
    required this.origin,
    required this.comparedValues,
    required this.signature,
    required this.failure,
    required List<String> rawLogs,
  }) : rawLogs = List.unmodifiable(rawLogs);

  /// Numeric program error code.
  final int code;

  /// Optional IDL error name.
  final String? idlName;

  /// Optional IDL message.
  final String? idlMessage;

  /// Optional typed origin.
  final SecondaryProgramErrorOrigin? origin;

  /// Optional values compared by the failed constraint.
  final SecondaryProgramComparedValues? comparedValues;

  /// Ordered raw logs.
  final List<String> rawLogs;

  /// Optional transaction signature.
  final String? signature;

  /// Optional transport-neutral transaction failure.
  final SecondaryProgramTransactionFailure? failure;
}

/// Unknown custom or framework program error.
final class SecondaryProgramUnknownProgramException
    extends SecondaryProgramProgramException {
  /// Creates an unknown program exception.
  SecondaryProgramUnknownProgramException({
    required int code,
    SecondaryProgramErrorOrigin? origin,
    SecondaryProgramComparedValues? comparedValues,
    List<String> rawLogs = const [],
    String? signature,
    SecondaryProgramTransactionFailure? failure,
  }) : super(
         code: code,
         idlName: null,
         idlMessage: null,
         origin: origin,
         comparedValues: comparedValues,
         rawLogs: rawLogs,
         signature: signature,
         failure: failure,
       );
}

/// Parses numeric program failures into typed exceptions.
abstract final class SecondaryProgramProgramErrorParser {
  /// Creates a typed error for [code].
  static SecondaryProgramProgramException fromCode(
    int code, {
    SecondaryProgramErrorOrigin? origin,
    SecondaryProgramComparedValues? comparedValues,
    List<String> logs = const [],
    String? signature,
    SecondaryProgramTransactionFailure? failure,
  }) {
    return switch (code) {
      _ => SecondaryProgramUnknownProgramException(
        code: code,
        origin: origin,
        comparedValues: comparedValues,
        rawLogs: logs,
        signature: signature,
        failure: failure,
      ),
    };
  }

  /// Parses a numeric code from Anchor or custom-program logs.
  static SecondaryProgramProgramException? parseLogs(
    List<String> logs, {
    String? signature,
    SecondaryProgramTransactionFailure? failure,
  }) {
    int? code;
    SecondaryProgramErrorOrigin? origin;
    String? left;
    String? right;
    for (var index = 0; index < logs.length; index++) {
      final line = logs[index];
      final anchor = RegExp(r'Error Number: ([0-9]+)').firstMatch(line);
      if (anchor != null) code = int.parse(anchor.group(1)!);
      final custom = RegExp(
        r'custom program error: 0x([0-9a-fA-F]+)',
      ).firstMatch(line);
      if (custom != null) code = int.parse(custom.group(1)!, radix: 16);
      final account = RegExp(
        r'AnchorError caused by account: ([A-Za-z_][A-Za-z0-9_]*)',
      ).firstMatch(line);
      if (account != null)
        origin = SecondaryProgramAccountErrorOrigin(account.group(1)!);
      final program = RegExp(
        r'AnchorError caused by program: ([1-9A-HJ-NP-Za-km-z]+)',
      ).firstMatch(line);
      if (program != null) {
        try {
          origin = SecondaryProgramProgramErrorOrigin(
            SecondaryProgramAddress.fromBase58(program.group(1)!),
          );
        } on FormatException {
          origin = null;
        } on ArgumentError {
          origin = null;
        }
      }
      if (line.endsWith('Left:') && index + 1 < logs.length) {
        left = logs[index + 1].replaceFirst('Program log: ', '');
      }
      if (line.endsWith('Right:') && index + 1 < logs.length) {
        right = logs[index + 1].replaceFirst('Program log: ', '');
      }
    }
    final compared = left == null || right == null
        ? null
        : SecondaryProgramTextComparedValues(left: left, right: right);
    return code == null
        ? null
        : fromCode(
            code,
            origin: origin,
            comparedValues: compared,
            logs: logs,
            signature: signature,
            failure: failure,
          );
  }
}
