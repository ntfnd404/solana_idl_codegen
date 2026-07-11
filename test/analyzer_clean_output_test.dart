import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:test/test.dart';

void main() {
  const generator = SolanaIdlGenerator();
  final fixture = File('test/fixtures/analyzer_clean.json').readAsStringSync();

  test('generic nullable and resolver fixture is analyzer-clean', () async {
    for (final layout in OutputLayout.values) {
      final root = await Directory.systemTemp.createTemp(
        'solana_idl_analyzer_matrix_',
      );
      addTearDown(() => root.delete(recursive: true));
      await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: analyzer_matrix_${layout.name}
publish_to: none

environment:
  sdk: ^3.12.2
''');
      final generated = generator.generateString(
        fixture,
        options: GenerationOptions(layout: layout),
      );
      final sources = await _writeGenerated(root, generated, layout);

      for (final source in sources) {
        expect(source, isNot(contains('PDA_SOURCE_UNRESOLVED')));
        expect(
          source,
          isNot(contains(RegExp(r"if \((\w+) != null\) '[^']+': \1!"))),
        );
        expect(source, isNot(contains(RegExp(r'(\w+) == null \? null : \1!'))));
      }

      await _runDart(root, ['pub', 'get']);
      await _runDart(root, [
        'analyze',
        '--fatal-warnings',
        '--fatal-infos',
        '.',
      ]);
    }
  });

  test(
    'nullable values and account-data PDA resolution keep semantics',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'solana_idl_analyzer_runtime_',
      );
      addTearDown(() => root.delete(recursive: true));
      final generated = generator.generateString(
        fixture,
        options: const GenerationOptions(),
      );
      await File(
        p.join(root.path, 'generated.dart'),
      ).writeAsString(generated.files['program.dart']!);
      await File(p.join(root.path, 'main.dart')).writeAsString(_runtimeProgram);

      await _runDart(root, ['run', 'main.dart']);
    },
  );
}

Future<List<String>> _writeGenerated(
  Directory root,
  GenerationOutput output,
  OutputLayout layout,
) async {
  final lib = Directory(p.join(root.path, 'lib'));
  await lib.create();
  if (layout == OutputLayout.bundled) {
    final source = output.files['program.dart']!;
    await File(
      p.join(lib.path, 'analyzer_matrix_solana.dart'),
    ).writeAsString(source);
    return [source];
  }

  const suffixes = {
    'program.dart': '',
    'support.dart': '_support',
    'types.dart': '_types',
    'accounts.dart': '_accounts',
    'instructions.dart': '_instructions',
    'resolution.dart': '_resolution',
    'events.dart': '_events',
    'errors.dart': '_errors',
    'client.dart': '_client',
  };
  final sources = <String>[];
  for (final entry in suffixes.entries) {
    final source = output.files[entry.key]!.replaceAll(
      '__PROGRAM_STEM__',
      'analyzer_matrix',
    );
    sources.add(source);
    await File(
      p.join(lib.path, 'analyzer_matrix_solana${entry.value}.dart'),
    ).writeAsString(source);
  }
  return sources;
}

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

const _runtimeProgram = r'''
import 'dart:typed_data';

import 'generated.dart';

final class TestRelationResolver implements AnalyzerMatrixRelationResolver {
  TestRelationResolver(this.relatedOne, this.relatedTwo);

  final AnalyzerMatrixAddress relatedOne;
  final AnalyzerMatrixAddress relatedTwo;
  var calls = 0;

  @override
  Future<AnalyzerMatrixAddress?> resolveRelation({
    required String accountPath,
    required String relationPath,
    required Map<String, AnalyzerMatrixAddress> resolvedAccounts,
  }) async {
    calls++;
    if (accountPath == 'related_one' &&
        resolvedAccounts.containsKey('data_derived') &&
        resolvedAccounts.containsKey('address_derived')) {
      return relatedOne;
    }
    if (accountPath == 'related_two' &&
        resolvedAccounts.containsKey('related_one')) {
      return relatedTwo;
    }
    return null;
  }
}

AnalyzerMatrixAddress address(int byte) =>
    AnalyzerMatrixAddress.fromBytes(List<int>.filled(32, byte));

AnalyzerMatrixAccountSnapshot snapshot(
  AnalyzerMatrixAddress source,
  AnalyzerMatrixAddress owner,
  List<int> data,
) => AnalyzerMatrixAccountSnapshot(
  address: source,
  owner: owner,
  data: data,
  lamports: BigInt.one,
  executable: false,
  rentEpoch: BigInt.zero,
  slot: BigInt.one,
);

Future<void> main() async {
  final mutableBytes = Uint8List.fromList([1, 2, 3]);
  final mutableItems = <int>[4, 5];
  final payload = AnalyzerMatrixNullablePayload(
    optionalBytes: mutableBytes,
    optionalItems: mutableItems,
    itemsWithOptions: const [null, 7],
    compactOptional: BigInt.from(8),
  );
  mutableBytes[0] = 99;
  mutableItems[0] = 99;
  final equalPayload = AnalyzerMatrixNullablePayload(
    optionalBytes: Uint8List.fromList([1, 2, 3]),
    optionalItems: const [4, 5],
    itemsWithOptions: const [null, 7],
    compactOptional: BigInt.from(8),
  );
  if (payload != equalPayload || payload.hashCode != equalPayload.hashCode) {
    throw StateError('Nullable structural semantics changed.');
  }
  final payloadWire = AnalyzerMatrixNullablePayload.codec.encode(payload);
  if (AnalyzerMatrixNullablePayload.codec.decodeExact(payloadWire) != payload) {
    throw StateError('Nullable codec round trip failed.');
  }
  final nullPayload = AnalyzerMatrixNullablePayload(
    optionalBytes: null,
    optionalItems: null,
    itemsWithOptions: const [null],
    compactOptional: null,
  );
  if (AnalyzerMatrixNullablePayload.codec.decodeExact(
        AnalyzerMatrixNullablePayload.codec.encode(nullPayload),
      ) !=
      nullPayload) {
    throw StateError('Null codec round trip failed.');
  }

  final authority = address(1);
  final seedState = address(2);
  final seedOwner = address(3);
  final dataDerived = address(4);
  final addressDerived = address(5);
  final relatedOne = address(6);
  final relatedTwo = address(7);
  final accountData = <int>[
    ...AnalyzerMatrixSeedStateAccount.discriminator,
    ...AnalyzerMatrixSeedState.codec.encode(
      AnalyzerMatrixSeedState(owner: seedOwner, counter: BigInt.two),
    ),
  ];
  var reads = 0;
  final reader = AnalyzerMatrixAccountReaderCallback(
    readOne: (requested, options) async {
      reads++;
      return snapshot(
        requested,
        AnalyzerMatrixProgram.programAddress,
        accountData,
      );
    },
    readMany: (requested, options) async =>
        List<AnalyzerMatrixAccountSnapshot?>.filled(requested.length, null),
  );
  final deriver = AnalyzerMatrixPdaDeriverCallback((program, seeds) async {
    final label = String.fromCharCodes(seeds.first);
    if (label == 'data') {
      if (seeds.length != 2 ||
          !seeds.last.asMap().entries.every(
            (entry) => entry.value == seedOwner.bytes[entry.key],
          )) {
        throw StateError('Account-data seed was decoded incorrectly.');
      }
      return AnalyzerMatrixPdaResult(address: dataDerived, bump: 255);
    }
    if (label == 'addr') {
      return AnalyzerMatrixPdaResult(address: addressDerived, bump: 254);
    }
    throw StateError('Unexpected PDA seed label.');
  });
  final relations = TestRelationResolver(relatedOne, relatedTwo);
  final resolver = AnalyzerMatrixResolveMatrixAccountResolver(
    AnalyzerMatrixResolutionContext(
      accountReader: reader,
      pdaDeriver: deriver,
      relationResolver: relations,
    ),
  );
  final args = AnalyzerMatrixResolveMatrixArgs(
    optionalOwner: null,
    optionalAmount: BigInt.from(9),
    optionalCount: null,
    payload: payload,
  );
  final overrides = AnalyzerMatrixResolveMatrixAccountOverrides(
    authority: AnalyzerMatrixAccountOverride.use(authority),
    seedState: AnalyzerMatrixAccountOverride.use(seedState),
  );
  final resolved = await resolver.resolve(args: args, overrides: overrides);
  if (resolved.dataDerived != dataDerived ||
      resolved.addressDerived != addressDerived ||
      resolved.relatedOne != relatedOne ||
      resolved.relatedTwo != relatedTwo ||
      reads != 1 ||
      relations.calls < 2) {
    throw StateError('Resolver semantics changed.');
  }

  Future<void> expectPdaFailure(
    AnalyzerMatrixAccountSnapshot? value,
    String code,
  ) async {
    final failingReader = AnalyzerMatrixAccountReaderCallback(
      readOne: (requested, options) async => value,
      readMany: (requested, options) async =>
          List<AnalyzerMatrixAccountSnapshot?>.filled(requested.length, null),
    );
    final failingResolver = AnalyzerMatrixResolveMatrixAccountResolver(
      AnalyzerMatrixResolutionContext(
        accountReader: failingReader,
        pdaDeriver: deriver,
      ),
    );
    try {
      await failingResolver.resolve(args: args, overrides: overrides);
      throw StateError('Expected $code.');
    } on AnalyzerMatrixPdaException catch (error) {
      if (error.code != code) rethrow;
    }
  }

  await expectPdaFailure(null, 'PDA_SOURCE_MISSING');
  await expectPdaFailure(
    snapshot(seedState, address(8), accountData),
    'PDA_SOURCE_OWNER',
  );
  try {
    await expectPdaFailure(
      snapshot(
        seedState,
        AnalyzerMatrixProgram.programAddress,
        AnalyzerMatrixSeedStateAccount.discriminator,
      ),
      'unused',
    );
    throw StateError('Expected malformed account data to fail decoding.');
  } on AnalyzerMatrixBorshException {
    // Expected decode failure remains typed.
  }
}
''';
