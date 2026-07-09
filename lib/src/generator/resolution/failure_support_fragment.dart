import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits generated account-resolution failure declarations.
final class FailureSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const FailureSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final cause = type('account_resolution_cause');
    return <Spec>[
      _cause(cause),
      _exception(type('account_resolution_exception'), cause),
    ];
  }

  Class _cause(String name) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// One deterministic account-resolution failure.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a cause.')
            ..optionalParameters.addAll([
              _thisRequired('path'),
              _thisRequired('code'),
              _thisRequired('message'),
            ]),
        ),
      )
      ..fields.addAll([
        _field('path', 'String', 'Account path.'),
        _field('code', 'String', 'Stable failure code.'),
        _field('message', 'String', 'Human-readable explanation.'),
      ]),
  );

  Class _exception(String name, String cause) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..implements.add(refer('Exception'))
      ..docs.add('/// Aggregate account-resolution exception.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates an exception and copies ordered causes.')
            ..requiredParameters.add(_parameter('causes', 'List<$cause>'))
            ..initializers.add(
              const Code('causes = List.unmodifiable(causes)'),
            ),
        ),
      )
      ..fields.add(
        _field(
          'causes',
          'List<$cause>',
          'Ordered unresolved accounts and reasons.',
        ),
      )
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'toString'
            ..returns = refer('String')
            ..annotations.add(refer('override'))
            ..lambda = true
            ..body = Code("'$name: \${causes.length} unresolved account(s)'"),
        ),
      ),
  );

  Parameter _thisRequired(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );

  Parameter _parameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type),
  );

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
