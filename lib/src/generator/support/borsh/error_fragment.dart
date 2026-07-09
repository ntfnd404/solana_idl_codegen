import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits structured Borsh decoding failures.
final class BorshErrorFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshErrorFragment(super.context);

  @override
  List<Spec> emit() {
    final name = type('borsh_exception');
    return <Spec>[
      Class(
        (builder) => builder
          ..name = name
          ..modifier = ClassModifier.final$
          ..implements.add(refer('Exception'))
          ..docs.add(
            '/// Borsh failure with byte offset and logical field path.',
          )
          ..constructors.add(
            Constructor(
              (builder) => builder
                ..constant = true
                ..docs.add('/// Creates a structured Borsh failure.')
                ..optionalParameters.addAll([
                  _parameter('code'),
                  _parameter('message'),
                  _parameter('offset'),
                  _parameter('path'),
                  _parameter('expected', required: false),
                  _parameter('actual', required: false),
                  _parameter('cause', required: false),
                ]),
            ),
          )
          ..fields.addAll([
            _field('code', 'String', 'Stable failure code.'),
            _field('message', 'String', 'Human-readable failure message.'),
            _field('offset', 'int', 'Byte offset at which decoding failed.'),
            _field('path', 'String', 'Logical field path.'),
            _field(
              'expected',
              'String?',
              'Optional expected value description.',
            ),
            _field('actual', 'String?', 'Optional actual value description.'),
            _field(
              'cause',
              'String?',
              'Sanitized underlying failure description.',
            ),
          ])
          ..methods.add(
            Method(
              (builder) => builder
                ..name = 'toString'
                ..returns = refer('String')
                ..annotations.add(refer('override'))
                ..lambda = true
                ..body = Code("'$name(\$code at \$path+\$offset: \$message)'"),
            ),
          ),
      ),
    ];
  }

  Parameter _parameter(String name, {bool required = true}) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = required
      ..toThis = true,
  );

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
