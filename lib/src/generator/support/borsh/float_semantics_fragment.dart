import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits canonical floating-point construction rules.
final class BorshFloatSemanticsFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshFloatSemanticsFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    Class(
      (builder) => builder
        ..name = type('float_semantics')
        ..abstract = true
        ..modifier = ClassModifier.final$
        ..docs.add(
          '/// Canonical floating-point construction rules used by generated models.',
        )
        ..methods.addAll([
          _floatMethod(
            'f32',
            'Rejects NaN and rounds [value] to its IEEE-754 f32 representation.',
            const Code('''
if (value.isNaN) {
  throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
}
final bytes = Uint8List(4);
final data = ByteData.sublistView(bytes)
  ..setFloat32(0, value, Endian.little);
return data.getFloat32(0, Endian.little);'''),
          ),
          _floatMethod(
            'f64',
            'Rejects NaN and returns an f64 value unchanged.',
            const Code('''
if (value.isNaN) {
  throw ArgumentError.value(value, 'value', 'NaN is not canonical Borsh.');
}
return value;'''),
          ),
        ]),
    ),
  ];

  Method _floatMethod(String name, String docs, Code body) => Method(
    (builder) => builder
      ..name = name
      ..static = true
      ..returns = refer('double')
      ..docs.add('/// $docs')
      ..requiredParameters.add(
        Parameter(
          (builder) => builder
            ..name = 'value'
            ..type = refer('double'),
        ),
      )
      ..body = body,
  );
}
