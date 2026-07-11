import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:solana_idl_codegen/builder.dart';
import 'package:test/test.dart';

const _idl = '''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "sample", "version": "1", "spec": "0.1.0"},
  "instructions": []
}
''';

void main() {
  test('package exposes only the bundled and modular builder keys', () {
    final config = File('build.yaml').readAsStringSync();
    expect(config, contains('  bundled:'));
    expect(config, contains('  modular:'));
    expect(config, isNot(contains('  solana_idl:')));
    expect(config, isNot(contains('  solana_idl_modular:')));
  });

  test('builder keys expose static non-overlapping output graphs', () {
    final bundled = solanaIdlBundledBuilder(BuilderOptions.empty);
    final modular = solanaIdlModularBuilder(BuilderOptions.empty);
    expect(bundled.buildExtensions.values.single, hasLength(1));
    expect(modular.buildExtensions.values.single, hasLength(9));
  });

  test('bundled builder emits one self-contained SDK', () async {
    await testBuilder(
      solanaIdlBundledBuilder(BuilderOptions.empty),
      {'app|lib/idl/sample.json': _idl},
      rootPackage: 'app',
      outputs: {
        'app|lib/generated/sample_solana.dart': decodedMatches(
          allOf(
            contains('// tool: solana_idl_codegen'),
            contains('class SampleAddress'),
            isNot(contains('package:solana')),
          ),
        ),
      },
    );
  });

  test('modular builder emits all nine neighboring libraries', () async {
    await testBuilder(
      solanaIdlModularBuilder(const BuilderOptions({'type_prefix': 'Api'})),
      {'app|lib/idl/nested/sample.json': _idl},
      rootPackage: 'app',
      outputs: {
        'app|lib/generated/nested/sample_solana.dart': decodedMatches(
          contains("export 'sample_solana_support.dart';"),
        ),
        'app|lib/generated/nested/sample_solana_support.dart': decodedMatches(
          contains('class ApiAddress'),
        ),
        'app|lib/generated/nested/sample_solana_types.dart': anything,
        'app|lib/generated/nested/sample_solana_accounts.dart': anything,
        'app|lib/generated/nested/sample_solana_instructions.dart': anything,
        'app|lib/generated/nested/sample_solana_resolution.dart': anything,
        'app|lib/generated/nested/sample_solana_events.dart': anything,
        'app|lib/generated/nested/sample_solana_errors.dart': anything,
        'app|lib/generated/nested/sample_solana_client.dart': anything,
      },
    );
  });
}
