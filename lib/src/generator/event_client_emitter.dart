import 'package:code_builder/code_builder.dart';

import 'event_model_emitter.dart';
import 'section_emitter.dart';

/// Emits the generated typed event subscription client.
final class EventClientEmitter extends SectionEmitter {
  /// Creates an event client emitter for [context].
  const EventClientEmitter(super.context);

  /// Emits the event client declaration.
  @override
  List<Spec> emit() => [_eventsClient()];

  Class _eventsClient() => Class(
    (builder) => builder
      ..name = type('events_client')
      ..modifier = ClassModifier.final$
      ..docs.add(
        '/// Typed event subscription client with invocation-stack parsing.',
      )
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates an event client.')
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'subscriber'
                  ..toThis = true,
              ),
            ),
        ),
      )
      ..fields.add(
        _models.field(
          'subscriber',
          type('event_subscriber'),
          'Raw log subscription capability.',
        ),
      )
      ..methods.addAll([
        Method(
          (builder) => builder
            ..name = 'subscribe'
            ..returns = refer('Future<${type('typed_event_subscription')}>')
            ..modifier = MethodModifier.async
            ..docs.add(
              '/// Subscribes and decodes events without closing on malformed logs.',
            )
            ..body = Code('''
final subscription = await subscriber.subscribe(${type('program')}.programAddress);
return ${type('typed_event_subscription')}._(
  subscription,
  subscription.batches.asyncExpand(_decodeBatch),
);'''),
        ),
        Method(
          (builder) => builder
            ..name = '_decodeBatch'
            ..returns = refer('Stream<${type('event_notification')}>')
            ..modifier = MethodModifier.asyncStar
            ..requiredParameters.add(_parameter('batch', type('log_batch')))
            ..body = Code(_decodeBatchBody()),
        ),
        Method(
          (builder) => builder
            ..name = '_decode'
            ..returns = refer('${type('event')}?')
            ..requiredParameters.add(_parameter('data', 'Uint8List'))
            ..body = Code(_decodeBody()),
        ),
        Method(
          (builder) => builder
            ..name = '_startsWith'
            ..returns = refer('bool')
            ..requiredParameters.addAll([
              _parameter('data', 'List<int>'),
              _parameter('prefix', 'List<int>'),
            ])
            ..body = const Code('''
if (data.length < prefix.length) return false;
for (var index = 0; index < prefix.length; index++) {
  if (data[index] != prefix[index]) return false;
}
return true;'''),
        ),
      ]),
  );

  String _decodeBatchBody() =>
      '''
final target = ${type('program')}.address;
final stack = <String>[];
for (final line in batch.logs) {
  final invoke = RegExp(r'^Program ([1-9A-HJ-NP-Za-km-z]+) invoke').firstMatch(line);
  if (invoke != null) {
    stack.add(invoke.group(1)!);
    continue;
  }
  final exit = RegExp(r'^Program ([1-9A-HJ-NP-Za-km-z]+) (success|failed)').firstMatch(line);
  if (exit != null) {
    if (stack.isEmpty || stack.last != exit.group(1)) {
      yield const ${type('event_diagnostic_notification')}(code: 'EVENT_STACK_MISMATCH', message: 'Program invocation stack is malformed.');
    } else {
      stack.removeLast();
    }
    continue;
  }
  if (!line.startsWith('Program data: ') || stack.isEmpty || stack.last != target) {
    continue;
  }
  Uint8List payload;
  try {
    payload = base64Decode(line.substring(14));
  } on FormatException {
    yield const ${type('event_diagnostic_notification')}(code: 'EVENT_BASE64', message: 'Event payload is not valid Base64.');
    continue;
  }
  final decoded = _decode(payload);
  if (decoded == null) {
    yield const ${type('event_diagnostic_notification')}(code: 'EVENT_DISCRIMINATOR', message: 'Unknown or truncated event discriminator.');
  } else {
    yield ${type('decoded_event_notification')}(
      event: decoded,
      context: ${type('event_context')}(signature: batch.signature, slot: batch.slot),
    );
  }
}''';

  String _decodeBody() {
    final out = StringBuffer();
    for (final event in context.program.events) {
      final wrapper = type('${event.name}_event');
      final model = type(event.name);
      out.writeln('''
if (_startsWith(data, $wrapper.discriminator)) {
  return $wrapper(
    $model.codec.decodeExact(data.sublist($wrapper.discriminator.length)),
  );
}''');
    }
    out.write('return null;');
    return out.toString();
  }

  Parameter _parameter(String name, String parameterType) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(parameterType),
  );

  EventModelEmitter get _models => EventModelEmitter(context);
}
