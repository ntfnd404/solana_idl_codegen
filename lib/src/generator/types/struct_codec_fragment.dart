import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'type_mapping.dart';

/// Emits Borsh codec fields and methods for generated struct models.
final class TypeStructCodecFragment extends SectionEmitter {
  /// Creates a struct codec fragment for [context].
  const TypeStructCodecFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);

  /// This fragment contributes codec members, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits static codec fields for non-generic structs.
  Iterable<Field> fields(
    String className,
    String declaration,
    List<IdlField> fields,
    List<String> constGenerics,
  ) {
    if (declaration.isNotEmpty || constGenerics.isNotEmpty) return const [];
    final codec = type('borsh_codec');
    return [
      Field(
        (builder) => builder
          ..name = 'codec'
          ..type = refer('$codec<$className>')
          ..static = true
          ..modifier = FieldModifier.final$
          ..docs.add('/// Borsh codec for [$className].')
          ..assignment = Code(codecExpression(className, '', fields)),
      ),
    ];
  }

  /// Emits static codec factory methods for generic structs.
  Iterable<Method> methods(
    String className,
    String declaration,
    List<IdlField> fields,
    List<String> constGenerics,
  ) {
    final generics = genericNames(declaration);
    if (generics.isEmpty && constGenerics.isEmpty) return const [];
    final codec = type('borsh_codec');
    return [
      Method(
        (builder) => builder
          ..name = 'codec'
          ..static = true
          ..types.addAll(generics.map(refer))
          ..returns = refer('$codec<$className$declaration>')
          ..docs.add('/// Creates a codec from generic argument codecs.')
          ..requiredParameters.addAll([
            for (final generic in generics)
              _parameter('${member(generic)}Codec', '$codec<$generic>'),
            for (final generic in constGenerics)
              _parameter(member(generic), 'int'),
          ])
          ..lambda = true
          ..body = Code(codecExpression(className, declaration, fields)),
      ),
    ];
  }

  /// Builds the generated codec expression for a struct model.
  String codecExpression(
    String className,
    String declaration,
    List<IdlField> fields,
  ) {
    final functional = type('functional_borsh_codec');
    final out = StringBuffer()
      ..writeln('$functional<$className$declaration>(')
      ..writeln('  (reader) => $className(');
    for (final field in fields) {
      out.writeln(
        "    ${context.fieldMember(fields, field)}: reader.field("
        "'${escape(field.name)}', "
        "() => ${_mapping.read(field.type, 'reader')}),",
      );
    }
    out
      ..writeln('  ),')
      ..writeln('  (writer, value) {');
    for (final field in fields) {
      out.writeln(
        '    ${_mapping.write(field.type, 'writer', 'value.${context.fieldMember(fields, field)}')}',
      );
    }
    out
      ..writeln('  },')
      ..write(')');
    return out.toString();
  }

  /// Extracts type generic names from a generated declaration string.
  List<String> genericNames(String declaration) => declaration.isEmpty
      ? const []
      : declaration.substring(1, declaration.length - 1).split(', ');

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
