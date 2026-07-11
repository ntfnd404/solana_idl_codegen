import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits private byte-comparison and canonical Base58 utilities.
final class EncodingSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const EncodingSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final prefix = member('program');
    final alphabet = '_${prefix}Base58Alphabet';
    final indexes = '_${prefix}Base58Indexes';
    return <Spec>[
      Method(
        (builder) => builder
          ..name = '_${prefix}BytesEqual'
          ..returns = refer('bool')
          ..requiredParameters.addAll([
            _parameter('left', 'List<int>'),
            _parameter('right', 'List<int>'),
          ])
          ..body = const Code('''
if (left.length != right.length) {
  return false;
}
for (var index = 0; index < left.length; index++) {
  if (left[index] != right[index]) {
    return false;
  }
}
return true;'''),
      ),
      Field(
        (builder) => builder
          ..name = alphabet
          ..modifier = FieldModifier.constant
          ..assignment = literalString(
            '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz',
          ).code,
      ),
      Method(
        (builder) => builder
          ..name = '_${prefix}BuildBase58Indexes'
          ..returns = refer('Uint8List')
          ..body = Code('''
final result = Uint8List(128)..fillRange(0, 128, 255);
for (var index = 0; index < $alphabet.length; index++) {
  result[$alphabet.codeUnitAt(index)] = index;
}
return result;'''),
      ),
      Field(
        (builder) => builder
          ..name = indexes
          ..type = refer('Uint8List')
          ..modifier = FieldModifier.final$
          ..assignment = Code('_${prefix}BuildBase58Indexes()'),
      ),
      Method(
        (builder) => builder
          ..name = '_${prefix}DecodeBase58'
          ..returns = refer('Uint8List')
          ..requiredParameters.add(_parameter('value', 'String'))
          ..body = Code('''
if (value.isEmpty) {
  throw const FormatException('Base58 value is empty.');
}
final codeUnits = value.codeUnits;
for (final codeUnit in codeUnits) {
  if (codeUnit >= $indexes.length) {
    throw const FormatException('Invalid Base58 character.');
  }
}
var leadingZeros = 0;
while (leadingZeros < codeUnits.length && codeUnits[leadingZeros] == 49) {
  leadingZeros++;
}
final capacity = ((codeUnits.length - leadingZeros) * 733 ~/ 1000) + 1;
final base256 = Uint8List(capacity);
var significantLength = 0;
for (var index = leadingZeros; index < codeUnits.length; index++) {
  final digit = $indexes[codeUnits[index]];
  if (digit == 255) {
    throw const FormatException('Invalid Base58 character.');
  }
  var carry = digit;
  var outputIndex = capacity - 1;
  for (var processed = 0;
      processed < significantLength;
      processed++, outputIndex--) {
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
result.setRange(
  leadingZeros,
  result.length,
  base256,
  firstSignificant,
);
return result;'''),
      ),
      Method(
        (builder) => builder
          ..name = '_${prefix}EncodeBase58'
          ..returns = refer('String')
          ..requiredParameters.add(_parameter('bytes', 'List<int>'))
          ..body = Code('''
var number = BigInt.zero;
for (final byte in bytes) {
  number = number * BigInt.from(256) + BigInt.from(byte);
}
final encoded = StringBuffer();
while (number > BigInt.zero) {
  final digit = (number % BigInt.from(58)).toInt();
  encoded.write($alphabet[digit]);
  number ~/= BigInt.from(58);
}
for (final byte in bytes) {
  if (byte != 0) {
    break;
  }
  encoded.write('1');
}
return encoded.toString().split('').reversed.join();'''),
      ),
    ];
  }

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
