import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:solana_idl_codegen/solana_idl_codegen.dart';
import 'package:test/test.dart';

void main() {
  const generator = SolanaIdlGenerator();

  group('generated SDK consumer package', () {
    for (final layout in OutputLayout.values) {
      test(
        '$layout compiles without a generator dependency',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'solana_idl_external_consumer_',
          );
          addTearDown(() => root.delete(recursive: true));

          await _writeConsumerPackage(root, layout, generator);
          await _runDart(root, ['pub', 'get']);
          await _runDart(root, ['analyze', '.']);
          await _runDart(root, ['run', 'bin/main.dart']);
          await _runDart(root, [
            'compile',
            'js',
            'bin/main.dart',
            '-o',
            p.join('build', 'main.js'),
          ]);

          final pubspec = await File(
            p.join(root.path, 'pubspec.yaml'),
          ).readAsString();
          expect(pubspec, isNot(contains('solana_idl_codegen')));
          expect(pubspec, isNot(contains('solana')));
          _expectGeneratedSdkHasNoForbiddenImports(root);
          _expectPublicApiHasNoDynamicOrObjectQuestion(root);
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }

    test(
      'two generated SDKs compile in one consumer package',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'solana_idl_two_sdk_consumer_',
        );
        addTearDown(() => root.delete(recursive: true));

        await _writeConsumerPackage(
          root,
          OutputLayout.modular,
          generator,
          includeSecondary: true,
        );
        await _runDart(root, ['pub', 'get']);
        await _runDart(root, ['analyze', '.']);
        await _runDart(root, ['run', 'bin/main.dart']);
        await _runDart(root, [
          'compile',
          'js',
          'bin/main.dart',
          '-o',
          p.join('build', 'main.js'),
        ]);

        _expectGeneratedSdkHasNoForbiddenImports(root);
        _expectPublicApiHasNoDynamicOrObjectQuestion(root);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

Future<void> _writeConsumerPackage(
  Directory root,
  OutputLayout layout,
  SolanaIdlGenerator generator, {
  bool includeSecondary = false,
}) async {
  final lib = Directory(p.join(root.path, 'lib', 'generated'));
  final bin = Directory(p.join(root.path, 'bin'));
  final build = Directory(p.join(root.path, 'build'));
  await lib.create(recursive: true);
  await bin.create(recursive: true);
  await build.create(recursive: true);
  await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: generated_sdk_consumer_${layout.name}
publish_to: none

environment:
  sdk: ^3.12.2
''');

  await _writeGeneratedSdk(
    lib,
    generator,
    layout,
    sourcePath: 'example/lib/idl/example_program.json',
    stem: 'example_program',
  );
  if (includeSecondary) {
    await _writeGeneratedSdk(
      lib,
      generator,
      layout,
      sourcePath: 'example/lib/idl/secondary_program.json',
      stem: 'secondary_program',
    );
  }
  await File(
    p.join(bin.path, 'main.dart'),
  ).writeAsString(_consumerMain(layout, includeSecondary: includeSecondary));
}

Future<void> _writeGeneratedSdk(
  Directory lib,
  SolanaIdlGenerator generator,
  OutputLayout layout, {
  required String sourcePath,
  required String stem,
}) async {
  final source = await File(sourcePath).readAsString();
  final output = generator.generateString(
    source,
    options: GenerationOptions(layout: layout),
  );
  await _writeGeneratedFiles(lib, output, layout, stem);
}

Future<void> _writeGeneratedFiles(
  Directory lib,
  GenerationOutput output,
  OutputLayout layout,
  String stem,
) async {
  if (layout == OutputLayout.bundled) {
    await File(
      p.join(lib.path, '$stem.solana.dart'),
    ).writeAsString(output.files['program.dart']!);
    return;
  }

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
      p.join(lib.path, '$stem.solana${entry.value}.dart'),
    ).writeAsString(
      output.files[entry.key]!.replaceAll('__PROGRAM_STEM__', stem),
    );
  }
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

void _expectGeneratedSdkHasNoForbiddenImports(Directory root) {
  for (final file in _generatedFiles(root)) {
    final source = file.readAsStringSync();
    expect(source, isNot(contains(RegExp(r"import 'package:"))));
    expect(source, isNot(contains(RegExp(r"import 'dart:io'"))));
    expect(source, isNot(contains(RegExp(r"import '.*(anchor|node|rpc).*'"))));
    expect(source, contains('// tool: solana_idl_codegen'));
  }
}

void _expectPublicApiHasNoDynamicOrObjectQuestion(Directory root) {
  for (final file in _generatedFiles(root)) {
    final source = file.readAsStringSync();
    expect(source, isNot(contains(RegExp(r'\bdynamic\b'))));
    final unit = parseString(
      content: source,
      throwIfDiagnostics: true,
      path: file.path,
    ).unit;
    final violations = <String>[];
    for (final declaration in unit.declarations) {
      _collectPublicSignatureViolations(declaration, violations);
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  }
}

void _collectPublicSignatureViolations(
  CompilationUnitMember declaration,
  List<String> violations,
) {
  switch (declaration) {
    case ClassDeclaration():
      if (_isPrivate(declaration.namePart.toSource().split('<').first)) return;
      for (final member in declaration.body.members) {
        switch (member) {
          case FieldDeclaration():
            if (_isPrivate(member.fields.variables.first.name.lexeme)) {
              continue;
            }
            _checkType(member.fields.type, violations);
          case MethodDeclaration():
            if (_isPrivate(member.name.lexeme)) continue;
            _checkType(member.returnType, violations);
            _checkParameters(member.parameters, violations);
          case ConstructorDeclaration():
            if (member.name != null && _isPrivate(member.name!.lexeme)) {
              continue;
            }
            _checkParameters(member.parameters, violations);
          default:
            break;
        }
      }
    case FunctionDeclaration():
      if (_isPrivate(declaration.name.lexeme)) return;
      _checkType(declaration.returnType, violations);
      _checkParameters(declaration.functionExpression.parameters, violations);
    case TopLevelVariableDeclaration():
      if (_isPrivate(declaration.variables.variables.first.name.lexeme)) {
        return;
      }
      _checkType(declaration.variables.type, violations);
  }
}

void _checkParameters(
  FormalParameterList? parameters,
  List<String> violations,
) {
  if (parameters == null) return;
  for (final parameter in parameters.parameters) {
    _checkType(parameter.toSource(), violations);
  }
}

void _checkType(Object? type, List<String> violations) {
  final source = switch (type) {
    TypeAnnotation() => type.toSource(),
    String() => type,
    _ => null,
  };
  if (source == null) return;
  if (RegExp(r'\bObject\?').hasMatch(source)) {
    violations.add('Unjustified Object? in public signature: $source');
  }
  if (RegExp(r'\bdynamic\b').hasMatch(source)) {
    violations.add('dynamic in public signature: $source');
  }
}

Iterable<File> _generatedFiles(Directory root) => Directory(
  p.join(root.path, 'lib', 'generated'),
).listSync().whereType<File>().where((file) => file.path.endsWith('.dart'));

bool _isPrivate(String name) => name.startsWith('_');

String _consumerMain(OutputLayout layout, {required bool includeSecondary}) =>
    '''
import 'package:generated_sdk_consumer_${layout.name}/generated/example_program.solana.dart';
${includeSecondary ? "import 'package:generated_sdk_consumer_${layout.name}/generated/secondary_program.solana.dart';" : ''}

void main() {
  final zero = ExampleProgramAddress.fromBytes(List<int>.filled(32, 0));
  ${includeSecondary ? "final secondaryZero = SecondaryProgramAddress.fromBytes(List<int>.filled(32, 0));" : ''}
  final message = ExampleProgramMessage(
    authority: zero,
    id: BigInt.one,
    text: 'hello',
  );
  final encoded = ExampleProgramMessage.codec.encode(message);
  final decoded = ExampleProgramMessage.codec.decodeExact(encoded);
  if (decoded != message) {
    throw StateError('Generated model codec did not round trip.');
  }

  final request = ExampleProgramCreateMessageRequest(
    args: ExampleProgramCreateMessageArgs(id: BigInt.two, text: 'created'),
    accounts: ExampleProgramCreateMessageAccounts(
      authority: zero,
      stateMessage: zero,
      optionalReferrer: null,
      systemProgram: zero,
    ),
  );
  final instruction = request.instruction();
  final wire = instruction.toWire();
  if (wire.programAddress.length != 32 ||
      wire.accounts.length != 4 ||
      wire.data.isEmpty) {
    throw StateError('Generated instruction wire shape is invalid.');
  }
  ${includeSecondary ? "if (secondaryZero.bytes.length != 32) throw StateError('Secondary SDK did not compile.');" : ''}
}
''';
