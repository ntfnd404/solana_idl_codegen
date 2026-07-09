import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'metadata_fragment.dart';
import 'struct_codec_fragment.dart';
import 'struct_fields.dart';
import 'struct_value_fragment.dart';

/// Emits immutable struct and tuple-struct models with Borsh codecs.
final class TypeStructFragment extends SectionEmitter {
  /// Creates a struct fragment for [context].
  const TypeStructFragment(super.context);

  /// Emits a struct or tuple-struct declaration for [definition].
  Class emitStruct(
    IdlTypeDefinition definition,
    List<IdlField> namedFields,
    List<IdlType> tupleFields,
  ) {
    final name = type(definition.name);
    final generics = definition.generics.map(type).toList(growable: false);
    final declaration = _declaration(generics);
    final fields = const StructFieldCollector().collect(
      namedFields,
      tupleFields,
    );
    final value = TypeStructValueFragment(context);
    final codec = TypeStructCodecFragment(context);
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..types.addAll(generics.map(refer))
        ..docs.addAll(
          TypeMetadataFragment.documentation(
            'Immutable Borsh value for `${definition.name}`.',
            definition.docs,
          ),
        )
        ..constructors.add(value.constructor(fields, unit: fields.isEmpty))
        ..fields.addAll(fields.map((field) => value.modelField(fields, field)))
        ..fields.addAll(
          codec.fields(name, declaration, fields, definition.constGenerics),
        )
        ..methods.addAll([
          ...codec.methods(name, declaration, fields, definition.constGenerics),
          value.equality(name, declaration, fields),
          value.hashCodeMethod(fields),
        ]),
    );
  }

  /// This fragment emits per-definition structs through [emitStruct].
  @override
  List<Spec> emit() => const [];

  String _declaration(List<String> generics) =>
      generics.isEmpty ? '' : '<${generics.join(', ')}>';
}
