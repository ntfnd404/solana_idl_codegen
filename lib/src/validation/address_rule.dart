import 'dart:convert';
import 'dart:typed_data';

import 'base58_decoder.dart';
import 'validation_issue.dart';

/// Validates Solana addresses without depending on an RPC package.
final class AddressValidationRule {
  /// Creates an address rule using [decoder].
  const AddressValidationRule([this._decoder = const Base58Decoder()]);

  final Converter<String, Uint8List> _decoder;

  /// Reports an issue unless [value] is Base58 encoding of exactly 32 bytes.
  void validate(String value, String path, ValidationIssue issue) {
    try {
      final bytes = _decoder.convert(value);
      if (bytes.length != 32) {
        issue(
          'IDL_ADDRESS_LENGTH',
          'Address must decode to exactly 32 bytes.',
          path,
        );
      }
    } on FormatException {
      issue('IDL_ADDRESS_BASE58', 'Address is not valid Base58.', path);
    }
  }
}
