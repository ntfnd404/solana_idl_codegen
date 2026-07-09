import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:solana_idl_codegen/src/generator/generator_version.dart';
import 'package:test/test.dart';

void main() {
  const generator = SolanaIdlGenerator();

  group('public facade', () {
    test('detects duplicate keys with stable diagnostics and locations', () {
      final result = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "address": "11111111111111111111111111111111"
}
''', sourceName: 'duplicate.json');
      expect(result.isValid, isFalse);
      expect(result.diagnostics.single.code, 'IDL_JSON_DUPLICATE_KEY');
      expect(result.diagnostics.single.jsonPath, r'$.address');
      expect(result.diagnostics.single.location.line, 3);
      expect(result.diagnostics.single.related, hasLength(1));
    });

    test('rejects unknown fields and recognized unsupported serialization', () {
      final unknown = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "bad", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "unexpected": true
}
''');
      expect(unknown.isValid, isFalse);
      expect(unknown.diagnostics.single.jsonPath, r'$.unexpected');

      final bytemuck = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "bad", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "types": [{
    "name": "Raw",
    "serialization": "bytemuck",
    "type": {"kind": "struct", "fields": []}
  }]
}
''');
      expect(bytemuck.diagnostics.single.code, 'IDL_SERIALIZATION_UNSUPPORTED');
    });

    test('rejects unknown and incomplete modern dialects', () {
      final unknown = generator.validateString('{"instructions": []}');
      expect(unknown.diagnostics.single.code, 'IDL_DIALECT_UNKNOWN');

      final missingSpec = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "modern", "version": "1"},
  "instructions": []
}
''');
      expect(
        missingSpec.diagnostics.single.code,
        'IDL_DIALECT_MODERN_SPEC_MISSING',
      );
      expect(missingSpec.diagnostics.single.location.line, 3);
    });

    test('locates semantic failures and normalized member collisions', () {
      final invalidAddress = generator.validateString('''
{
  "address": "bad",
  "metadata": {"name": "program", "version": "1", "spec": "0.1.0"},
  "instructions": []
}
''');
      expect(invalidAddress.diagnostics.single.location.line, 2);

      final collision = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "program", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "types": [{
    "name": "Collision",
    "type": {"kind": "struct", "fields": [
      {"name": "foo_bar", "type": "u8"},
      {"name": "fooBar", "type": "u8"}
    ]}
  }]
}
''');
      expect(collision.diagnostics.single.code, 'IDL_DART_MEMBER_COLLISION');
    });

    test('rejects unsupported PDA seeds before emission', () {
      final result = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "program", "version": "1", "spec": "0.1.0"},
  "instructions": [{
    "name": "run",
    "discriminator": [1],
    "accounts": [{
      "name": "state",
      "pda": {"seeds": [{"kind": "const", "type": "bool", "value": true}]}
    }],
    "args": []
  }]
}
''');
      expect(result.isValid, isFalse);
      expect(
        result.diagnostics.any((item) => item.code == 'IDL_PDA_SEED_TYPE'),
        isTrue,
      );
    });

    test('rejects unverified COption payload types', () {
      final result = generator.validateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "bad_coption", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "types": [{
    "name": "Unsupported",
    "type": {
      "kind": "struct",
      "fields": [{"name": "value", "type": {"coption": "string"}}]
    }
  }]
}
''');
      expect(result.isValid, isFalse);
      expect(result.diagnostics.first.code, 'IDL_COPTION_TYPE_UNSUPPORTED');
    });

    test('normalizes legacy and generates without runtime package imports', () {
      final source = File('test/fixtures/legacy.json').readAsStringSync();
      final output = generator.generateString(
        source,
        options: const GenerationOptions(),
      );
      final dart = output.files['program.dart']!;
      expect(dart, contains('class LegacyCounterAddress'));
      expect(dart, contains('generator-version: $solanaIdlGeneratorVersion'));
      expect(dart, isNot(contains('package:solana')));
      expect(dart, isNot(contains('package:solana_idl_codegen')));
      expect(dart, isNot(contains(RegExp(r'\bdynamic\b'))));
    });

    test('bundled and modular generation is deterministic', () {
      final source = File('test/fixtures/full_types.json').readAsStringSync();
      final first = generator.generateString(
        source,
        options: const GenerationOptions(layout: OutputLayout.bundled),
      );
      final second = generator.generateString(
        source,
        options: const GenerationOptions(layout: OutputLayout.bundled),
      );
      expect(first.files, second.files);
      final modular = generator.generateString(
        source,
        options: const GenerationOptions(layout: OutputLayout.modular),
      );
      expect(
        modular.files.keys,
        containsAll(<String>[
          'program.dart',
          'support.dart',
          'types.dart',
          'accounts.dart',
          'instructions.dart',
          'resolution.dart',
          'events.dart',
          'errors.dart',
          'client.dart',
        ]),
      );
      expect(
        _publicDeclarationNames(first.files.values),
        _publicDeclarationNames(
          modular.files.entries
              .where((entry) => entry.key != 'program.dart')
              .map((entry) => entry.value),
        ),
      );
    });
  });

  test('generated bundled and modular SDKs pass dart analyze', () async {
    final source = File(
      'example/lib/idl/example_program.json',
    ).readAsStringSync();
    for (final layout in OutputLayout.values) {
      final directory = await Directory.systemTemp.createTemp(
        'solana_idl_consumer_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final output = generator.generateString(
        source,
        options: GenerationOptions(layout: layout),
      );
      if (layout == OutputLayout.bundled) {
        await File(
          '${directory.path}/example_program.solana.dart',
        ).writeAsString(output.files['program.dart']!);
      } else {
        const suffixes = {
          'program.dart': '',
          'support.dart': '.support',
          'types.dart': '.types',
          'accounts.dart': '.accounts',
          'instructions.dart': '.instructions',
          'resolution.dart': '.resolution',
          'events.dart': '.events',
          'errors.dart': '.errors',
          'client.dart': '.client',
        };
        for (final entry in suffixes.entries) {
          await File(
            '${directory.path}/example_program.solana${entry.value}.dart',
          ).writeAsString(
            output.files[entry.key]!.replaceAll(
              '__PROGRAM_STEM__',
              'example_program',
            ),
          );
        }
      }
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['analyze', directory.path],
        environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }
  });

  test('generated Borsh executes strict round trips', () async {
    final directory = await Directory.systemTemp.createTemp(
      'solana_idl_borsh_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = File('test/fixtures/full_types.json').readAsStringSync();
    final output = generator.generateString(
      source,
      options: const GenerationOptions(),
    );
    await File(
      '${directory.path}/generated.dart',
    ).writeAsString(output.files['program.dart']!);
    await File('${directory.path}/main.dart').writeAsString(r'''
import 'generated.dart';

void main() {
  final ownerBytes = List<int>.filled(32, 0);
  final owner = TypeMatrixAddress.fromBytes(ownerBytes);
  ownerBytes[0] = 99;
  if (owner.bytes[0] != 0) throw StateError('Address was not copied.');
  final nonZeroAddress = TypeMatrixAddress.fromBytes(
    List<int>.generate(32, (index) => index),
  );
  final addressRoundTrip = TypeMatrixAddress.fromBase58(
    nonZeroAddress.toBase58(),
  );
  if (addressRoundTrip != nonZeroAddress) {
    throw StateError('Base58 address round trip failed.');
  }
  try {
    TypeMatrixAddress.fromBase58('0');
    throw StateError('Invalid Base58 was accepted.');
  } on FormatException {
    // Expected.
  }

  final value = TypeMatrixEverything(
    flag: true,
    small: -42,
    large: (BigInt.one << 255) - BigInt.one,
    ratio: -0.0,
    name: 'matrix',
    data: [1, 2, 3],
    owner: owner,
    optional: BigInt.from(9),
    items: [1, 2],
    fixed: [3, 4, 5, 6],
    choice: const TypeMatrixChoiceEmpty(),
  );
  final encoded = TypeMatrixEverything.codec.encode(value);
  final decoded = TypeMatrixEverything.codec.decodeExact(encoded);
  if (decoded != value || decoded.hashCode != value.hashCode) {
    throw StateError('Borsh round trip or value equality failed.');
  }
  try {
    TypeMatrixEverything.codec.decodeExact([2]);
    throw StateError('Invalid bool tag was accepted.');
  } on TypeMatrixBorshException catch (error) {
    if (error.code != 'BORSH_INVALID_BOOL') rethrow;
  }
}

''');
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', '${directory.path}/main.dart'],
      workingDirectory: Directory.current.path,
      environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('const-generic array lengths compile at concrete use sites', () async {
    final output = generator.generateString('''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "generic_matrix", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "types": [
    {
      "name": "Sized",
      "generics": [{"kind": "const", "name": "N", "type": "usize"}],
      "type": {
        "kind": "struct",
        "fields": [{"name": "items", "type": {"array": ["u8", {"generic": "N"}]}}]
      }
    },
    {
      "name": "Holder",
      "type": {
        "kind": "struct",
        "fields": [{
          "name": "value",
          "type": {"defined": {"name": "Sized", "generics": [{"kind": "const", "value": 4}]}}
        }]
      }
    }
  ]
}
''', options: const GenerationOptions());
    expect(output.files['program.dart'], contains('codec(int n)'));
  });

  test(
    'generated resolver applies overrides, PDA, fixed, and absent order',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'solana_idl_resolution_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final output = generator.generateString(
        File('example/lib/idl/example_program.json').readAsStringSync(),
        options: const GenerationOptions(),
      );
      await File(
        '${directory.path}/generated.dart',
      ).writeAsString(output.files['program.dart']!);
      await File('${directory.path}/main.dart').writeAsString(r'''
