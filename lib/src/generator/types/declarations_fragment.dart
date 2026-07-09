import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'constants_fragment.dart';
import 'enum_fragment.dart';
import 'metadata_fragment.dart';
import 'struct_fragment.dart';
import 'type_mapping.dart';

/// Emits model, enum, alias, codec, metadata, and constant declarations.
final class TypeDeclarationsFragment extends SectionEmitter {
  /// Creates a type declaration fragment for [context].
  const TypeDeclarationsFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);

  @override
  List<Spec> emit() {
    final result = <Spec>[...TypeMetadataFragment(context).emit()];
    for (final definition in context.program.types) {
      result.addAll(_definition(definition));
    }
    result.addAll(TypeConstantsFragment(context).emit());
    return List<Spec>.unmodifiable(result);
  }

  List<Spec> _definition(
    IdlTypeDefinition definition,
  ) => switch (definition.body) {
    IdlAliasBody(:final value) => [
      TypeDef(
        (builder) => builder
          ..name = type(definition.name)
          ..types.addAll(definition.generics.map((name) => refer(type(name))))
          ..docs.addAll(
            TypeMetadataFragment.documentation(
              'Dart representation of the IDL alias `${definition.name}`.',
              definition.docs,
            ),
          )
          ..definition = refer(_mapping.dartType(value)),
      ),
    ],
    IdlStructBody(:final fields, :final tupleFields) => [
      TypeStructFragment(context).emitStruct(definition, fields, tupleFields),
    ],
    IdlEnumBody(:final variants) => TypeEnumFragment(
      context,
    ).emitEnum(definition, variants),
  };
}
