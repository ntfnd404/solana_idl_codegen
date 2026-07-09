import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits PDA exception, result, deriver port, and callback adapter.
final class PdaDerivationSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const PdaDerivationSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final deriver = type('pda_deriver');
    final pda = type('pda_result');
    return <Spec>[
      _pdaException(),
      _pdaResult(pda, address),
      _pdaDeriver(deriver, pda, address),
      _pdaDeriverCallback(deriver, pda, address),
    ];
  }

  Class _pdaException() {
    final name = type('pda_exception');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer('Exception'))
        ..docs.add('/// Typed PDA seed or derivation failure.')
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..constant = true
              ..docs.add('/// Creates a PDA failure.')
              ..optionalParameters.addAll([
                _thisParameter('code'),
                _thisParameter('message'),
                _thisParameter('seedIndex', required: false),
              ]),
          ),
        )
        ..fields.addAll([
          _field('code', 'String', '/// Stable failure code.'),
          _field('message', 'String', '/// Human-readable explanation.'),
          _field('seedIndex', 'int?', '/// Optional failing seed index.'),
        ])
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'toString'
              ..returns = refer('String')
              ..annotations.add(refer('override'))
              ..lambda = true
              ..body = Code("'$name(\$code: \$message)'"),
          ),
        ),
    );
  }

  Class _pdaResult(String name, String address) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..docs.add('/// Immutable program-derived address and canonical bump.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..docs.add('/// Creates a PDA result.')
            ..optionalParameters.addAll([
              _thisParameter('address'),
              _thisParameter('bump'),
            ])
            ..body = const Code('''
if (bump < 0 || bump > 255) {
  throw RangeError.range(bump, 0, 255, 'bump');
}'''),
        ),
      )
      ..fields.addAll([
        _field('address', address, '/// Derived address.'),
        _field('bump', 'int', '/// Canonical bump in the range 0–255.'),
      ]),
  );

  Class _pdaDeriver(String name, String pda, String address) => Class(
    (builder) => builder
      ..name = name
      ..abstract = true
      ..modifier = ClassModifier.interface
      ..docs.add(
        '/// Port used for canonical program-derived-address calculation.',
      )
      ..methods.add(
        Method(
          (builder) => builder
            ..name = 'derive'
            ..returns = refer('Future<$pda>')
            ..docs.add('/// Derives an address from at most 15 IDL [seeds].')
            ..optionalParameters.addAll([
              _namedParameter('programAddress', address),
              _namedParameter('seeds', 'List<Uint8List>'),
            ]),
        ),
      ),
  );

  Class _pdaDeriverCallback(String deriver, String pda, String address) {
    final name = type('pda_deriver_callback');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..implements.add(refer(deriver))
        ..docs.add('/// Callback adapter for [$deriver].')
        ..constructors.add(_callbackConstructor())
        ..fields.add(
          _field(
            'callback',
            'Future<$pda> Function($address, List<Uint8List>)',
            '/// Derivation callback.',
          ),
        )
        ..methods.add(
          Method(
            (builder) => builder
              ..name = 'derive'
              ..returns = refer('Future<$pda>')
              ..annotations.add(refer('override'))
              ..optionalParameters.addAll([
                _namedParameter('programAddress', address),
                _namedParameter('seeds', 'List<Uint8List>'),
              ])
              ..lambda = true
              ..body = const Code('''
callback(
  programAddress,
  List.unmodifiable(
    seeds.map((seed) => Uint8List.fromList(seed).asUnmodifiableView()),
  ),
)'''),
          ),
        ),
    );
  }

  Constructor _callbackConstructor() => Constructor(
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
  );

  Parameter _thisParameter(String name, {bool required = true}) => Parameter(
    (builder) => builder
      ..name = name
      ..named = true
      ..required = required
      ..toThis = true,
  );

  Parameter _namedParameter(String name, String type) => Parameter(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..named = true
      ..required = true,
  );

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add(docs),
  );
}
