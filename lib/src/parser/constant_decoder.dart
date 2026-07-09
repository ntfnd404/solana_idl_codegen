import 'dart:convert';

import '../idl.dart';
import 'idl_format_exception.dart';
import 'strict_json_reader.dart';
import 'type_decoder.dart';

/// Decodes the verified subset of Anchor constant representations.
final class AnchorConstantDecoder {
  /// Creates a constant decoder.
  const AnchorConstantDecoder(this.values, this.types);

  /// Strict JSON value reader.
  final StrictJsonReader values;

  /// Anchor type expression decoder.
  final AnchorTypeDecoder types;

  /// Decodes one IDL constant declaration.
  IdlConstantDefinition definition(Map<String, Object?> object, String path) {
    values.knownKeys(object, const {'name', 'docs', 'type', 'value'}, path);
    final type = types.typeExpression(
      values.requiredValue(object, 'type', '$path.type'),
      '$path.type',
    );
    final raw = values.requiredString(object, 'value', '$path.value').trim();
    return IdlConstantDefinition(
      name: values.requiredString(object, 'name', '$path.name'),
      type: type,
      value: _value(raw, type, '$path.value'),
      docs: values.docs(object, 'docs', '$path.docs'),
      sourcePath: path,
    );
  }

  IdlConstValue _value(String raw, IdlType type, String path) {
    final normalized = raw.replaceAll('_', '');
    if (type case IdlPrimitiveType(
      name: 'u8' ||
          'i8' ||
          'u16' ||
          'i16' ||
          'u32' ||
          'i32' ||
          'u64' ||
          'i64' ||
          'u128' ||
          'i128' ||
          'u256' ||
          'i256',
    )) {
      final parsed = BigInt.tryParse(normalized);
      if (parsed == null) {
        throw IdlFormatException(
          'Unsupported integer constant representation.',
          path,
          code: 'IDL_CONSTANT_REPRESENTATION',
        );
      }
      return IdlIntegerConstValue(parsed);
    }
    if (type case IdlPrimitiveType(name: 'bytes')) {
      if (normalized.startsWith('[') && normalized.endsWith(']')) {
        final content = normalized.substring(1, normalized.length - 1).trim();
        if (content.isEmpty) return IdlBytesConstValue(const []);
        final bytes = <int>[];
        for (final item in content.split(',')) {
          final value = int.tryParse(item.trim());
          if (value == null || value < 0 || value > 255) {
            throw IdlFormatException(
              'Byte array constants require values from 0 to 255.',
              path,
              code: 'IDL_CONSTANT_REPRESENTATION',
            );
          }
          bytes.add(value);
        }
        return IdlBytesConstValue(bytes);
      }
      if (raw.startsWith('b"') && raw.endsWith('"')) {
        return IdlBytesConstValue(
          utf8.encode(raw.substring(2, raw.length - 1)),
        );
      }
    }
    throw IdlFormatException(
      'Constant representation is not supported for this type.',
      path,
      code: 'IDL_CONSTANT_REPRESENTATION',
    );
  }
}
