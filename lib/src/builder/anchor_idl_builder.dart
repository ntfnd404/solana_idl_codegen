import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import '../generation.dart';
import '../solana_idl_generator.dart';
import 'builder_options.dart';

/// Creates the default single-file Anchor IDL builder.
Builder solanaIdlBundledBuilder(BuilderOptions options) => AnchorIdlBuilder(
  layout: OutputLayout.bundled,
  options: SolanaIdlBuilderOptions.fromBuilderOptions(options),
);

/// Creates the multi-library Anchor IDL builder.
Builder solanaIdlModularBuilder(BuilderOptions options) => AnchorIdlBuilder(
  layout: OutputLayout.modular,
  options: SolanaIdlBuilderOptions.fromBuilderOptions(options),
);

/// A `build_runner` adapter for one statically declared output layout.
final class AnchorIdlBuilder implements Builder {
  /// Creates a builder for [layout] and validated naming [options].
  const AnchorIdlBuilder({
    required this.layout,
    this.options = const SolanaIdlBuilderOptions(),
  });

  static const _inputPattern = r'lib/idl/{{}}.json';
  static const _bundledOutputs = <String>[r'lib/generated/{{}}.solana.dart'];
  static const _modularOutputs = <String>[
    r'lib/generated/{{}}.solana.dart',
    r'lib/generated/{{}}.solana.support.dart',
    r'lib/generated/{{}}.solana.types.dart',
    r'lib/generated/{{}}.solana.accounts.dart',
    r'lib/generated/{{}}.solana.instructions.dart',
    r'lib/generated/{{}}.solana.resolution.dart',
    r'lib/generated/{{}}.solana.events.dart',
    r'lib/generated/{{}}.solana.errors.dart',
    r'lib/generated/{{}}.solana.client.dart',
  ];

  /// Physical layout declared by this builder key.
  final OutputLayout layout;

  /// Naming configuration supplied through `build.yaml`.
  final SolanaIdlBuilderOptions options;

  @override
  Map<String, List<String>> get buildExtensions =>
      layout == OutputLayout.bundled
      ? const {_inputPattern: _bundledOutputs}
      : const {_inputPattern: _modularOutputs};

  @override
  Future<void> build(BuildStep buildStep) async {
    final output = const SolanaIdlGenerator().generateString(
      await buildStep.readAsString(buildStep.inputId),
      sourceName: buildStep.inputId.path,
      options: GenerationOptions(
        layout: layout,
        typePrefix: options.typePrefix,
        typeSuffix: options.typeSuffix,
      ),
    );
    final relative = path.relative(buildStep.inputId.path, from: 'lib/idl');
    final outputStem = path.withoutExtension(relative);
    final sourceStem = path.basename(outputStem);
    final mapping = layout == OutputLayout.bundled
        ? const {'.solana.dart': 'program.dart'}
        : const {
            '.solana.dart': 'program.dart',
            '.solana.support.dart': 'support.dart',
            '.solana.types.dart': 'types.dart',
            '.solana.accounts.dart': 'accounts.dart',
            '.solana.instructions.dart': 'instructions.dart',
            '.solana.resolution.dart': 'resolution.dart',
            '.solana.events.dart': 'events.dart',
            '.solana.errors.dart': 'errors.dart',
            '.solana.client.dart': 'client.dart',
          };
    for (final entry in mapping.entries) {
      final content = output.files[entry.value];
      if (content == null) {
        throw StateError('Generator omitted logical output ${entry.value}.');
      }
      await buildStep.writeAsString(
        AssetId(
          buildStep.inputId.package,
          'lib/generated/$outputStem${entry.key}',
        ),
        content.replaceAll('__PROGRAM_STEM__', sourceStem),
      );
    }
  }
}
