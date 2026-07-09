import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'metadata_fragment.dart';
import 'type_mapping.dart';
import 'value_semantics.dart';

/// Emits struct constructors, fields, equality, and hashCode members.
final class TypeStructValueFragment extends SectionEmitter {
  /// Creates a struct value fragment for [context].
  const TypeStructValueFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);
  GeneratedValueSemantics get _values => GeneratedValueSemantics(context);

  /// This fragment contributes class members, not top-level specs.
  @override
  List<Spec> emit() => const [];

  /// Emits the validating constructor for [fields].
  Constructor constructor(
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
            ..type = refer(parameterType(field.type))
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

  /// Emits one immutable field declaration.
  Field modelField(List<IdlField> scope, IdlField field) {
    final dartName = context.fieldMember(scope, field);
    final baseName = member(field.name);
    final docs = TypeMetadataFragment.documentation(
      'Value of the IDL field `${field.name}`.',
      field.docs,
    );
    if (dartName != baseName) {
      docs.add(
        '/// Generated Dart name `$dartName` for `${field.sourcePath}`.',
      );
    }
    return Field(
      (builder) => builder
        ..name = dartName
        ..type = refer(_mapping.dartType(field.type))
        ..modifier = FieldModifier.final$
        ..docs.addAll(docs),
    );
  }

  /// Emits structural equality for a generated struct class.
  Method equality(String className, String declaration, List<IdlField> fields) {
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

  /// Emits stable structural hashCode for a generated struct class.
  Method hashCodeMethod(List<IdlField> fields) => Method(
    (builder) => builder
      ..name = 'hashCode'
      ..type = MethodType.getter
      ..returns = refer('int')
      ..annotations.add(refer('override'))
      ..lambda = true
      ..body = Code(
        'Object.hashAll([${fields.map((field) => _values.hash(field.type, context.fieldMember(fields, field))).join(', ')}])',
      ),
  );

  /// Returns the constructor parameter type for [type].
  String parameterType(IdlType type) => switch (type) {
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
