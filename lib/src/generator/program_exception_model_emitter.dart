import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits generated typed program exception classes.
final class ProgramExceptionModelEmitter extends SectionEmitter {
  /// Creates a program-exception emitter for [context].
  const ProgramExceptionModelEmitter(super.context);

  @override
  List<Spec> emit() => <Spec>[
    _programException(),
    for (final error in context.program.errors)
      _knownException(error.name, error.code, error.message),
    _unknownException(),
  ];

  Class _programException() => Class(
    (builder) => builder
      ..name = type('program_exception')
      ..sealed = true
      ..implements.add(refer('Exception'))
      ..docs.add('/// Base typed program exception.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates a program exception and copies logs.')
            ..optionalParameters.addAll([
              for (final field in [
                'code',
                'idlName',
                'idlMessage',
                'origin',
                'comparedValues',
                'signature',
                'failure',
              ])
                Parameter(
                  (builder) => builder
                    ..name = field
                    ..toThis = true
                    ..named = true
                    ..required = true,
                ),
              Parameter(
                (builder) => builder
                  ..name = 'rawLogs'
                  ..type = refer('List<String>')
                  ..named = true
                  ..required = true,
              ),
            ])
            ..initializers.add(
              const Code('rawLogs = List.unmodifiable(rawLogs)'),
            ),
        ),
      )
      ..fields.addAll([
        _field('code', 'int', 'Numeric program error code.'),
        _field('idlName', 'String?', 'Optional IDL error name.'),
        _field('idlMessage', 'String?', 'Optional IDL message.'),
        _field('origin', '${type('error_origin')}?', 'Optional typed origin.'),
        _field(
          'comparedValues',
          '${type('compared_values')}?',
          'Optional values compared by the failed constraint.',
        ),
        _field('rawLogs', 'List<String>', 'Ordered raw logs.'),
        _field('signature', 'String?', 'Optional transaction signature.'),
        _field(
          'failure',
          '${type('transaction_failure')}?',
          'Optional transport-neutral transaction failure.',
        ),
      ]),
  );

  Class _knownException(String sourceName, int code, String message) {
    final name = type('${sourceName}_exception');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..extend = refer(type('program_exception'))
        ..docs.add('/// IDL error `$sourceName` ($code).')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..docs.add('/// Creates this typed program exception.')
              ..optionalParameters.addAll(exceptionParameters())
              ..initializers.add(
                Code(
                  "super(code: $code, idlName: '${escape(sourceName)}', "
                  "idlMessage: '${escape(message)}', origin: origin, "
                  'comparedValues: comparedValues, rawLogs: rawLogs, '
                  'signature: signature, failure: failure)',
                ),
              ),
          ),
        ),
    );
  }

  Class _unknownException() => Class(
    (builder) => builder
      ..name = type('unknown_program_exception')
      ..modifier = ClassModifier.final$
      ..extend = refer(type('program_exception'))
      ..docs.add('/// Unknown custom or framework program error.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates an unknown program exception.')
            ..optionalParameters.addAll([
              Parameter(
                (builder) => builder
                  ..name = 'code'
                  ..type = refer('int')
                  ..named = true
                  ..required = true,
              ),
              ...exceptionParameters(),
            ])
            ..initializers.add(
              const Code(
                'super(code: code, idlName: null, idlMessage: null, '
                'origin: origin, comparedValues: comparedValues, '
                'rawLogs: rawLogs, signature: signature, failure: failure)',
              ),
            ),
        ),
      ),
  );

  /// Shared constructor parameters for typed program exceptions.
  List<Parameter> exceptionParameters() => [
    _named('origin', '${type('error_origin')}?'),
    _named('comparedValues', '${type('compared_values')}?'),
    _named('rawLogs', 'List<String>', defaultValue: 'const []'),
    _named('signature', 'String?'),
    _named('failure', '${type('transaction_failure')}?'),
  ];

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );

  Parameter _named(String name, String parameterType, {String? defaultValue}) =>
      Parameter(
        (builder) => builder
          ..name = name
          ..type = refer(parameterType)
          ..named = true
          ..defaultTo = defaultValue == null ? null : Code(defaultValue),
      );
}
