import 'dart:convert';
import 'dart:typed_data';

/// Decodes Bitcoin/Solana Base58 text without external dependencies.
///
/// A successful result preserves every leading zero byte represented by a
/// leading `1`.
final class Base58Decoder extends Converter<String, Uint8List> {
  /// Creates a stateless Base58 decoder.
  const Base58Decoder();

  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static final Uint8List _indexes = _buildIndexes();

  static Uint8List _buildIndexes() {
    final result = Uint8List(128)..fillRange(0, 128, 255);
    for (int index = 0; index < _alphabet.length; index++) {
      result[_alphabet.codeUnitAt(index)] = index;
    }

    return result;
  }

  /// Decodes [input].
  ///
  /// Throws a [FormatException] when [input] is empty or contains a character
  /// outside the Base58 alphabet.
  @override
  Uint8List convert(String input) {
    if (input.isEmpty) {
      throw const FormatException('Empty Base58 string.');
    }

    final codeUnits = input.codeUnits;
    for (final codeUnit in codeUnits) {
      if (codeUnit >= _indexes.length) {
        throw const FormatException('Non-ASCII Base58 input.');
      }
    }

    var leadingZeros = 0;
    while (leadingZeros < codeUnits.length && codeUnits[leadingZeros] == 49) {
      leadingZeros++;
    }

    // log(58) / log(256), rounded up conservatively.
    final capacity = ((codeUnits.length - leadingZeros) * 733 ~/ 1000) + 1;
    final base256 = Uint8List(capacity);
    var significantLength = 0;

    for (var index = leadingZeros; index < codeUnits.length; index++) {
      final digit = _indexes[codeUnits[index]];
      if (digit == 255) {
        throw FormatException(
          'Invalid Base58 character: '
          '${String.fromCharCode(codeUnits[index])}',
        );
      }

      var carry = digit;
      var outputIndex = capacity - 1;
      for (
        var processed = 0;
        processed < significantLength;
        processed++, outputIndex--
      ) {
        carry += 58 * base256[outputIndex];
        base256[outputIndex] = carry & 0xff;
        carry >>= 8;
      }
      while (carry > 0) {
        base256[outputIndex] = carry & 0xff;
        carry >>= 8;
        outputIndex--;
        significantLength++;
      }
    }

    var firstSignificant = 0;
    while (firstSignificant < capacity && base256[firstSignificant] == 0) {
      firstSignificant++;
    }

    final result = Uint8List(leadingZeros + capacity - firstSignificant);
    result.setRange(leadingZeros, result.length, base256, firstSignificant);
    return result;
  }
}
