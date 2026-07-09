import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits tri-state account override declarations.
final class OverrideSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const OverrideSupportFragment(super.context);

  @override
  List<Spec> emit() {
    final address = type('address');
    final override = type('account_override');
    return <Spec>[
      _overrideBase(override, address),
      _emptyOverride(
        type('inherit_account_override'),
        override,
        'IDL-driven resolution without an explicit override.',
        'Creates the inherit state.',
      ),
      _useOverride(type('use_account_override'), override, address),
      _emptyOverride(
        type('absent_account_override'),
        override,
        'Explicit absence for an IDL-optional account.',
        'Creates the absent state.',
      ),
    ];
  }

  Class _overrideBase(String name, String address) => Class(
    (builder) => builder
      ..name = name
      ..sealed = true
      ..docs.add('/// Tri-state override for one instruction account.')
      ..constructors.addAll([
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates an override state.'),
        ),
        _redirectingFactory(
          'inherit',
          type('inherit_account_override'),
          'Uses IDL-driven resolution.',
        ),
        _redirectingFactory(
          'use',
          type('use_account_override'),
          'Uses an explicit address.',
          parameter: _parameter('address', address),
        ),
        _redirectingFactory(
          'absent',
          type('absent_account_override'),
          'Omits an IDL-optional account using the program sentinel.',
        ),
      ]),
  );

  Constructor _redirectingFactory(
    String name,
    String redirect,
    String docs, {
    Parameter? parameter,
  }) => Constructor((builder) {
    builder
      ..name = name
      ..constant = true
      ..factory = true
      ..redirect = refer(redirect)
      ..docs.add('/// $docs');
    if (parameter != null) builder.requiredParameters.add(parameter);
  });

  Class _emptyOverride(
    String name,
    String base,
    String docs,
    String constructorDocs,
  ) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..extend = refer(base)
      ..docs.add('/// $docs')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// $constructorDocs'),
        ),
      ),
  );

  Class _useOverride(String name, String base, String address) => Class(
    (builder) => builder
      ..name = name
      ..modifier = ClassModifier.final$
      ..extend = refer(base)
      ..docs.add('/// Explicit account address override.')
      ..constructors.add(
        Constructor(
          (builder) => builder
            ..constant = true
            ..docs.add('/// Creates an explicit address state.')
            ..requiredParameters.add(
              Parameter(
                (builder) => builder
                  ..name = 'address'
                  ..toThis = true,
              ),
            ),
        ),
      )
      ..fields.add(_field('address', address, 'Explicit address.')),
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
