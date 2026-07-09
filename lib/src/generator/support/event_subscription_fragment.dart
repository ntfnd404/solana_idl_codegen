import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits event-subscription support value objects and ports.
final class EventSubscriptionSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const EventSubscriptionSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final failure = type('transaction_failure');
    final subscriber = type('event_subscriber');
    final subscription = type('event_subscription');
    final logBatch = type('log_batch');
    return <Spec>[
      _logBatch(logBatch, address, failure),
      _subscription(subscription, logBatch),
      _subscriber(subscriber, subscription, address),
      _subscriberCallback(subscriber, subscription, address),
    ];
  }

  Class _logBatch(String name, String address, String failure) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Immutable raw log notification.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates a batch and copies ordered [logs].')
            ..optionalParameters.addAll([
              _thisParameter('programAddress'),
              _thisParameter('signature'),
              _thisParameter('slot'),
              _thisParameter('failure'),
              _namedParameter('logs', 'List<String>'),
            ])
            ..initializers.add(const Code('logs = List.unmodifiable(logs)')),
        ),
      )
      ..fields.addAll([
        _field(
          'programAddress',
          address,
          '/// Program address associated with the subscription.',
        ),
        _field('signature', 'String', '/// Transaction signature.'),
        _field('slot', 'BigInt', '/// Context slot.'),
        _field(
          'failure',
          '$failure?',
          '/// Optional neutral transaction failure.',
        ),
        _field('logs', 'List<String>', '/// Ordered program logs.'),
      ]),
  );

  Class _subscription(String name, String logBatch) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add('/// Closeable raw event subscription.')
      ..methods.addAll([
        Method(
          (builder) => builder
            ..name = 'batches'
            ..type = MethodType.getter
            ..returns = refer('Stream<$logBatch>')
            ..docs.add(
              '/// Raw log stream. Transport failures are delivered as stream errors.',
            ),
        ),
        Method(
          (builder) => builder
            ..name = 'close'
            ..returns = refer('Future<void>')
            ..docs.add(
              '/// Closes the subscription. Implementations must be idempotent.',
            ),
        ),
      ]),
  );

  Class _subscriber(String name, String subscription, String address) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add('/// Port used by generated event clients.')
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'subscribe'
            ..returns = refer('Future<$subscription>')
            ..docs.add('/// Subscribes to logs for [programAddress].')
            ..requiredParameters.add(_parameter('programAddress', address)),
        ),
      ),
  );

  Class _subscriberCallback(
    String subscriber,
    String subscription,
    String address,
  ) {
    final name = type('event_subscriber_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(subscriber))
        ..docs.add('/// Callback adapter for [$subscriber].')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates an adapter from [callback].')
              ..requiredParameters.add(
                Parameter(
                  (builder) => builder
                    ..name = 'callback'
                    ..toThis = true,
                ),
              ),
          ),
        )
        ..fields.add(
          _field(
            'callback',
            'Future<$subscription> Function($address)',
            '/// Subscription callback.',
          ),
        )
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'subscribe'
              ..returns = refer('Future<$subscription>')
              ..annotations.add(refer('override'))
              ..requiredParameters.add(_parameter('programAddress', address))
              ..lambda = true
              ..body = const Code('callback(programAddress)'),
          ),
        ),
    );
  }

  Parameter _thisParameter(String name) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = true
      ..toThis = true,
  );

  Parameter _namedParameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..named = true
      ..required = true,
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
      ..docs.add(docs),
  );
}
