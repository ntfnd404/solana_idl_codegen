import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'enum_fields.dart';
import 'type_mapping.dart';

/// Emits Borsh codec expressions for generated sealed enum families.
final class TypeEnumCodecFragment extends SectionEmitter {
  /// Creates an enum codec fragment for [context].
  const TypeEnumCodecFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);

  /// This fragment contributes codec expressions, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Builds the generated codec expression for an enum [definition].
  String codecExpression(
    IdlTypeDefinition definition,
    List<IdlEnumVariant> variants,
    String base,
    String declaration,
  ) {
    final functional = type('functional_borsh_codec');
    final fields = const EnumFieldCollector();
    final out = StringBuffer()
      ..writeln('$functional<$base$declaration>(')
      ..writeln('  (reader) {')
      ..writeln('    final tag = reader.readInt(1);')
      ..writeln('    return switch (tag) {');
    for (var index = 0; index < variants.length; index++) {
      final variant = variants[index];
      final variantName = type('${definition.name}_${variant.name}');
      out.writeln('      $index => $variantName$declaration(');
      final variantFields = fields.collect(variant);
      for (final field in variantFields) {
        out.writeln(
          "        ${context.fieldMember(variantFields, field)}: reader.field("
          "'${escape(field.name)}', "
          "() => ${_mapping.read(field.type, 'reader')}),",
        );
      }
      out.writeln('      ),');
    }
    out
      ..writeln(
        "      _ => throw ${type('borsh_exception')}("
        "code: 'BORSH_ENUM_TAG', message: 'Invalid enum tag.', "
        "offset: reader.offset - 1, path: r'\\\$'),",
      )
      ..writeln('    };')
      ..writeln('  },')
      ..writeln('  (writer, value) {')
      ..writeln('    switch (value) {');
    for (var index = 0; index < variants.length; index++) {
      final variant = variants[index];
      final variantName = type('${definition.name}_${variant.name}');
      out
        ..writeln('      case $variantName$declaration():')
        ..writeln('        writer.writeUnsigned(BigInt.from($index), 1);');
      final variantFields = fields.collect(variant);
      for (final field in variantFields) {
        out.writeln(
          '        ${_mapping.write(field.type, 'writer', 'value.${context.fieldMember(variantFields, field)}')}',
        );
      }
    }
    out
      ..writeln('    }')
      ..writeln('  },')
      ..write(')');
    return out.toString();
  }
}
