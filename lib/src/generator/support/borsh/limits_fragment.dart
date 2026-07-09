import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits Borsh decoder resource limits.
final class BorshLimitsFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const BorshLimitsFragment(super.context);

  @override
  List<Spec> emit() {
    final name = type('decode_limits');
    return <Spec>[
      Class(
        (builder) => builder
          ..name = name
          ..modifier = ClassModifier.final$
          ..docs.add(
            '/// Resource limits applied by every public Borsh decoder.',
          )
          ..constructors.add(
            Constructor(
              (builder) => builder
                ..constant = true
                ..docs.add('/// Creates explicit decoder limits.')
                ..optionalParameters.addAll([
                  _parameter('maxInputBytes'),
                  _parameter('maxStringBytes'),
                  _parameter('maxCollectionLength'),
                  _parameter('maxTotalElements'),
                  _parameter('maxNestingDepth'),
                ]),
            ),
          )
          ..fields.addAll([
            Field(
              (builder) => builder
                ..name = 'defaults'
                ..static = true
                ..modifier = FieldModifier.constant
                ..docs.add(
                  '/// Recommended limits for untrusted account and event data.',
                )
                ..assignment = Code('''
$name(
  maxInputBytes: 16 * 1024 * 1024,
  maxStringBytes: 4 * 1024 * 1024,
  maxCollectionLength: 1000000,
  maxTotalElements: 2000000,
  maxNestingDepth: 128,
)'''),
            ),
            _field('maxInputBytes', 'Maximum input bytes.'),
            _field('maxStringBytes', 'Maximum UTF-8 string bytes.'),
            _field(
              'maxCollectionLength',
              'Maximum elements in one collection.',
            ),
            _field(
              'maxTotalElements',
              'Maximum total decoded collection elements.',
            ),
            _field('maxNestingDepth', 'Maximum nested codec depth.'),
          ]),
      ),
    ];
  }

  Parameter _parameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );

  Field _field(String name, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer('int')
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
