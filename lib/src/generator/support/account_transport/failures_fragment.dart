import 'package:code_builder/code_builder.dart';

import '../../section_emitter.dart';

/// Emits transport-neutral transaction, account, and view failures.
final class TransportFailuresFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const TransportFailuresFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[
    _failure(
      type('transaction_failure'),
      'Neutral transaction failure supplied by an application adapter.',
      'Adapter-defined stable code.',
      'Human-readable failure message.',
      exception: false,
    ),
    _failure(
      type('account_exception'),
      'Typed account read, ownership, decoding, or capability failure.',
      'Stable generated SDK error code.',
      'Human-readable failure description.',
    ),
    _failure(
      type('view_exception'),
      'Typed view simulation or return-data failure.',
      'Stable generated SDK error code.',
      'Human-readable failure description.',
    ),
  ];

  Class _failure(
    String name,
    String summary,
    String codeDocs,
    String messageDocs, {
    bool exception = true,
  }) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// $summary')
      ..implements.addAll(exception ? [refer('Exception')] : const [])
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add(
              exception
                  ? '/// Creates a failure with a stable machine-readable [code].'
                  : '/// Creates a failure.',
            )
            ..optionalParameters.addAll([
              _thisParameter('code'),
              _thisParameter('message'),
            ]),
        ),
      )
      ..fields.addAll([
        _field('code', codeDocs),
        _field('message', messageDocs),
      ])
      ..methods.addAll(
        exception
            ? [
                Method(
                  (builder) => builder
                    ..name = 'toString'
                    ..returns = refer('String')
                    ..annotations.add(refer('override'))
                    ..lambda = true
                    ..body = Code("'$name(\$code: \$message)'"),
                ),
              ]
            : const [],
      ),
  );

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );

  Field _field(String name, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer('String')
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
