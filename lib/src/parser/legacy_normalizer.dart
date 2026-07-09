import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Pure legacy Anchor naming and discriminator normalization.
final class LegacyIdlNormalizer {
  /// Creates a legacy normalizer.
  const LegacyIdlNormalizer();

  /// Converts a legacy instruction name to modern snake case.
  String instructionName(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .toLowerCase();

  /// Computes the legacy eight-byte Anchor discriminator.
  List<int> discriminator(String namespace, String name) => sha256
      .convert(utf8.encode('$namespace:$name'))
      .bytes
      .take(8)
      .toList(growable: false);
}