import 'generated.dart';

Future<void> main() async {
  final explicit = ExampleProgramAddress.fromBytes(List<int>.filled(32, 3));
  final derived = ExampleProgramAddress.fromBytes(List<int>.filled(32, 7));
  final deriver = ExampleProgramPdaDeriverCallback((program, seeds) async {
    if (seeds.length != 2 ||
        String.fromCharCodes(seeds.first) != 'message' ||
        seeds.last.length != 8) {
      throw StateError('Typed PDA seeds were encoded incorrectly.');
    }
    return ExampleProgramPdaResult(address: derived, bump: 255);
  });
  final resolver = ExampleProgramCreateMessageAccountResolver(
    ExampleProgramResolutionContext(pdaDeriver: deriver),
  );
  final request = await resolver.prepare(
    args: ExampleProgramCreateMessageArgs(
      id: BigInt.from(9),
      text: 'test',
    ),
    overrides: ExampleProgramCreateMessageAccountOverrides(
      authority: ExampleProgramAccountOverride.use(explicit),
      optionalReferrer: const ExampleProgramAccountOverride.absent(),
    ),
  );
  final instruction = request.instruction();
  if (instruction.accounts[0].address != explicit ||
      instruction.accounts[1].address != derived ||
      instruction.accounts[2].address !=
          ExampleProgramProgram.programAddress ||
      instruction.accounts[2].isSigner ||
      instruction.accounts[2].isWritable) {
    throw StateError('Resolution precedence or sentinel semantics failed.');
  }
}
''');
      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', '${directory.path}/main.dart'],
        workingDirectory: Directory.current.path,
        environment: {'HOME': directory.path, 'DART_DISABLE_ANALYTICS': '1'},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test('custom errors may contain an empty Anchor msg', () {
    final result = generator.validateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "empty_error_msg", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "accounts": [],
  "types": [],
  "events": [],
  "errors": [
    {"code": 6000, "name": "NoMessage", "msg": ""}
  ]
}
''');
    expect(result.isValid, isTrue, reason: result.diagnostics.join('\n'));
  });

  test('tuple enum variants accept object type expressions', () {
    final output = generator.generateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "tuple_object_payload", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "accounts": [],
  "types": [
    {
      "name": "Payload",
      "type": {
        "kind": "enum",
        "variants": [
          {"name": "Maybe", "fields": [{"option": "u64"}]}
        ]
      }
    }
  ],
  "events": [],
  "errors": []
}
''', options: const GenerationOptions());
    expect(output.files['program.dart'], contains('PayloadMaybe'));
  });

  test('duplicate field wire names get deterministic Dart names', () {
    final output = generator.generateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "duplicate_fields", "version": "1", "spec": "0.1.0"},
  "instructions": [],
  "accounts": [],
  "types": [
    {
      "name": "Padded",
      "type": {
        "kind": "struct",
        "fields": [
          {"name": "padding", "type": {"array": ["u8", 1]}},
          {"name": "padding", "type": {"array": ["u8", 2]}}
        ]
      }
    }
  ],
  "events": [],
  "errors": []
}
''', options: const GenerationOptions());
    final dart = output.files['program.dart']!;
    expect(dart, contains('final List<int> padding;'));
    expect(dart, contains('final List<int> padding2;'));
    expect(dart, contains(r'Generated Dart name `padding2`'));
    expect(dart, contains('value.padding'));
    expect(dart, contains('value.padding2'));
  });

  test('instruction helper type collision uses role-expanded fallback', () {
    final output = generator.generateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "helper_collision", "version": "1", "spec": "0.1.0"},
  "instructions": [
    {
      "name": "placeOrder",
      "discriminator": [1],
      "accounts": [],
      "args": [{"name": "price", "type": "u64"}]
    }
  ],
  "accounts": [],
  "types": [
    {
      "name": "PlaceOrderArgs",
      "type": {"kind": "struct", "fields": []}
    }
  ],
  "events": [],
  "errors": []
}
''', options: const GenerationOptions());
    final dart = output.files['program.dart']!;
    expect(dart, contains('final class HelperCollisionPlaceOrderArgs'));
    expect(
      dart,
      contains('final class HelperCollisionPlaceOrderInstructionArgs'),
    );
    expect(
      dart,
      contains(
        'HelperCollisionPlaceOrderInstructionArgs.codec.write(writer, args);',
      ),
    );
  });

  test('PDA argument paths resolve by wire-normalized names', () {
    final result = generator.validateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "legacy_path", "version": "1", "spec": "0.1.0"},
  "instructions": [
    {
      "name": "groupCreate",
      "discriminator": [1],
      "accounts": [
        {
          "name": "group",
          "writable": true,
          "signer": false,
          "pda": {
            "seeds": [
              {"kind": "arg", "type": "u32", "path": "group_num"}
            ]
          }
        }
      ],
      "args": [{"name": "groupNum", "type": "u32"}]
    }
  ],
  "accounts": [],
  "types": [],
  "events": [],
  "errors": []
}
''');
    expect(result.isValid, isTrue, reason: result.diagnostics.join('\n'));
    final output = generator.generateString(r'''
{
  "address": "11111111111111111111111111111111",
  "metadata": {"name": "legacy_path", "version": "1", "spec": "0.1.0"},
  "instructions": [
    {
      "name": "groupCreate",
      "discriminator": [1],
      "accounts": [
        {
          "name": "group",
          "writable": true,
          "signer": false,
          "pda": {
            "seeds": [
              {"kind": "arg", "type": "u32", "path": "group_num"}
            ]
          }
        }
      ],
      "args": [{"name": "groupNum", "type": "u32"}]
    }
  ],
  "accounts": [],
  "types": [],
  "events": [],
  "errors": []
}
''', options: const GenerationOptions());
    expect(output.files['program.dart'], contains('args.groupNum'));
  });
}

Set<String> _publicDeclarationNames(Iterable<String> sources) {
  final result = <String>{};
  final declarationPattern = RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed) )*'
    r'(?:class|enum|mixin|extension type|typedef) ([A-Za-z_][A-Za-z0-9_]*)',
  );
  for (final source in sources) {
    final unit = parseString(content: source, throwIfDiagnostics: true).unit;
    for (final declaration in unit.declarations) {
      final match = declarationPattern.firstMatch(declaration.toSource());
      final name = match?.group(1);
      if (name != null && !name.startsWith('_')) result.add(name);
    }
  }
  return result;
}
