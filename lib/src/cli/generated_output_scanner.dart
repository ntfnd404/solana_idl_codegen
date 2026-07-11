import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Stable marker embedded in every file owned by this generator.
const generatedFileMarker = '// tool: solana_idl_codegen';

const _knownSuffixes = <String>[
  '_solana.dart',
  '_solana_support.dart',
  '_solana_types.dart',
  '_solana_accounts.dart',
  '_solana_instructions.dart',
  '_solana_resolution.dart',
  '_solana_events.dart',
  '_solana_errors.dart',
  '_solana_client.dart',
  // Legacy dotted names remain recognized so regeneration removes them.
  '.solana.dart',
  '.solana.support.dart',
  '.solana.types.dart',
  '.solana.accounts.dart',
  '.solana.instructions.dart',
  '.solana.resolution.dart',
  '.solana.events.dart',
  '.solana.errors.dart',
  '.solana.client.dart',
];

/// Finds generated files without treating unrelated SDKs as stale.
final class GeneratedOutputScanner {
  /// Creates an ownership scanner.
  const GeneratedOutputScanner();

  /// Returns tool-owned outputs for [stems] which are not in [expected].
  Future<List<File>> staleForStems(
    Iterable<String> stems,
    Set<String> expected,
  ) async {
    final normalizedExpected = expected.map(_absolute).toSet();
    final result = <File>[];
    for (final stem in stems.map(_absolute).toSet()) {
      for (final suffix in _knownSuffixes) {
        final file = File('$stem$suffix');
        if (normalizedExpected.contains(_absolute(file.path)) ||
            !await file.exists()) {
          continue;
        }
        if (await isOwned(file)) result.add(file);
      }
    }
    result.sort((left, right) => left.path.compareTo(right.path));
    return result;
  }

  /// Returns every tool-owned file below [root].
  Future<List<File>> allOwned(Directory root) async {
    if (!await root.exists()) return const [];
    final result = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && await isOwned(entity)) result.add(entity);
    }
    result.sort((left, right) => left.path.compareTo(right.path));
    return result;
  }

  /// Whether [file] starts with the stable generator marker.
  Future<bool> isOwned(File file) async {
    if (!await file.exists()) return false;
    try {
      final prefix = await file.openRead(0, 512).transform(utf8.decoder).join();
      return prefix.contains(generatedFileMarker);
    } on FileSystemException {
      rethrow;
    } on Object {
      return false;
    }
  }

  String _absolute(String value) => path.normalize(path.absolute(value));
}
