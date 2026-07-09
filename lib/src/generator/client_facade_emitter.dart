import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits the optional generated facade over specialized clients.
final class ClientFacadeEmitter extends SectionEmitter {
  /// Creates a client facade emitter for [context].
  const ClientFacadeEmitter(super.context);

  /// Emits the complete client facade declaration.
  @override
  List<Spec> emit() => [_clientFacade()];

  Class _clientFacade() => Class(
    (builder) => builder
      ..name = type('client')
      ..modifier = ClassModifier.final$
      ..docs.add('/// Optional facade over specialized generated clients.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add(
              '/// Creates a facade from only the capabilities an application uses.',
            )
            ..optionalParameters.addAll([
              Parameter(
                (builder) => builder
                  ..name = 'instructions'
                  ..toThis = true
                  ..named = true
                  ..defaultTo = Code('const ${type('instructions_client')}()'),
              ),
              for (final name in const ['accounts', 'events', 'views'])
                Parameter(
                  (builder) => builder
                    ..name = name
                    ..toThis = true
                    ..named = true,
                ),
            ]),
        ),
      )
      ..fields.addAll([
        _field(
          'instructions',
          type('instructions_client'),
          'Instruction construction client.',
        ),
        _field(
          'accounts',
          '${type('accounts_client')}?',
          'Optional account client.',
        ),
        _field('events', '${type('events_client')}?', 'Optional event client.'),
        _field(
          'views',
          '${type('view_client')}?',
          'Optional typed view client.',
        ),
      ]),
  );

  Field _field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
