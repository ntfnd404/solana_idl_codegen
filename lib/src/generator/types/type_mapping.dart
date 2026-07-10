import '../../idl.dart';
import '../generator_context.dart';

/// Maps normalized IDL types to Dart types and Borsh codec expressions.
final class DartTypeMapping {
  /// Creates a mapper for [context].
  const DartTypeMapping(this.context);

  /// Shared immutable generation context.
  final GeneratorContext context;

  /// Maps a generated type name through the configured naming strategy.
  String type(String name) => context.type(name);

  /// Maps a generated member name through the configured naming strategy.
  String member(String name) => context.member(name);

  /// Returns the Dart source type used for [value].
  String dartType(IdlType value) => switch (value) {
    IdlPrimitiveType(:final name) => switch (name) {
      'bool' => 'bool',
      'u8' || 'i8' || 'u16' || 'i16' || 'u32' || 'i32' => 'int',
      'u64' || 'i64' || 'u128' || 'i128' || 'u256' || 'i256' => 'BigInt',
      'f32' || 'f64' => 'double',
      'bytes' => 'Uint8List',
      'string' => 'String',
      'pubkey' => type('address'),
      _ => throw StateError('Unsupported primitive $name.'),
    },
    IdlOptionType(:final inner) => '${dartType(inner)}?',
    IdlCOptionType(:final inner) => '${dartType(inner)}?',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) => 'List<${dartType(inner)}>',
    IdlDefinedType(:final name, :final generics) =>
      '${type(name)}${generics.isEmpty ? '' : '<${generics.map(dartType).join(', ')}>'}',
    IdlGenericType(:final name) => type(name),
  };

  /// Builds a Borsh read expression for [value] using [reader].
  String read(IdlType value, String reader) => switch (value) {
    IdlPrimitiveType(:final name) => switch (name) {
      'bool' => '$reader.readBool()',
      'u8' => '$reader.readInt(1)',
      'i8' => '$reader.readSigned(1).toInt()',
      'u16' => '$reader.readInt(2)',
      'i16' => '$reader.readSigned(2).toInt()',
      'u32' => '$reader.readInt(4)',
      'i32' => '$reader.readSigned(4).toInt()',
      'u64' => '$reader.readUnsigned(8)',
      'i64' => '$reader.readSigned(8)',
      'u128' => '$reader.readUnsigned(16)',
      'i128' => '$reader.readSigned(16)',
      'u256' => '$reader.readUnsigned(32)',
      'i256' => '$reader.readSigned(32)',
      'f32' => '$reader.readFloat(4)',
      'f64' => '$reader.readFloat(8)',
      'bytes' => '$reader.readBytes($reader.collectionLength())',
      'string' => '$reader.readString()',
      'pubkey' => '${type('address')}.fromBytes($reader.readBytes(32))',
      _ => throw StateError('Unsupported primitive $name.'),
    },
    IdlOptionType(:final inner) =>
      '($reader.readOptionTag(1) ? $reader.nested(() => ${read(inner, reader)}) : null)',
    IdlCOptionType(:final inner) =>
      '(() { final present = $reader.readOptionTag(4); '
          'if (!present) { $reader.readBytes(${_cOptionPayloadSize(inner)}); '
          'return null; } '
          'return $reader.nested(() => ${read(inner, reader)}); })()',
    IdlVectorType(:final inner) =>
      'List.unmodifiable(List.generate($reader.collectionLength(), (index) => $reader.index(index, () => $reader.nested(() => ${read(inner, reader)}))))',
    IdlArrayType(:final inner, :final length) =>
      'List.unmodifiable(List.generate($reader.fixedLength($length), (index) => $reader.index(index, () => $reader.nested(() => ${read(inner, reader)}))))',
    IdlGenericArrayType(:final inner, :final lengthName) =>
      'List.unmodifiable(List.generate($reader.fixedLength(${member(lengthName)}), (index) => $reader.index(index, () => $reader.nested(() => ${read(inner, reader)}))))',
    IdlDefinedType(:final name, :final generics, :final constGenerics) =>
      '$reader.nested(() => ${_codec(name, generics, constGenerics)}.read($reader))',
    IdlGenericType(:final name) => '${member(name)}Codec.read($reader)',
  };

  /// Builds Borsh write statements for [value] from [expression].
  String write(IdlType value, String writer, String expression) =>
      _write(value, writer, expression, 0);

  String _write(
    IdlType value,
    String writer,
    String expression,
    int depth,
  ) => switch (value) {
    IdlPrimitiveType(:final name) => switch (name) {
      'bool' => '$writer.writeBool($expression);',
      'u8' => '$writer.writeUnsigned(BigInt.from($expression), 1);',
      'i8' => '$writer.writeSigned(BigInt.from($expression), 1);',
      'u16' => '$writer.writeUnsigned(BigInt.from($expression), 2);',
      'i16' => '$writer.writeSigned(BigInt.from($expression), 2);',
      'u32' => '$writer.writeUnsigned(BigInt.from($expression), 4);',
      'i32' => '$writer.writeSigned(BigInt.from($expression), 4);',
      'u64' => '$writer.writeUnsigned($expression, 8);',
      'i64' => '$writer.writeSigned($expression, 8);',
      'u128' => '$writer.writeUnsigned($expression, 16);',
      'i128' => '$writer.writeSigned($expression, 16);',
      'u256' => '$writer.writeUnsigned($expression, 32);',
      'i256' => '$writer.writeSigned($expression, 32);',
      'f32' => '$writer.writeFloat($expression, 4);',
      'f64' => '$writer.writeFloat($expression, 8);',
      'bytes' =>
        '$writer..writeUnsigned(BigInt.from($expression.length), 4)..writeBytes($expression);',
      'string' => '$writer.writeString($expression);',
      'pubkey' => '$writer.writeBytes($expression.bytes);',
      _ => throw StateError('Unsupported primitive $name.'),
    },
    IdlOptionType(:final inner) =>
      'switch ($expression) { '
          'case null: $writer.writeUnsigned(BigInt.zero, 1); '
          'case final optionValue$depth: '
          '$writer.writeUnsigned(BigInt.one, 1); '
          '${_write(inner, writer, 'optionValue$depth', depth + 1)} }',
    IdlCOptionType(:final inner) =>
      'switch ($expression) { '
          'case null: $writer.writeUnsigned(BigInt.zero, 4); '
          '$writer.writeBytes(List<int>.filled(${_cOptionPayloadSize(inner)}, 0)); '
          'case final optionValue$depth: '
          '$writer.writeUnsigned(BigInt.one, 4); '
          '${_write(inner, writer, 'optionValue$depth', depth + 1)} }',
    IdlVectorType(:final inner) =>
      '$writer.writeUnsigned(BigInt.from($expression.length), 4); '
          'for (final item in $expression) { ${_write(inner, writer, 'item', depth + 1)} }',
    IdlArrayType(:final inner, :final length) =>
      'if ($expression.length != $length) throw ArgumentError.value($expression.length, "value"); '
          'for (final item in $expression) { ${_write(inner, writer, 'item', depth + 1)} }',
    IdlGenericArrayType(:final inner, :final lengthName) =>
      'if ($expression.length != ${member(lengthName)}) throw ArgumentError.value($expression.length, "value"); '
          'for (final item in $expression) { ${_write(inner, writer, 'item', depth + 1)} }',
    IdlDefinedType(:final name, :final generics, :final constGenerics) =>
      '${_codec(name, generics, constGenerics)}.write($writer, $expression);',
    IdlGenericType(:final name) =>
      '${member(name)}Codec.write($writer, $expression);',
  };

  String _codec(
    String name,
    List<IdlType> generics, [
    List<int> constGenerics = const [],
  ]) {
    final definition = context.program.types
        .where((item) => item.name == name)
        .firstOrNull;
    if (definition?.body case IdlAliasBody(:final value)) {
      final typeArguments = <String, IdlType>{
        for (var index = 0; index < definition!.generics.length; index++)
          definition.generics[index]: generics[index],
      };
      final constArguments = <String, int>{
        for (var index = 0; index < definition.constGenerics.length; index++)
          definition.constGenerics[index]: constGenerics[index],
      };
      return codecForType(
        _substituteAlias(value, typeArguments, constArguments),
      );
    }
    return generics.isEmpty && constGenerics.isEmpty
        ? '${type(name)}.codec'
        : '${type(name)}.codec(${[...generics.map((item) => codecForType(item)), ...constGenerics].join(', ')})';
  }

  int _cOptionPayloadSize(IdlType inner) => switch (inner) {
    IdlPrimitiveType(name: 'u64') => 8,
    IdlPrimitiveType(name: 'pubkey') => 32,
    _ => throw StateError(
      'Validator allowed an unsupported COption payload type.',
    ),
  };

  IdlType _substituteAlias(
    IdlType value,
    Map<String, IdlType> typeArguments,
    Map<String, int> constArguments,
  ) => switch (value) {
    IdlPrimitiveType() => value,
    IdlOptionType(:final inner) => IdlOptionType(
      _substituteAlias(inner, typeArguments, constArguments),
    ),
    IdlCOptionType(:final inner) => IdlCOptionType(
      _substituteAlias(inner, typeArguments, constArguments),
    ),
    IdlVectorType(:final inner) => IdlVectorType(
      _substituteAlias(inner, typeArguments, constArguments),
    ),
    IdlArrayType(:final inner, :final length) => IdlArrayType(
      _substituteAlias(inner, typeArguments, constArguments),
      length,
    ),
    IdlGenericArrayType(:final inner, :final lengthName) => IdlArrayType(
      _substituteAlias(inner, typeArguments, constArguments),
      constArguments[lengthName]!,
    ),
    IdlDefinedType(:final name, :final generics, :final constGenerics) =>
      IdlDefinedType(name, [
        for (final generic in generics)
          _substituteAlias(generic, typeArguments, constArguments),
      ], constGenerics: constGenerics),
    IdlGenericType(:final name) => typeArguments[name]!,
  };

  /// Builds a codec expression for an arbitrary concrete [value].
  String codecForType(IdlType value) => switch (value) {
    IdlDefinedType(:final name, :final generics, :final constGenerics) =>
      _codec(name, generics, constGenerics),
    IdlGenericType(:final name) => '${member(name)}Codec',
    _ =>
      '${type('functional_borsh_codec')}<${dartType(value)}>('
          '(reader) => ${read(value, 'reader')}, '
          '(writer, value) { ${write(value, 'writer', 'value')} })',
  };
}
