import 'package:solana_idl_codegen/src/validation/address_rule.dart';
import 'package:solana_idl_codegen/src/validation/base58_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('Base58Decoder', () {
    const decoder = Base58Decoder();

    test('preserves leading zero bytes', () {
      expect(decoder.convert('1'), orderedEquals([0]));
      expect(decoder.convert('111'), orderedEquals([0, 0, 0]));
      expect(
        decoder.convert('11111111111111111111111111111111'),
        orderedEquals(List<int>.filled(32, 0)),
      );
    });

    test('rejects empty, non-ASCII, and excluded alphabet characters', () {
      for (final value in ['', '0', 'O', 'I', 'l', 'é']) {
        expect(
          () => decoder.convert(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  group('AddressValidationRule', () {
    const rule = AddressValidationRule();

    test('accepts exactly 32 decoded bytes', () {
      final issues = <String>[];
      rule.validate(
        '11111111111111111111111111111111',
        r'$.address',
        (code, _, _) => issues.add(code),
      );
      expect(issues, isEmpty);
    });

    test('distinguishes invalid Base58 from invalid byte length', () {
      String? code;
      void issue(String value) {
        rule.validate(value, r'$.address', (value, _, _) => code = value);
      }

      issue('');
      expect(code, 'IDL_ADDRESS_BASE58');
      issue('0');
      expect(code, 'IDL_ADDRESS_BASE58');
      issue('1111111111111111111111111111111');
      expect(code, 'IDL_ADDRESS_LENGTH');
      issue('111111111111111111111111111111111');
      expect(code, 'IDL_ADDRESS_LENGTH');
    });
  });
}
