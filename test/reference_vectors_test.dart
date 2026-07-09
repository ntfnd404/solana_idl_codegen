import 'dart:convert';
import 'dart:io';

import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:test/test.dart';

void main() {
  const generator = SolanaIdlGenerator();

  test(
    'committed Anchor instruction vectors match generated SDK bytes',
    () async {
      final manifest =
          jsonDecode(
                File(
                  'test/reference_vectors/provenance.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final vectors = (manifest['vectors']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(
        vectors.map((vector) => vector['version']),
        containsAll(<String>['legacy-pre-0.30', '0.30.1', '0.31.1', '1.0.2']),
      );

      for (final fixture in <(String, String, String)>[
        (
          'modern_alias.json',
          'ReferenceVectors',
          vectors.first['expectedHex']! as String,
        ),
        (
          'legacy_alias.json',
          'LegacyReferenceVectors',
          vectors.firstWhere(
                (vector) =>
                    vector['id'] == 'anchor-legacy-initialize-discriminator',
              )['expectedHex']!
              as String,
        ),
      ]) {
        final source = File(
          'test/reference_vectors/${fixture.$1}',
        ).readAsStringSync();
        final output = generator.generateString(
          source,
          options: const GenerationOptions(),
        );
        final directory = await Directory.systemTemp.createTemp(
          'solana_idl_vector_',
        );
        addTearDown(() => directory.delete(recursive: true));
        await File(
          '${directory.path}/generated.dart',
        ).writeAsString(output.files['program.dart']!);
        await File('${directory.path}/main.dart').writeAsString('''
import 'generated.dart';

void main() {
  final request = ${fixture.$2}InitializeRequest(
    args: ${fixture.$2}InitializeArgs(arg: <int>[1, 2, 3]),
    accounts: const ${fixture.$2}InitializeAccounts(),
  );
  final actual = request.instruction().data
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  if (actual != '${fixture.$3}') {
    throw StateError('Expected ${fixture.$3}, got \$actual.');
  }
}
''');
        final result = await Process.run(
          Platform.resolvedExecutable,
          ['run', '${directory.path}/main.dart'],
          environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
        );
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      }
    },
  );

  test('committed Anchor type vectors match generated Borsh codecs', () async {
    final source = File(
      'test/reference_vectors/modern_types.json',
    ).readAsStringSync();
    final output = generator.generateString(
      source,
      options: const GenerationOptions(),
    );
    final directory = await Directory.systemTemp.createTemp(
      'solana_idl_type_vector_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File(
      '${directory.path}/generated.dart',
    ).writeAsString(output.files['program.dart']!);
    await File('${directory.path}/main.dart').writeAsString(r'''
import 'generated.dart';

String hex(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  final mint = ReferenceTypesMintInfo(minted: true, metadataUrl: 'hello');
  final mintHex = hex(ReferenceTypesMintInfo.codec.encode(mint));
  const expectedMint = '010500000068656c6c6f';
  if (mintHex != expectedMint) {
    throw StateError('Expected $expectedMint, got $mintHex.');
  }

  final integers = ReferenceTypesIntegerTest(
    unsigned: BigInt.from(2588012355),
    signed: BigInt.from(-93842345),
  );
  final integerHex = hex(ReferenceTypesIntegerTest.codec.encode(integers));
  const expectedIntegers =
      '43ef419a00000000000000000000000000000000000000000000000000000000'
      '571468faffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
  if (integerHex != expectedIntegers) {
    throw StateError('Expected $expectedIntegers, got $integerHex.');
  }
}
''');
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', '${directory.path}/main.dart'],
      environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test(
    'account, event, COption, PDA, error, and malformed vectors match',
    () async {
      final source = File(
        'test/reference_vectors/runtime_matrix.json',
      ).readAsStringSync();
      final output = generator.generateString(
        source,
        options: const GenerationOptions(),
      );
      final directory = await Directory.systemTemp.createTemp(
        'solana_idl_runtime_vector_',
      );
      addTearDown(() => directory.delete(recursive: true));
      await File(
        '${directory.path}/generated.dart',
      ).writeAsString(output.files['program.dart']!);
      await File('${directory.path}/main.dart').writeAsString(r'''
import 'dart:convert';

import 'generated.dart';

String hex(List<int> value) =>
    value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

final class TestSubscription implements ReferenceRuntimeEventSubscription {
  TestSubscription(this.batches);

  @override
  final Stream<ReferenceRuntimeLogBatch> batches;

  var closeCount = 0;

  @override
  Future<void> close() async {
    closeCount++;
  }
}

Future<void> main() async {
  final authority = ReferenceRuntimeAddress.fromBytes(List<int>.filled(32, 0));
  final none = ReferenceRuntimeState(
    name: 'test',
    authority: authority,
    native: null,
  );
  const expectedNone =
      '0400000074657374'
      '0000000000000000000000000000000000000000000000000000000000000000'
      '000000000000000000000000';
  if (hex(ReferenceRuntimeState.codec.encode(none)) != expectedNone) {
    throw StateError('COption None does not preserve its fixed payload span.');
  }

  final some = ReferenceRuntimeState(
    name: 'test',
    authority: authority,
    native: BigInt.from(7),
  );
  const expectedSome =
      '0400000074657374'
      '0000000000000000000000000000000000000000000000000000000000000000'
      '010000000700000000000000';
  final someBytes = ReferenceRuntimeState.codec.encode(some);
  if (hex(someBytes) != expectedSome) {
    throw StateError('COption Some bytes differ from the SPL layout.');
  }

  final accountBytes = <int>[
    ...ReferenceRuntimeStateAccount.discriminator,
    ...someBytes,
    0,
    0,
  ];
  final decoded = ReferenceRuntimeStateAccount.decodeAccount(accountBytes);
  if (decoded != some) throw StateError('Account decode failed.');
  try {
    ReferenceRuntimeStateAccount.decodeAccountExact(accountBytes);
    throw StateError('Exact account decoder accepted trailing bytes.');
  } on ReferenceRuntimeBorshException catch (error) {
    if (error.code != 'BORSH_TRAILING_BYTES') rethrow;
  }
  try {
    ReferenceRuntimeStateAccount.decodeAccount([
      99,
      ...accountBytes.skip(1),
    ]);
    throw StateError('Account discriminator mismatch was accepted.');
  } on FormatException {
    // Expected.
  }

  final malformedCOption = <int>[
    4,
    0,
    0,
    0,
    116,
    101,
    115,
    116,
    ...List<int>.filled(32, 0),
    2,
    0,
    0,
    0,
    ...List<int>.filled(8, 0),
  ];
  try {
    ReferenceRuntimeState.codec.decodeExact(malformedCOption);
    throw StateError('Invalid COption tag was accepted.');
  } on ReferenceRuntimeBorshException catch (error) {
    if (error.code != 'BORSH_INVALID_OPTION') rethrow;
  }

  final capturedSeeds = <List<int>>[];
  final resolver = ReferenceRuntimeDeriveAccountResolver(
    ReferenceRuntimeResolutionContext(
      pdaDeriver: ReferenceRuntimePdaDeriverCallback(
        (programAddress, seeds) async {
          capturedSeeds
            ..clear()
            ..addAll(seeds.map(List<int>.from));
          return ReferenceRuntimePdaResult(
            address: authority,
            bump: 255,
          );
        },
      ),
    ),
  );
  await resolver.resolve(
    args: ReferenceRuntimeDeriveArgs(id: BigInt.from(7)),
  );
  if (hex(capturedSeeds[0]) != '7374617465' ||
      hex(capturedSeeds[1]) != '0700000000000000') {
    throw StateError('Typed PDA seed bytes differ from Anchor semantics.');
  }

  final eventPayload = <int>[
    ...ReferenceRuntimeChangedEvent.discriminator,
    42,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    3,
    0,
    0,
    0,
    101,
    118,
    116,
  ];
  final raw = TestSubscription(
    Stream.value(
      ReferenceRuntimeLogBatch(
        programAddress: ReferenceRuntimeProgram.programAddress,
        signature: 'signature',
        slot: BigInt.from(9),
        failure: null,
        logs: [
          'Program ${ReferenceRuntimeProgram.address} invoke [1]',
          'Program data: ${base64Encode(eventPayload)}',
          'Program ${ReferenceRuntimeProgram.address} success',
        ],
      ),
    ),
  );
  final events = ReferenceRuntimeEventsClient(
    ReferenceRuntimeEventSubscriberCallback((_) async => raw),
  );
  final subscription = await events.subscribe();
  final notification = await subscription.notifications.first;
  if (notification
      case ReferenceRuntimeDecodedEventNotification(
        event: ReferenceRuntimeChangedEvent(
          value: ReferenceRuntimeChanged(id: final id, label: final label),
        ),
        context: ReferenceRuntimeEventContext(slot: final slot),
      )
      when id == BigInt.from(42) && label == 'evt' && slot == BigInt.from(9)) {
    // Expected.
  } else {
    throw StateError('Typed event decode failed.');
  }
  await subscription.close();
  await subscription.close();
  if (raw.closeCount != 1) throw StateError('Event close is not idempotent.');

  final malformedRaw = TestSubscription(
    Stream.value(
      ReferenceRuntimeLogBatch(
        programAddress: ReferenceRuntimeProgram.programAddress,
        signature: 'signature',
        slot: BigInt.zero,
        failure: null,
        logs: [
          'Program ${ReferenceRuntimeProgram.address} invoke [1]',
          'Program data: %%%',
        ],
      ),
    ),
  );
  final malformedEvents = ReferenceRuntimeEventsClient(
    ReferenceRuntimeEventSubscriberCallback((_) async => malformedRaw),
  );
  final malformedSubscription = await malformedEvents.subscribe();
  final diagnostic = await malformedSubscription.notifications.first;
  if (diagnostic
      case ReferenceRuntimeEventDiagnosticNotification(code: final code)
      when code == 'EVENT_BASE64') {
    // Expected.
  } else {
    throw StateError('Malformed event did not produce a diagnostic.');
  }

  final error = ReferenceRuntimeProgramErrorParser.parseLogs([
    'Program log: AnchorError caused by account: state. '
        'Error Code: BadState. Error Number: 6000. Error Message: Bad state.',
  ]);
  if (error is! ReferenceRuntimeBadStateException ||
      error.origin is! ReferenceRuntimeAccountErrorOrigin ||
      error.rawLogs.length != 1) {
    throw StateError('Typed Anchor error parsing failed.');
  }
}
''');
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', '${directory.path}/main.dart'],
        environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}
