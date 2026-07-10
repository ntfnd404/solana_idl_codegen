import 'package:code_builder/code_builder.dart';

import '../section_emitter.dart';

/// Emits the generated account-resolution dependency context.
final class ContextSupportFragment extends SectionEmitter {
  /// Creates this fragment for [context].
  const ContextSupportFragment(super.context);

  @override
  List<Spec> emit() => <Spec>[_context(type('resolution_context'))];

  Class _context(String name) {
    final address = type('address');
    final readOptions = type('account_read_options');
    final decodeLimits = type('decode_limits');
    return Class(
      (builder) => builder
        ..name = name
        ..modifier = ClassModifier.final$
        ..docs.add('/// Dependencies supplied to generated account resolvers.')
        ..docs.add(
          '/// Relation/PDA cycles are runtime-resolvable when these dependencies break the cycle.',
        )
        ..constructors.add(
          Constructor(
            (builder) => builder
              ..docs.add('/// Creates a resolution context.')
              ..optionalParameters.addAll([
                _thisOptional('identity'),
                Parameter(
                  (builder) => builder
                    ..name = 'identityAccountPaths'
                    ..type = refer('Set<String>')
                    ..named = true
                    ..defaultTo = const Code('const {}'),
                ),
                _thisOptional('accountReader'),
                _thisOptional('externalAccountSeedResolver'),
                _thisOptional('relationResolver'),
                _thisOptional('pdaDeriver'),
                _thisOptional('readOptions', defaultTo: 'const $readOptions()'),
                _thisOptional(
                  'decodeLimits',
                  defaultTo: '$decodeLimits.defaults',
                ),
              ])
              ..initializers.add(
                const Code(
                  'identityAccountPaths = '
                  'Set.unmodifiable(identityAccountPaths)',
                ),
              ),
          ),
        )
        ..fields.addAll([
          _field('identity', '$address?', 'Optional application identity.'),
          _field(
            'identityAccountPaths',
            'Set<String>',
            'Account paths allowed to use [identity].',
          ),
          _field(
            'accountReader',
            '${type('account_reader')}?',
            'Optional account reader used by relation and account-data seeds.',
          ),
          _field(
            'externalAccountSeedResolver',
            '${type('external_account_seed_resolver')}?',
            'Optional decoder for application-owned external account seeds.',
          ),
          _field(
            'relationResolver',
            '${type('relation_resolver')}?',
            'Optional application relation resolver.',
          ),
          _field(
            'pdaDeriver',
            '${type('pda_deriver')}?',
            'Optional canonical PDA deriver.',
          ),
          _field('readOptions', readOptions, 'Account read policy.'),
          _field('decodeLimits', decodeLimits, 'Decode limits.'),
        ]),
    );
  }

  Parameter _thisOptional(String name, {String? defaultTo}) =>
      Parameter((builder) {
        builder
          ..name = name
          ..named = true
          ..toThis = true;
        if (defaultTo != null) builder.defaultTo = Code(defaultTo);
      });

  Field _field(String name, String type, String docs) => Field(
    (builder) => builder
      ..name = name
      ..type = refer(type)
      ..modifier = FieldModifier.final$
      ..docs.add('/// $docs'),
  );
}
