import 'dart:convert';
import 'dart:io';

import 'package:solana_idl_codegen/src/cli.dart';
import 'package:solana_idl_codegen/src/cli/output_transaction.dart';
import 'package:solana_idl_codegen/src/cli/output_transaction_observer.dart';
import 'package:test/test.dart';

void main() {
  test('CLI batch generation, check drift, and marker-safe clean', () async {
    final directory = await Directory.systemTemp.createTemp('idl_cli_');
    addTearDown(() => directory.delete(recursive: true));
    final inputs = Directory('${directory.path}/idl')..createSync();
    final output = Directory('${directory.path}/generated');
    File('${inputs.path}/program.json').writeAsStringSync('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "cli_program", "version": "1", "spec": "0.1.0"},
  "instructions": []
}
''');
    final foreign = File('${output.path}/foreign.dart');
    output.createSync();
    foreign.writeAsStringSync('// handwritten\n');
    final legacy = File('${output.path}/program.solana.types.dart')
      ..writeAsStringSync(
        '// GENERATED CODE - DO NOT MODIFY BY HAND.\n'
        '// tool: solana_idl_codegen\n',
      );
    final log = File('${directory.path}/log').openWrite();
    final arguments = [
      'generate',
      '${inputs.path}/program.json',
      '--input-root',
      inputs.path,
      '--output',
      output.path,
      '--layout',
      'modular',
    ];
    expect(await runCli(arguments, stdoutSink: log, stderrSink: log), 0);
    expect(await legacy.exists(), isFalse);
    expect(
      await runCli([...arguments, '--check'], stdoutSink: log, stderrSink: log),
      0,
    );
    final generated = File('${output.path}/program_solana_types.dart');
    await generated.writeAsString('// drift\n');
    expect(
      await runCli([...arguments, '--check'], stdoutSink: log, stderrSink: log),
      3,
    );
    expect(
      await runCli(
        ['clean', '--output', output.path],
        stdoutSink: log,
        stderrSink: log,
      ),
      0,
    );
    expect(await foreign.exists(), isTrue);
    await log.close();
  });

  test(
    'generating one IDL preserves other SDKs and scopes stale layout',
    () async {
      final directory = await Directory.systemTemp.createTemp('idl_cli_scope_');
      addTearDown(() => directory.delete(recursive: true));
      final inputs = Directory('${directory.path}/idl')..createSync();
      final output = Directory('${directory.path}/generated');
      for (final name in ['first', 'second']) {
        File('${inputs.path}/$name.json').writeAsStringSync('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "${name}_program", "version": "1", "spec": "0.1.0"},
  "instructions": []
}
''');
      }
      final log = File('${directory.path}/log').openWrite();
      List<String> generate(String name, String layout) => [
        'generate',
        '${inputs.path}/$name.json',
        '--input-root',
        inputs.path,
        '--output',
        output.path,
        '--layout',
        layout,
      ];

      expect(await runCli(generate('first', 'modular'), stdoutSink: log), 0);
      expect(await runCli(generate('second', 'modular'), stdoutSink: log), 0);
      final secondTypes = File('${output.path}/second_solana_types.dart');
      expect(await secondTypes.exists(), isTrue);

      expect(await runCli(generate('first', 'bundled'), stdoutSink: log), 0);
      expect(await secondTypes.exists(), isTrue);
      expect(
        await File('${output.path}/first_solana_types.dart').exists(),
        isFalse,
      );
      expect(await File('${output.path}/first_solana.dart').exists(), isTrue);
      await log.close();
    },
  );

  test('filesystem input failures use exit code one', () async {
    final directory = await Directory.systemTemp.createTemp('idl_cli_io_');
    addTearDown(() => directory.delete(recursive: true));
    final log = File('${directory.path}/log').openWrite();
    expect(
      await runCli(
        ['validate', '${directory.path}/missing.json'],
        stdoutSink: log,
        stderrSink: log,
      ),
      1,
    );
    await log.close();
  });

  test('transaction recovery restores pre-commit output', () async {
    final directory = await Directory.systemTemp.createTemp(
      'idl_cli_recovery_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final canonical = await directory.resolveSymbolicLinks();
    const token = '123_456';
    final target = File('$canonical/program_solana.dart');
    final backup = File('${target.path}.solana-idl-backup-$token');
    const original = '// tool: solana_idl_codegen\n// original\n';
    await target.writeAsString(original);
    await target.rename(backup.path);
    await target.writeAsString(
      '// tool: solana_idl_codegen\n// interrupted replacement\n',
    );
    final manifest = File('$canonical/.solana_idl_codegen.recovery.json');
    await manifest.writeAsString(
      jsonEncode({
        'version': 1,
        'token': token,
        'phase': 'installed',
        'entries': [
          {
            'target': target.path,
            'staged': '${target.path}.solana-idl-stage-$token',
            'backup': backup.path,
            'install': true,
            'hadOriginal': true,
          },
        ],
      }),
    );

    await const OutputTransactionWriter().recover(directory);

    expect(await target.readAsString(), original);
    expect(await backup.exists(), isFalse);
    expect(await manifest.exists(), isFalse);
  });

  test(
    'invalid recovery manifest is preserved and returns exit code four',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'idl_cli_bad_recovery_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final output = Directory('${directory.path}/generated')..createSync();
      final manifest = File('${output.path}/.solana_idl_codegen.recovery.json')
        ..writeAsStringSync(
          jsonEncode({
            'version': 1,
            'token': '123_456',
            'phase': 'installed',
            'entries': [
              {
                'target': '${directory.parent.path}/outside_solana.dart',
                'staged': null,
                'backup': '${directory.parent.path}/outside.backup',
                'install': false,
                'hadOriginal': true,
              },
            ],
          }),
        );
      final log = File('${directory.path}/log').openWrite();

      expect(
        await runCli(
          ['clean', '--output', output.path],
          stdoutSink: log,
          stderrSink: log,
        ),
        4,
      );
      expect(await manifest.exists(), isTrue);
      await log.close();
    },
  );

  for (final phase in OutputTransactionPhase.values) {
    test('recovers deterministic interruption after ${phase.name}', () async {
      final directory = await Directory.systemTemp.createTemp('idl_cli_phase_');
      addTearDown(() => directory.delete(recursive: true));
      final canonical = await directory.resolveSymbolicLinks();
      final existing = File('$canonical/existing_solana.dart');
      final added = File('$canonical/added_solana.dart');
      const original = '// tool: solana_idl_codegen\n// original\n';
      const replacement = '// tool: solana_idl_codegen\n// replacement\n';
      await existing.writeAsString(original);

      await expectLater(
        OutputTransactionWriter(observer: _InterruptAt(phase)).write(
          directory,
          {existing.path: replacement, added.path: replacement},
          const [],
        ),
        throwsA(isA<OutputTransactionInterruption>()),
      );
      await const OutputTransactionWriter().recover(directory);

      if (phase == OutputTransactionPhase.committed) {
        expect(await existing.readAsString(), replacement);
        expect(await added.readAsString(), replacement);
      } else {
        expect(await existing.readAsString(), original);
        expect(await added.exists(), isFalse);
      }
      final artifacts = await directory
          .list()
          .where(
            (entity) =>
                entity.path.contains('.solana-idl-stage-') ||
                entity.path.contains('.solana-idl-backup-') ||
                entity.path.endsWith('.solana_idl_codegen.recovery.json'),
          )
          .toList();
      expect(artifacts, isEmpty);
    });
  }

  test('real path and symlink alias share one canonical lock', () async {
    if (Platform.isWindows) return;
    final parent = await Directory.systemTemp.createTemp('idl_cli_lock_');
    addTearDown(() => parent.delete(recursive: true));
    final output = Directory('${parent.path}/output')..createSync();
    final alias = Link('${parent.path}/alias')..createSync(output.path);
    final canonical = await output.resolveSymbolicLinks();
    final firstReached = File('${parent.path}/first-reached');
    final secondReached = File('${parent.path}/second-reached');
    final release = File('${parent.path}/release');
    final first = await Process.start(Platform.resolvedExecutable, [
      'run',
      'test/helpers/lock_writer.dart',
      output.path,
      '$canonical/first_solana.dart',
      firstReached.path,
      release.path,
    ], workingDirectory: Directory.current.path);
    while (!await firstReached.exists()) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final second = await Process.start(Platform.resolvedExecutable, [
      'run',
      'test/helpers/lock_writer.dart',
      alias.path,
      '$canonical/second_solana.dart',
      secondReached.path,
      '-',
    ], workingDirectory: Directory.current.path);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(await secondReached.exists(), isFalse);

    await release.writeAsString('release', flush: true);
    expect(await first.exitCode, 0);
    expect(await second.exitCode, 0);
    expect(await secondReached.exists(), isTrue);
  });
}

final class _InterruptAt implements OutputTransactionObserver {
  const _InterruptAt(this.target);

  final OutputTransactionPhase target;

  @override
  Future<void> reached(OutputTransactionPhase phase, {int? entryIndex}) async {
    if (phase == target &&
        (phase != OutputTransactionPhase.partialInstall || entryIndex == 0)) {
      throw OutputTransactionInterruption(phase);
    }
  }
}
