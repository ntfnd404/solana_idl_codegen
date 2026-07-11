import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../generation.dart';

/// Resolves safe deterministic CLI destinations for generated artifacts.
final class CliOutputPlanner {
  /// Creates the stateless output planner.
  const CliOutputPlanner();

  /// Converts logical generator outputs to concrete destination paths.
  Map<String, String> resolveOutputs(
    GenerationOutput generated,
    String outputRoot,
    String relativeStem,
    String sourceStem,
    OutputLayout layout,
  ) {
    final base = path.join(outputRoot, relativeStem);
    if (layout == OutputLayout.bundled) {
      return {'${base}_solana.dart': generated.files['program.dart']!};
    }
    const suffixes = {
      'program.dart': '_solana.dart',
      'support.dart': '_solana_support.dart',
      'types.dart': '_solana_types.dart',
      'accounts.dart': '_solana_accounts.dart',
      'instructions.dart': '_solana_instructions.dart',
      'resolution.dart': '_solana_resolution.dart',
      'events.dart': '_solana_events.dart',
      'errors.dart': '_solana_errors.dart',
      'client.dart': '_solana_client.dart',
    };
    return {
      for (final entry in suffixes.entries)
        '$base${entry.value}': generated.files[entry.key]!.replaceAll(
          '__PROGRAM_STEM__',
          sourceStem,
        ),
    };
  }

  /// Rejects path traversal outside [parent].
  void requireInside(String child, String parent, String label) {
    final normalizedChild = path.normalize(path.absolute(child));
    final normalizedParent = path.normalize(path.absolute(parent));
    if (!path.isWithin(normalizedParent, normalizedChild)) {
      throw UsageException(
        '$label path escapes its configured root: $normalizedChild',
        '',
      );
    }
  }

  /// Resolves existing symlinks while preserving missing destination segments.
  Future<String> canonicalDestination(Directory directory) async {
    if (await directory.exists()) {
      return path.normalize(await directory.resolveSymbolicLinks());
    }
    final missingSegments = <String>[];
    var existing = directory;
    while (!await existing.exists()) {
      missingSegments.add(path.basename(existing.path));
      final parent = existing.parent;
      if (parent.path == existing.path) {
        throw FileSystemException(
          'No existing parent for output directory.',
          directory.path,
        );
      }
      existing = parent;
    }
    var result = await existing.resolveSymbolicLinks();
    for (final segment in missingSegments.reversed) {
      result = path.join(result, segment);
    }
    return path.normalize(result);
  }
}
