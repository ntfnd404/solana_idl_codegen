// GENERATED CODE - DO NOT MODIFY BY HAND.
// tool: solana_idl_codegen
// generator-version: 0.1.0
// source-sha256: 2865113b5e9095b7a15ecca890930530f1875b9cd72df2cd2c81ac066ae07d80
// semantic-ir-sha256: 5a434b479f377019592da21c1dd21985819054fa8f3ddcca8908f25645f95fef
// SPDX-License-Identifier: MIT
// ignore_for_file: prefer_initializing_formals, unused_element, unused_import, use_super_parameters

/// Generated program errors for `example_program`.
library;

import 'example_program_solana_support.dart';

/// Origin reported by Anchor error logs.
sealed class ExampleProgramErrorOrigin {
  /// Creates a error origin.
  const ExampleProgramErrorOrigin();
}

/// Account-name error origin.
final class ExampleProgramAccountErrorOrigin extends ExampleProgramErrorOrigin {
  /// Creates Account-name error origin.
  const ExampleProgramAccountErrorOrigin(this.name);

  /// IDL account name.
  final String name;
}

/// Program-address error origin.
final class ExampleProgramProgramErrorOrigin extends ExampleProgramErrorOrigin {
  /// Creates Program-address error origin.
  const ExampleProgramProgramErrorOrigin(this.address);

  /// Program address.
  final ExampleProgramAddress address;
}

/// Compared values reported by Anchor error logs.
sealed class ExampleProgramComparedValues {
  /// Creates a compared values.
  const ExampleProgramComparedValues();
}

/// Compared textual values whose wire type is unknown.
final class ExampleProgramTextComparedValues
    extends ExampleProgramComparedValues {
  /// Creates Compared textual values whose wire type is unknown.
  const ExampleProgramTextComparedValues({
    required this.left,
    required this.right,
  });

  /// Left value.
  final String left;

  /// Right value.
  final String right;
}

/// Base typed program exception.
sealed class ExampleProgramProgramException implements Exception {
  /// Creates a program exception and copies logs.
  ExampleProgramProgramException({
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
  final ExampleProgramErrorOrigin? origin;

  /// Optional values compared by the failed constraint.
  final ExampleProgramComparedValues? comparedValues;

  /// Ordered raw logs.
  final List<String> rawLogs;

  /// Optional transaction signature.
  final String? signature;

  /// Optional transport-neutral transaction failure.
  final ExampleProgramTransactionFailure? failure;
}

/// IDL error `EmptyMessage` (6000).
final class ExampleProgramEmptyMessageException
    extends ExampleProgramProgramException {
  /// Creates this typed program exception.
  ExampleProgramEmptyMessageException({
    ExampleProgramErrorOrigin? origin,
    ExampleProgramComparedValues? comparedValues,
    List<String> rawLogs = const [],
    String? signature,
    ExampleProgramTransactionFailure? failure,
  }) : super(
         code: 6000,
         idlName: 'EmptyMessage',
         idlMessage: 'Message text cannot be empty',
         origin: origin,
         comparedValues: comparedValues,
         rawLogs: rawLogs,
         signature: signature,
         failure: failure,
       );
}

/// Unknown custom or framework program error.
final class ExampleProgramUnknownProgramException
    extends ExampleProgramProgramException {
  /// Creates an unknown program exception.
  ExampleProgramUnknownProgramException({
    required int code,
    ExampleProgramErrorOrigin? origin,
    ExampleProgramComparedValues? comparedValues,
    List<String> rawLogs = const [],
    String? signature,
    ExampleProgramTransactionFailure? failure,
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
abstract final class ExampleProgramProgramErrorParser {
  /// Returns the IDL error name for [code], if known.
  static String? nameForCode(int code) {
    return switch (code) {
      6000 => 'EmptyMessage',
      _ => null,
    };
  }

  /// Returns the IDL error message for [code], if known.
  static String? messageForCode(int code) {
    return switch (code) {
      6000 => 'Message text cannot be empty',
      _ => null,
    };
  }

  /// Returns the numeric code for [name], if known.
  static int? codeForName(String name) {
    return switch (name) {
      'EmptyMessage' => 6000,
      _ => null,
    };
  }

  /// Whether [code] is declared by this IDL.
  static bool isKnownCode(int code) => nameForCode(code) != null;

  /// Creates a typed error for [code].
  static ExampleProgramProgramException fromCode(
    int code, {
    ExampleProgramErrorOrigin? origin,
    ExampleProgramComparedValues? comparedValues,
    List<String> logs = const [],
    String? signature,
    ExampleProgramTransactionFailure? failure,
  }) {
    return switch (code) {
      6000 => ExampleProgramEmptyMessageException(
        origin: origin,
        comparedValues: comparedValues,
        rawLogs: logs,
        signature: signature,
        failure: failure,
      ),
      _ => ExampleProgramUnknownProgramException(
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
  static ExampleProgramProgramException? parseLogs(
    List<String> logs, {
    String? signature,
    ExampleProgramTransactionFailure? failure,
  }) {
    int? code;
    ExampleProgramErrorOrigin? origin;
    String? left;
    String? right;
    for (var index = 0; index < logs.length; index++) {
      final line = logs[index];
      final anchor = RegExp(r'Error Number: ([0-9]+)').firstMatch(line);
      if (anchor != null) {
        code = int.parse(anchor.group(1)!);
      }
      final custom = RegExp(
        r'custom program error: 0x([0-9a-fA-F]+)',
      ).firstMatch(line);
      if (custom != null) {
        code = int.parse(custom.group(1)!, radix: 16);
      }
      final account = RegExp(
        r'AnchorError caused by account: ([A-Za-z_][A-Za-z0-9_]*)',
      ).firstMatch(line);
      if (account != null) {
        origin = ExampleProgramAccountErrorOrigin(account.group(1)!);
      }
      final program = RegExp(
        r'AnchorError caused by program: ([1-9A-HJ-NP-Za-km-z]+)',
      ).firstMatch(line);
      if (program != null) {
        try {
          origin = ExampleProgramProgramErrorOrigin(
            ExampleProgramAddress.fromBase58(program.group(1)!),
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
        : ExampleProgramTextComparedValues(left: left, right: right);
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
