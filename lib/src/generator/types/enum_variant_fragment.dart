import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'enum_fields.dart';
import 'metadata_fragment.dart';
import 'type_mapping.dart';
import 'value_semantics.dart';

/// Emits concrete variant classes for generated sealed enum families.
final class TypeEnumVariantFragment extends SectionEmitter {
  /// Creates an enum variant fragment for [context].
  const TypeEnumVariantFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);
  GeneratedValueSemantics get _values => GeneratedValueSemantics(context);

  /// This fragment emits variants through [variant].
  @override
  List<Spec> emit() => const [];

  /// Emits one concrete enum variant class.
  Class variant(
    IdlTypeDefinition definition,
    IdlEnumVariant variant,
    int tag,
    String base,
    List<String> generics,
    String declaration,
  ) {
    final name = type('${definition.name}_${variant.name}');
    final fields = const EnumFieldCollector().collect(variant);
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..types.addAll(generics.map(refer))
        ..extend = refer('$base$declaration')
        ..docs.addAll(
          TypeMetadataFragment.documentation(
            'The `${variant.name}` variant of [$base].',
            variant.docs,
          ),
        )
        ..constructors.add(_modelConstructor(fields, unit: fields.isEmpty))
        ..fields.addAll([
          for (final field in fields)
            Field(
              (builder) => builder
                ..name = context.fieldMember(fields, field)
                ..type = refer(_mapping.dartType(field.type))
                ..modifier = FieldModifier.final$
                ..docs.addAll(_fieldDocs(fields, field)),
            ),
        ])
        ..methods.addAll([
          _equality(name, declaration, fields),
          _hashCode(fields, tag: tag),
        ]),
    );
  }

  Constructor _modelConstructor(
    List<IdlField> fields, {
    required bool unit,
  }) => Constructor((builder) {
    builder
      ..constant = unit
      ..docs.add(
        unit
            ? '/// Creates the unit value.'
            : '/// Creates a validated immutable value.',
      );
    for (final field in fields) {
      final fieldName = context.fieldMember(fields, field);
      builder.optionalParameters.add(
        Parameter(
          (builder) => builder
            ..name = fieldName
            ..type = refer(_parameterType(field.type))
            ..named = true
            ..required = true,
        ),
      );
      builder.initializers.add(
        Code(
          '$fieldName = '
          '${_values.immutableExpression(field.type, fieldName)}',
        ),
      );
    }
    final floats = fields.where(
      (field) =>
          field.type is IdlPrimitiveType &&
          const {'f32', 'f64'}.contains((field.type as IdlPrimitiveType).name),
    );
    if (floats.isNotEmpty) {
      builder.body = Code(
        [
          for (final field in floats)
            "if (${context.fieldMember(fields, field)}.isNaN) { "
                "throw ArgumentError.value(${context.fieldMember(fields, field)}, "
                "'${context.fieldMember(fields, field)}', 'NaN is not supported.'); }",
        ].join('\n'),
      );
    }
  });

  Method _equality(
    String className,
    String declaration,
    List<IdlField> fields,
  ) {
    final valueConditions = [
      for (final field in fields)
        _values.equal(
          field.type,
          context.fieldMember(fields, field),
          'other.${context.fieldMember(fields, field)}',
        ),
    ];
    final structural =
        'other is $className$declaration'
        '${valueConditions.isEmpty ? '' : ' && ${valueConditions.join(' && ')}'}';
    return Method(
      (builder) => builder
        ..name = 'operator =='
        ..returns = refer('bool')
        ..annotations.add(refer('override'))
        ..requiredParameters.add(_parameter('other', 'Object'))
        ..lambda = true
        ..body = Code('identical(this, other) || ($structural)'),
    );
  }

  Method _hashCode(List<IdlField> fields, {int? tag}) => Method(
    (builder) => builder
      ..name = 'hashCode'
      ..type = MethodType.getter
      ..returns = refer('int')
      ..annotations.add(refer('override'))
      ..lambda = true
      ..body = Code(
        'Object.hashAll([${[if (tag != null) '$tag', ...fields.map((field) => _values.hash(field.type, context.fieldMember(fields, field)))].join(', ')}])',
      ),
  );

  List<String> _fieldDocs(List<IdlField> scope, IdlField field) {
    final dartName = context.fieldMember(scope, field);
    final docs = ['/// Variant field `${field.name}`.'];
    if (dartName != member(field.name)) {
      docs.add(
        '/// Generated Dart name `$dartName` for `${field.sourcePath}`.',
      );
    }
    return docs;
  }

  String _parameterType(IdlType type) => switch (type) {
    IdlPrimitiveType(name: 'bytes') => 'List<int>',
    IdlVectorType(:final inner) ||
    IdlArrayType(:final inner) ||
    IdlGenericArrayType(:final inner) => 'List<${_mapping.dartType(inner)}>',
    _ => _mapping.dartType(type),
  };

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );
}
