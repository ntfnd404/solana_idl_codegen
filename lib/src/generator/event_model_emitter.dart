import 'package:code_builder/code_builder.dart';

import 'section_emitter.dart';

/// Emits generated event wrapper and notification model classes.
final class EventModelEmitter extends SectionEmitter {
  /// Creates an event model emitter for [context].
  const EventModelEmitter(super.context);

  /// Emits event model declarations for the current program.
  @override
  List<Spec> emit() => List.unmodifiable([
    _eventBase(),
    for (final event in context.program.events)
      _eventWrapper(event.name, event.discriminator),
    _eventContext(),
    _notificationBase(),
    _decodedNotification(),
    _diagnosticNotification(),
    _typedSubscription(),
  ]);

  Class _eventBase() => Class(
    (builder) => builder
      ..name = type('event')
      ..sealed = true
      ..docs.add('/// Base class for decoded program events.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a decoded event wrapper.'),
        ),
      ),
  );

  Class _eventWrapper(String eventName, List<int> discriminator) {
    final name = type('${eventName}_event');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..extend = refer(type('event'))
        ..docs.add('/// Decoded `$eventName` event.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates an event wrapper.')
              ..requiredParameters.add(
                Parameter(
                  (builder) => builder
                    ..name = 'value'
                    ..toThis = true,
                ),
              ),
          ),
        )
        ..fields.addAll([
          field('value', type(eventName), 'Typed event payload.'),
          Field(
            (builder) => builder
              ..name = 'discriminator'
              ..type = refer('List<int>')
              ..static = true
              ..modifier = FieldModifier.final$
              ..docs.add('/// IDL event discriminator.')
              ..assignment = Code('List.unmodifiable(${bytes(discriminator)})'),
          ),
        ]),
    );
  }

  Class _eventContext() => immutableClass(
    name: 'event_context',
    docs: 'Context attached to every decoded event notification.',
    constructorDocs: 'Creates event context.',
    fields: [
      ('signature', 'String', 'Transaction signature.'),
      ('slot', 'BigInt', 'Context slot.'),
    ],
  );

  Class _notificationBase() => Class(
    (builder) => builder
      ..name = type('event_notification')
      ..sealed = true
      ..docs.add(
        '/// One typed event notification or recoverable log diagnostic.',
      )
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates a notification.'),
        ),
      ),
  );

  Class _decodedNotification() => immutableClass(
    name: 'decoded_event_notification',
    docs: 'Successfully decoded event notification.',
    constructorDocs: 'Creates a decoded notification.',
    parent: type('event_notification'),
    fields: [
      ('event', type('event'), 'Typed event.'),
      ('context', type('event_context'), 'Transaction context.'),
    ],
  );

  Class _diagnosticNotification() => immutableClass(
    name: 'event_diagnostic_notification',
    docs: 'Recoverable malformed or truncated log notification.',
    constructorDocs: 'Creates a diagnostic notification.',
    parent: type('event_notification'),
    fields: [
      ('code', 'String', 'Stable diagnostic code.'),
      ('message', 'String', 'Human-readable diagnostic.'),
    ],
  );

  Class _typedSubscription() => Class(
    (builder) => builder
      ..name = type('typed_event_subscription')
      ..modifier = ClassModifier.final$
      ..docs.add('/// Closeable typed event subscription.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..name = '_'
            ..docs.add('/// Creates a typed wrapper around a raw subscription.')
            ..requiredParameters.addAll([
              Parameter(
                (builder) => builder
                  ..name = '_raw'
                  ..toThis = true,
              ),
              Parameter(
                (builder) => builder
                  ..name = 'notifications'
                  ..toThis = true,
              ),
            ]),
        ),
      )
      ..fields.addAll([
        Field(
          (builder) => builder
            ..name = '_raw'
            ..type = refer(type('event_subscription'))
            ..modifier = FieldModifier.final$,
        ),
        Field(
          (builder) => builder
            ..name = '_closed'
            ..type = refer('bool')
            ..assignment = const Code('false'),
        ),
        field(
          'notifications',
          'Stream<${type('event_notification')}>',
          'Typed events and recoverable malformed-log diagnostics.',
        ),
      ])
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'close'
            ..returns = refer('Future<void>')
            ..modifier = MethodModifier.async
            ..docs.add('/// Closes the raw subscription exactly once.')
            ..body = const Code('''
if (_closed) return;
_closed = true;
await _raw.close();'''),
        ),
      ),
  );

  /// Emits a simple immutable value class.
  Class immutableClass({
    required String name,
    required String docs,
    required String constructorDocs,
    required List<(String, String, String)> fields,
    String? parent,
  }) => Class(
    (builder) => builder
      ..name = type(name)
      ..modifier = ClassModifier.final$
      ..extend = parent == null ? null : refer(parent)
      ..docs.add('/// $docs')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// $constructorDocs')
            ..optionalParameters.addAll(
              fields.map(
                (field) => Parameter(
                  (builder) => builder
                    ..name = field.$1
                    ..toThis = true
                    ..named = true
                    ..required = true,
                ),
              ),
            ),
        ),
      )
      ..fields.addAll(
        fields.map((field) => this.field(field.$1, field.$2, field.$3)),
      ),
  );

  /// Emits a documented final field.
  Field field(String name, String fieldType, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(fieldType)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
