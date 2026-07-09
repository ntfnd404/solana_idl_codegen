import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'enum_codec_fragment.dart';
import 'enum_variant_fragment.dart';
import 'metadata_fragment.dart';

/// Emits sealed enum bases, variants, and enum Borsh codecs.
final class TypeEnumFragment extends SectionEmitter {
  /// Creates an enum fragment for [context].
  const TypeEnumFragment(super.context);

  /// Emits the sealed enum family for [definition].
  List<Spec> emitEnum(
    IdlTypeDefinition definition,
    List<IdlEnumVariant> variants,
  ) {
    final base = type(definition.name);
    final generics = definition.generics.map(type).toList(growable: false);
    final declaration = _declaration(generics);
    return <Spec>[
      _enumBase(definition, variants, base, generics, declaration),
      for (var index = 0; index < variants.length; index++)
        TypeEnumVariantFragment(context).variant(
          definition,
          variants[index],
          index,
          base,
          generics,
          declaration,
        ),
    ];
  }

  /// This fragment emits enum families through [emitEnum].
  @override
  List<Spec> emit() => const [];

  Class _enumBase(
    IdlTypeDefinition definition,
    List<IdlEnumVariant> variants,
    String base,
    List<String> generics,
    String declaration,
  ) {
    final codec = type('borsh_codec');
    final hasParameters =
        generics.isNotEmpty || definition.constGenerics.isNotEmpty;
    return Class(
      (builder) => builder
        ..name = base
        ..sealed = true
        ..types.addAll(generics.map(refer))
        ..docs.addAll(
          TypeMetadataFragment.documentation(
            'Sealed immutable representation of `${definition.name}`.',
            definition.docs,
          ),
        )
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates an enum variant.'),
          ),
        )
        ..fields.addAll(
          hasParameters
              ? const []
              : [
                  Field(
                    (builder) => builder
                      ..name = 'codec'
                      ..type = refer('$codec<$base>')
                      ..static = true
                      ..modifier = FieldModifier.final$
                      ..docs.add('/// Borsh codec for [$base].')
                      ..assignment = Code(
                        _enumCodecExpression(
                          definition,
                          variants,
                          base,
                          declaration,
                        ),
                      ),
                  ),
                ],
        )
        ..methods.addAll(
          hasParameters
              ? [
                  Method(
                    (builder) => builder
                      ..name = 'codec'
                      ..static = true
                      ..types.addAll(generics.map(refer))
                      ..returns = refer('$codec<$base$declaration>')
                      ..docs.add(
                        '/// Creates a codec from generic argument codecs.',
                      )
                      ..requiredParameters.addAll([
                        for (final generic in generics)
                          _parameter(
                            '${member(generic)}Codec',
                            '$codec<$generic>',
                          ),
                        for (final generic in definition.constGenerics)
                          _parameter(member(generic), 'int'),
                      ])
                      ..lambda = true
                      ..body = Code(
                        _enumCodecExpression(
                          definition,
                          variants,
                          base,
                          declaration,
                        ),
                      ),
                  ),
                ]
              : const [],
        ),
    );
  }

  String _enumCodecExpression(
    IdlTypeDefinition definition,
    List<IdlEnumVariant> variants,
    String base,
    String declaration,
  ) => TypeEnumCodecFragment(
    context,
  ).codecExpression(definition, variants, base, declaration);

  String _declaration(List<String> generics) =>
      generics.isEmpty ? '' : '<${generics.join(', ')}>';

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
