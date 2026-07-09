import 'package:code_builder/code_builder.dart';

import '../../idl.dart';
import '../section_emitter.dart';
import 'metadata_fragment.dart';
import 'type_mapping.dart';

/// Emits typed constants declared by the IDL.
final class TypeConstantsFragment extends SectionEmitter {
  /// Creates a constants fragment for [context].
  const TypeConstantsFragment(super.context);

  DartTypeMapping get _mapping => DartTypeMapping(context);

  /// Emits the constants holder class when the IDL declares constants.
  @override
  List<Spec> emit() =>
      context.program.constants.isEmpty ? const [] : [_constants()];

  Class _constants() => Class(
    (builder) => builder
      ..name = type('constants')
      ..abstract = true
      ..modifier = ClassModifier.final$
      ..docs.add('/// Typed constants declared by the IDL.')
      ..fields.addAll(context.program.constants.map(_constantField)),
  );

  Field _constantField(IdlConstantDefinition constant) {
    final dartType = _mapping.dartType(constant.type);
    final assignment = switch (constant.value) {
      IdlIntegerConstValue(:final value) when dartType == 'int' => Code(
        '${value.toInt()}',
      ),
      IdlIntegerConstValue(:final value) => Code("BigInt.parse('$value')"),
      IdlBytesConstValue(:final value) => Code(
        'Uint8List.fromList(${bytes(value)}).asUnmodifiableView()',
      ),
      IdlBooleanConstValue(:final value) => Code('$value'),
      IdlStringConstValue(:final value) => literalString(value).code,
    };
    final isConst =
        constant.value is IdlBooleanConstValue ||
        constant.value is IdlStringConstValue ||
        (constant.value is IdlIntegerConstValue && dartType == 'int');
    return Field(
      (builder) => builder
        ..name = member(constant.name)
        ..type = refer(dartType)
        ..static = true
        ..modifier = isConst ? FieldModifier.constant : FieldModifier.final$
        ..docs.addAll(
          TypeMetadataFragment.documentation(
            'IDL constant `${constant.name}`.',
            constant.docs,
          ),
        )
        ..assignment = assignment,
    );
  }
}
