import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits generated program-error value object hierarchies.
final class ErrorValueEmitter extends SectionEmitter {
  /// Creates an error-value emitter for [context].
  const ErrorValueEmitter(super.context);

  @override
  List<Spec> emit() => <Spec>[
    sealedBase('error_origin', 'Origin reported by Anchor error logs.'),
    valueClass(
      'account_error_origin',
      type('error_origin'),
      'Account-name error origin.',
      [('name', 'String', 'IDL account name.')],
    ),
    valueClass(
      'program_error_origin',
      type('error_origin'),
      'Program-address error origin.',
      [('address', type('address'), 'Program address.')],
    ),
    sealedBase(
      'compared_values',
      'Compared values reported by Anchor error logs.',
    ),
    valueClass(
      'text_compared_values',
      type('compared_values'),
      'Compared textual values whose wire type is unknown.',
      [('left', 'String', 'Left value.'), ('right', 'String', 'Right value.')],
      named: true,
    ),
  ];

  /// Emits one sealed base class.
  Class sealedBase(String name, String docs) => Class(
    (builder) => builder
      ..name = type(name)
      ..sealed = true
      ..docs.add('/// $docs')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a ${name.replaceAll('_', ' ')}.'),
        ),
      ),
  );

  /// Emits an immutable value class under [parent].
  Class valueClass(
    String name,
    String parent,
    String docs,
    List<(String, String, String)> fields, {
    bool named = false,
  }) => Class(
    (builder) => builder
      ..name = type(name)
      ..modifier = ClassModifier.final$
      ..extend = refer(parent)
      ..docs.add('/// $docs')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates $docs')
            ..requiredParameters.addAll(
              named
                  ? const []
                  : fields.map(
                      (field) => Parameter(
                        (builder) => builder
                          ..name = field.$1
                          ..toThis = true,
                      ),
                    ),
            )
            ..optionalParameters.addAll(
              named
                  ? fields.map(
                      (field) => Parameter(
                        (builder) => builder
                          ..name = field.$1
                          ..toThis = true
                          ..named = true
                          ..required = true,
                      ),
                    )
                  : const [],
            ),
        ),
      )
      ..fields.addAll(
        fields.map((field) => _field(field.$1, field.$2, field.$3)),
      ),
  );

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
