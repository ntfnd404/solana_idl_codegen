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
      return {'$base.solana.dart': generated.files['program.dart']!};
    }
    const suffixes = {
      'program.dart': '.solana.dart',
      'support.dart': '.solana.support.dart',
      'types.dart': '.solana.types.dart',
      'accounts.dart': '.solana.accounts.dart',
      'instructions.dart': '.solana.instructions.dart',
      'resolution.dart': '.solana.resolution.dart',
      'events.dart': '.solana.events.dart',
      'errors.dart': '.solana.errors.dart',
      'client.dart': '.solana.client.dart',
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
