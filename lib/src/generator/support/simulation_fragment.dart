import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits transaction-simulation support value objects and ports.
final class SimulationSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const SimulationSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final instruction = type('instruction');
    final failure = type('transaction_failure');
    final simulator = type('transaction_simulator');
    final simulation = type('simulation_result');
    return <Spec>[
      _simulation(simulation, address, failure),
      _simulator(simulator, simulation, instruction),
      _simulatorCallback(simulator, simulation, instruction),
    ];
  }

  Class _simulation(String name, String address, String failure) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Immutable result of simulating one instruction.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add(
              '/// Creates a simulation result and copies byte/log collections.',
            )
            ..optionalParameters.addAll([
              _thisParameter('failure'),
              _namedParameter('logs', 'List<String>'),
              _thisParameter('returnProgramAddress'),
              _namedParameter('returnData', 'List<int>?'),
              _thisParameter('unitsConsumed'),
              _thisParameter('slot'),
            ])
            ..initializers.addAll([
              const Code('logs = List.unmodifiable(logs)'),
              const Code(
                'returnData = returnData == null '
                '? null '
                ': Uint8List.fromList(returnData).asUnmodifiableView()',
              ),
            ]),
        ),
      )
      ..fields.addAll([
        _field('failure', '$failure?', '/// Optional transaction failure.'),
        _field('logs', 'List<String>', '/// Ordered logs.'),
        _field(
          'returnProgramAddress',
          '$address?',
          '/// Program that supplied return data.',
        ),
        _field('returnData', 'Uint8List?', '/// Immutable return bytes.'),
        _field(
          'unitsConsumed',
          'BigInt?',
          '/// Optional compute units consumed.',
        ),
        _field('slot', 'BigInt', '/// Context slot.'),
      ]),
  );

  Class _simulator(String name, String simulation, String instruction) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add('/// Port used by generated view clients.')
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'simulate'
            ..returns = refer('Future<$simulation>')
            ..docs.add('/// Simulates exactly one [instruction].')
            ..requiredParameters.add(_parameter('instruction', instruction)),
        ),
      ),
  );

  Class _simulatorCallback(
    String simulator,
    String simulation,
    String instruction,
  ) {
    final name = type('transaction_simulator_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(simulator))
        ..docs.add('/// Callback adapter for [$simulator].')
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
            'Future<$simulation> Function($instruction)',
            '/// Simulation callback.',
          ),
        )
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'simulate'
              ..returns = refer('Future<$simulation>')
              ..annotations.add(refer('override'))
              ..requiredParameters.add(_parameter('instruction', instruction))
              ..lambda = true
              ..body = const Code('callback(instruction)'),
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
