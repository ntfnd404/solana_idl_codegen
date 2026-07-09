import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'output_recovery_exception.dart';

/// Serializes output operations by canonical output-root identity.
final class OutputLock {
  /// Creates an output lock service.
  const OutputLock();

  /// Runs [operation] while holding the canonical root lock.
  Future<void> synchronized(
    String canonicalRoot,
    Future<void> Function() operation,
  ) async {
    final lockDirectory = Directory(
      path.join(Directory.systemTemp.path, 'solana_idl_codegen_locks'),
    );
    RandomAccessFile handle;
    try {
      await lockDirectory.create(recursive: true);
      final name = sha256.convert(utf8.encode(canonicalRoot)).toString();
      handle = await File(
        path.join(lockDirectory.path, '$name.lock'),
      ).open(mode: FileMode.write);
      await handle.lock(FileLock.exclusive);
    } on FileSystemException catch (error) {
      throw OutputRecoveryException('Could not lock the output tree.', error);
    }
    try {
      await operation();
    } finally {
      try {
        await handle.unlock();
        await handle.close();
      } on FileSystemException catch (error) {
        throw OutputRecoveryException(
          'Could not release the output lock.',
          error,
        );
      }
    }
  }
}
