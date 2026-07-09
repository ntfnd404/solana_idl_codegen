import 'dart:io';

import 'package:path/path.dart' as path;

import 'output_recovery_exception.dart';

/// Resolves canonical output roots and enforces their path boundary.
final class CanonicalPathResolver {
  /// Creates a canonical path resolver.
  const CanonicalPathResolver();

  /// Resolves [directory], including a suffix which does not exist yet.
  Future<String> resolveDirectory(Directory directory) async {
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

  /// Returns canonical [candidate] or throws when it escapes [root].
  String requireInside(String root, String candidate) {
    final normalized = path.normalize(path.absolute(candidate));
    if (!path.isWithin(root, normalized)) {
      throw const OutputRecoveryException(
        'Transaction path escapes output root.',
      );
    }
    return normalized;
  }
}
