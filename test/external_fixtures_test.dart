import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:test/test.dart';

void main() {
  const generator = SolanaIdlGenerator();

  group('external IDL fixture provenance', () {
    final provenance = _loadProvenance();

    test('documents every committed external fixture', () {
      final fixtures = _fixtures(provenance);
      expect(fixtures, isNotEmpty);

      final documentedFiles = fixtures
          .map((fixture) => fixture['file'] as String)
          .toSet();
      final committedFiles = Directory('test/fixtures/external')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name != 'provenance.json')
          .toSet();

      expect(documentedFiles, committedFiles);
    });

    test('contains required source, license, purpose, mode, and checksum', () {
      for (final fixture in _fixtures(provenance)) {
        for (final key in [
          'id',
          'file',
          'mode',
          'sourceUrl',
          'rawSourceUrl',
          'commit',
          'producer',
          'licenseNote',
          'sourceSha256',
          'purpose',
        ]) {
          expect(
            fixture[key],
            isA<String>().having((value) => value.isNotEmpty, key, isTrue),
            reason: 'Missing $key in ${fixture['id']}',
          );
        }

        final bytes = File(
          'test/fixtures/external/${fixture['file']}',
        ).readAsBytesSync();
        expect(
          sha256.convert(bytes).toString(),
          fixture['sourceSha256'],
          reason: 'Checksum drift in ${fixture['id']}',
        );
      }
    });

    test('keeps current skipped candidates tied to exact diagnostics', () {
      for (final fixture in _fixtures(provenance)) {
        if (fixture['mode'] != 'skipped-generation-candidate') continue;

        final source = File(
          'test/fixtures/external/${fixture['file']}',
        ).readAsStringSync();
        final withAddress = _injectAddress(
          source,
          fixture['testAddress'] as String,
        );
        final result = generator.validateString(
          withAddress,
          sourceName: fixture['file'] as String,
        );

        expect(result.isValid, isFalse, reason: fixture['id'] as String);
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.code),
          contains(fixture['expectedDiagnostic']),
          reason: fixture['skipReason'] as String,
        );
      }
    });

    test(
      'generates passing external fixtures in both layouts',
      () {
        for (final fixture in _fixtures(provenance)) {
          if (fixture['mode'] != 'generation-only-with-test-address') continue;

          final source = File(
            'test/fixtures/external/${fixture['file']}',
          ).readAsStringSync();
          final withAddress = _injectAddress(
            source,
            fixture['testAddress'] as String,
          );
          final validation = generator.validateString(
            withAddress,
            sourceName: fixture['file'] as String,
          );
          expect(
            validation.isValid,
            isTrue,
            reason: '${fixture['id']}\n${validation.diagnostics.join('\n')}',
          );

          for (final layout in OutputLayout.values) {
            final output = generator.generateString(
              withAddress,
              options: GenerationOptions(layout: layout),
              sourceName: fixture['file'] as String,
            );
            expect(output.files, isNotEmpty, reason: fixture['id'] as String);
            for (final source in output.files.values) {
              _expectGeneratedSourceIsTransportNeutral(source);
            }
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'generated external fixtures are analyzer-clean in both layouts',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'solana_idl_external_analyzer_',
        );
        addTearDown(() => root.delete(recursive: true));
        await File('${root.path}/pubspec.yaml').writeAsString('''
name: external_analyzer_matrix
publish_to: none

environment:
  sdk: ^3.12.2
''');
        await File('${root.path}/analysis_options.yaml').writeAsString('''
linter:
  rules:
    curly_braces_in_flow_control_structures: true
    prefer_initializing_formals: true
    type_init_formals: true
    use_super_parameters: true
''');
        final lib = Directory('${root.path}/lib');
        await lib.create();

        for (final fixture in _fixtures(provenance)) {
          if (fixture['mode'] != 'generation-only-with-test-address') continue;
          final source = File(
            'test/fixtures/external/${fixture['file']}',
          ).readAsStringSync();
          final withAddress = _injectAddress(
            source,
            fixture['testAddress'] as String,
          );
          final fixtureStem = _dartStem(fixture['id'] as String);
          for (final layout in OutputLayout.values) {
            final output = generator.generateString(
              withAddress,
              options: GenerationOptions(layout: layout),
              sourceName: fixture['file'] as String,
            );
            final programStem = '${fixtureStem}_${layout.name}';
            for (final entry in output.files.entries) {
              final suffix = entry.key == 'program.dart'
                  ? ''
                  : '_${entry.key.substring(0, entry.key.length - 5)}';
              final generated = entry.value.replaceAll(
                '__PROGRAM_STEM__',
                programStem,
              );
              await File(
                '${lib.path}/${programStem}_solana$suffix.dart',
              ).writeAsString(generated);
            }
          }
        }

        await _runDart(root, ['pub', 'get']);
        await _runDart(root, [
          'analyze',
          '--fatal-warnings',
          '--fatal-infos',
          '.',
        ]);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

String _dartStem(String value) => value
    .replaceAll(RegExp('[^A-Za-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '')
    .toLowerCase();

Future<void> _runDart(Directory root, List<String> arguments) async {
  final result = await Process.run(
    Platform.resolvedExecutable,
    arguments,
    workingDirectory: root.path,
    environment: {'HOME': root.path, 'DART_DISABLE_ANALYTICS': '1'},
  );
  expect(
    result.exitCode,
    0,
    reason: [
      'dart ${arguments.join(' ')} failed in ${root.path}',
      result.stdout,
      result.stderr,
    ].join('\n'),
  );
}

Map<String, Object?> _loadProvenance() {
  final raw = File('test/fixtures/external/provenance.json').readAsStringSync();
  return jsonDecode(raw) as Map<String, Object?>;
}

List<Map<String, Object?>> _fixtures(Map<String, Object?> provenance) =>
    (provenance['fixtures'] as List<Object?>)
        .map(
          (fixture) =>
              Map<String, Object?>.from(fixture! as Map<Object?, Object?>),
        )
        .toList(growable: false);

String _injectAddress(String source, String address) {
  final json = jsonDecode(source) as Map<String, Object?>;
  final withAddress = <String, Object?>{'address': address, ...json};
  return jsonEncode(withAddress);
}

void _expectGeneratedSourceIsTransportNeutral(String source) {
  expect(source, isNot(contains("import 'package:")));
  expect(source, isNot(contains("import 'dart:io'")));
  expect(source, isNot(contains(RegExp(r'\bdynamic\b'))));
}
